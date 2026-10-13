#!/usr/bin/env python3
"""Check Stata-rendered help, including sections beyond the initial examples."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--render-dir', type=Path, default=ROOT / 'build/help-render')
    args = parser.parse_args()
    source = (ROOT / 'stata/fegraph.sthlp').read_text()
    titles = re.findall(r'^\{title:([^}]+)\}$', source, re.M)
    raw_directive = re.compile(r'\{(?:pstd|phang\d?|p_end|p\s|title:|marker\s)')
    for width in (79, 120):
        path = args.render_dir / f'help-{width}.txt'
        text = path.read_text()
        assert not raw_directive.search(text), f'Uninterpreted SMCL in {path}'
        lines = {line.strip() for line in text.splitlines()}
        assert all(title in lines for title in titles), f'Merged or missing headings in {path}'
        assert 'Installation and updates' not in text and 'net install' not in text
        joined = ' '.join(text.split())
        assert 'fegraph visualizes linked worker-firm data' in joined
        # Check distinct syntax and late-file paragraphs, not just absence of braces.
        for start in ('Worker-period panel;', 'Prepared moves or aggregated flows;',
                      'Scores are numeric firm attributes', 'N_firms counts known input firms',
                      'flow_total is gross transition/match mass'):
            assert any(line.startswith(start) for line in lines), (path, start)
    print('FEGRAPH_HELP_RENDER_OK')


if __name__ == '__main__':
    main()
