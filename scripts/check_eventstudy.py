#!/usr/bin/env python3
"""Independent means/cluster-variance and standalone serialization checks."""
from pathlib import Path
import csv
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/eventstudy'
def load(name):
    text = (OUT / (name + '.html')).read_text()
    assert not re.search(r'<(?:script|link)[^>]+(?:src|href)=', text, re.I)
    assert not re.search(r'\b(?:fetch|XMLHttpRequest|WebSocket)\s*\(', text)
    data = json.loads(re.search(r'<script type="application/json" id="fegraph-data">(.*?)</script>', text, re.S).group(1))
    assert data['type'] == 'eventstudy'
    assert not any(key in data for key in ('worker_id', 'events', 'worker_index'))
    assert '900719925474099312345' not in text
    return data
base = load('base')
assert base['N_events'] == 32 and len(base['rows']) == 64
for row in base['rows']:
    cohort, origin, dest, period, mean, se, low, high, n, workers, shown = row
    expected = 3 + (origin if period < 0 else dest)/5 + (8*(origin-1)+2*dest-.5)/100 + .01*(period+3)
    assert math.isclose(mean, expected, abs_tol=1e-12)
    assert math.isclose(se, .005, abs_tol=1e-12)
    critical = 1 / math.tan(math.pi*.025)  # Exact t(1) 97.5th percentile.
    assert math.isclose(low, mean-critical*se, abs_tol=1e-10)
    assert math.isclose(high, mean+critical*se, abs_tol=1e-10)
    assert (cohort, n, workers, shown) == (None, 2, 2, 1)
with (OUT/'base.csv').open() as f:
    rows = list(csv.DictReader(f))
for actual, saved in zip(base['rows'], rows):
    assert math.isclose(actual[4], float(saved['mean']), abs_tol=1e-7)
normalized = load('normalized')
assert normalized['title'] == 'Test </script> & title'
assert {r[1] for r in normalized['rows']} == {1,4}
assert all(abs(r[4]) < 1e-12 for r in normalized['rows'] if r[3] == -1)
assert normalized['normalize'] == '-1'
cohorts = load('cohorts')
assert cohorts['cohorts'] == [3,13]
for year, origins in ((3,{1,2}),(13,{3,4})):
    sample = [r for r in cohorts['rows'] if r[0] == year]
    assert {r[1] for r in sample} == origins
    assert sum(r[8] for r in sample if r[3] == 0) == 16
repeated = load('repeated')
row = next(r for r in repeated['rows'] if r[1] == 1 and r[3] == 0)
# Changes 1 and 2 belong to worker A, change 6 to worker B: mean 3,
# worker-centered sums -3,+3, G/(G-1) * 18 / N^2 = 4.
assert math.isclose(row[4],3,abs_tol=1e-12) and math.isclose(row[5],2,abs_tol=1e-12)
assert (row[8],row[9]) == (3,2)
assert all(r[5] is None for r in repeated['rows'] if r[1] == 2)
svg=(OUT/'annotations.svg').read_text()
for text in ('Mover wage profiles','Firm-score quantiles','balanced events shown'):
    assert text not in svg
print('FEGRAPH_EVENTSTUDY_JSON_OK')
