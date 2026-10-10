#!/usr/bin/env python3
"""Check palette colors in Stata exports, including their legend keys."""
from collections import Counter
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / 'build' / 'palettes'


def elements(name, tag):
    root = ET.parse(ROOT / f'{name}.svg').getroot()
    for element in root.iter():
        if element.tag.rsplit('}', 1)[-1] == tag:
            style = dict(item.split(':', 1) for item in element.get('style', '').split(';') if ':' in item)
            yield element, style


def fills(name, tag='circle'):
    return Counter(style['fill'] for _, style in elements(name, tag)
                   if style.get('fill') not in (None, 'none', '#FFFFFF'))


def markers(name):
    return {(e.get('cx'), e.get('cy')): s['fill'] for e, s in elements(name, 'circle')
            if s.get('fill') not in (None, 'none')}


def heads(name):
    # Stata exports each arrowhead as two round-ended line segments.
    return Counter(s['stroke'] for e, s in elements(name, 'line')
                   if e.get('stroke-linecap') == 'round')


def check():
    for name in ('viridis', 'blues', 'greens', 'grays', 'redblue', 'brownteal'):
        counts = fills(name)
        assert len(counts) == 7 and set(counts.values()) == {2}, (name, counts)
        # Each class has one real firm marker and one matching legend marker.
    blues = ['#EFF3FF', '#C6DBEF', '#9ECAE1', '#6BAED6', '#4292C6', '#2171B5', '#084594']
    assert fills('blues') == Counter({c: 2 for c in blues})
    original, reversed_colors = markers('blues'), markers('blues-reverse')
    assert original.keys() == reversed_colors.keys(), 'Reversal moved graph or legend markers'
    reverse = dict(zip(blues, reversed(blues)))
    assert all(reversed_colors[p] == reverse[c] for p, c in original.items())
    custom = ['#1A476F', '#0000FF', '#00FFFF', '#E0E0E0', '#FFFF00', '#FF7F00', '#BE1E2D']
    assert fills('custom') == Counter({c: 2 for c in custom}), 'Custom names/RGB or legend mismatch'
    assert fills('categorical') == fills('greens'), 'Categorical palette differs from requested colors'
    counts = fills('bipartite')
    assert len(counts) == 7 and set(counts.values()) == {4}, counts
    assert all(c[1:3] == c[3:5] == c[5:7] for c in counts), 'Worker/node grays are not gray'
    for name in ('edges-effect', 'edges-wage'):
        assert heads(name) == Counter({'#B2182B': 2, '#92C5DE': 12}), (name, heads(name))
        strokes = {s['stroke'] for _, s in elements(name, 'path') if 'stroke' in s}
        assert {'#B2182B', '#92C5DE'} <= strokes, (name, strokes)
    assert heads('edges-reverse') == Counter({'#2166AC': 2, '#F4A582': 12})
    # s2color's ordinary rbar fill intensity is 80%; all cell and legend fills
    # are correspondingly blended with white. Zero/hidden cells stay neutral;
    # the plot background contributes one light-blue rectangle.
    assert fills('heatmap', 'rect') == Counter({'#EAF2F3': 1, '#F7F7F7': 43, '#337B5B': 8})
    assert fills('heatmap-net', 'rect') == Counter({'#EAF2F3': 1, '#F7F7F7': 36, '#4D85BD': 8, '#C14655': 8})
    print('FEGRAPH_PALETTE_SVG_OK')


if __name__ == '__main__':
    check()
