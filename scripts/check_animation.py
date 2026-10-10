#!/usr/bin/env python3
"""Independent checks of exported JSON against small, known histories."""
import json, math, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def load(name):
    s=(ROOT/'build/animation'/name).read_text()
    assert not re.search(r'<script[^>]+src=|<link[^>]+href=|fetch\s*\(|XMLHttpRequest|https?://',s)
    d=json.loads(re.search(r'<script type="application/json" id="fegraph-data">(.*?)</script>',s,re.S).group(1))
    for frame in d['frames']:
        assert len(frame['values'])==len(d['edges'])
        assert len(frame['sizes'])==len(d['nodes'])
    return d
for p in (ROOT/'build/animation').glob('*.html'): load(p.name)
d=load('ladder.html'); assert len(d['frames'])==3
assert [f['coverage'][0] for f in d['frames']]==[0,3,3]
ids=[n['id'] for n in d['nodes']]
assert [dict(zip(ids,f['sizes'])) for f in d['frames']]==[
    {'1':2,'2':1,'3':0,'[outside]':1},
    {'1':1,'2':2,'3':1,'[outside]':0},
    {'1':1,'2':1,'3':1,'[outside]':1}]
expected=[{}, {('1','2'):1,('2','3'):1,('[outside]','2'):1}, {('2','3'):1,('1','[outside]'):1,('3','1'):1}]
for f,want in zip(d['frames'],expected):
    got={(ids[e['from']],ids[e['to']]):v[0] for e,v in zip(d['edges'],f['values']) if v[0]}
    assert got==want,(got,want)
assert any('</script><script>bad()</script>' in n['label'] for n in d['nodes'])
assert '<script>bad()' not in (ROOT/'build/animation/ladder.html').read_text()
b=load('bipartite.html'); assert [f['coverage'][0] for f in b['frames']]==[3,4,3]
s=load('shared.html'); assert [f['coverage'][0] for f in s['frames']]==[0,2,6]
n=load('net-ladder.html'); assert [f['values'][0][3] for f in n['frames']]==[8,-4]
assert [f['coverage'][:2] for f in n['frames']]==[[12,12],[6,6]]
h=load('hidden.html'); assert math.isclose(h['frames'][1]['values'][0][3],1/3)
assert h['frames'][1]['coverage'][:2]==[2,1]
assert [f['coverage'][0] for f in load('sample-selected.html')['frames']]==[0,1,2]
assert [f['coverage'][0] for f in load('sample-original.html')['frames']]==[0,1,1]
e=load('empty.html'); assert e['nodes'][0]['id']=='900719925474099312345' and not e['edges']
p=load('path with space, comma.html'); assert not any(p[k] for k in ['title','subtitle','note','legend','command'])
assert p['palette'][0]=='26 71 111' and p['palette'][3]=='224 224 224'
u=load('unquoted.html'); assert u['title']=='Custom title' and u['note']=='Custom note'
print('FEGRAPH_ANIMATION_JSON_OK')
