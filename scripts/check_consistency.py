#!/usr/bin/env python3
"""Analytic pooled/bin frame counts, independent of the Mata aggregation code."""
import json
from pathlib import Path
import re
import subprocess
import shutil
ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / 'build/consistency'
def load(name):
    html = (folder / (name+'.html')).read_text()
    assert not re.search(r'<script[^>]+src=|fetch\s*\(|XMLHttpRequest|https?://', html)
    return json.loads(re.search(r'id="fegraph-data">(.*?)</script>', html, re.S).group(1))
for view in ('firmgraph','ladder','heatmap'):
    d = load(view)
    assert [f['coverage'][0] for f in d['frames']] == [0,2,3,2,2]
    assert len(d['nodes']) == 2
b = load('bipartite')
assert len(b['nodes']) == 5 and len(b['edges']) == 6
assert len([n for n in b['nodes'] if n['v'][0]==1]) == 3
for f in b['frames']:
    assert f['coverage'][:2] == [3,3]
    assert all(v[0] in (0,1) for v in f['values'])
    assert sum(n for n,node in zip(f['sizes'],b['nodes']) if node['v'][0]==0)==3
for name in ('shared','shared-descending','shared-heatmap'):
    d = load(name)
    assert [f['coverage'][0] for f in d['frames']] == [0,2,5,7,7]
    cross = [i for i,e in enumerate(d['edges']) if e['from']!=e['to']]
    assert len(cross)==1
    assert [f['values'][cross[0]][0] for f in d['frames']] == [0,0,3,3,3]
    assert not d['directed']
e = load('eventstudy')
assert e['title']=='Mover outcome profiles' and e['N_events']==4
assert e['ytitle']=='Mean y'
# Exercise actual exported scripts in a DOM/Canvas mock (separate from browser QA).
# The network mock targets network controls; eventstudy has its own viewer checks.
network_dir = folder / 'network-unit'
network_dir.mkdir(exist_ok=True)
for source in folder.glob('*.html'):
    if source.stem!='eventstudy':
        (network_dir/source.name).write_bytes(source.read_bytes())
subprocess.run([shutil.which('node') or 'node',str(ROOT/'scripts/check_animation_viewer.js'),str(network_dir)],check=True)
print('FEGRAPH_CONSISTENCY_JSON_OK')
