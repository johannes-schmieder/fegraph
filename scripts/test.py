#!/usr/bin/env python3
"""Run fresh licensed Stata sessions; retain exact-source hashes and logs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def stata_quote(value):
    text = str(value)
    if any(c in text for c in ('"', '\n', '\r', '`', '$')):
        raise ValueError('Unsupported character in a Stata test path')
    return '"' + text + '"'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fesim', type=Path)
    parser.add_argument('--ferank', type=Path)
    parser.add_argument('--fereg', type=Path)
    parser.add_argument('--texpdf', type=Path)
    parser.add_argument('--reports-only', action='store_true')
    args = parser.parse_args()
    if bool(args.fesim) != bool(args.ferank):
        parser.error('Supply both --fesim and --ferank for integration checks')
    if (args.fereg or args.texpdf or args.reports_only) and not all((args.fesim, args.ferank, args.fereg, args.texpdf)):
        parser.error('Reports require --fesim, --ferank, --fereg and --texpdf; latexlog must be installed')
    stata = os.environ.get('STATA_BIN') or shutil.which('stata-mp') or shutil.which('stata-se') or shutil.which('stata')
    if not stata:
        parser.error('Set STATA_BIN to your licensed Stata executable')
    manifest = []
    for line in (ROOT / 'fegraph.pkg').read_text().splitlines():
        if line.startswith('f '):
            path = ROOT / line[2:].strip()
            if not path.is_file() or not path.name.startswith('fegraph'):
                raise RuntimeError(f'Invalid package entry: {line}')
            manifest.append(path)
    if not manifest:
        raise RuntimeError('Empty package manifest')
    out = ROOT / 'build' / 'test-runs'
    out.mkdir(parents=True, exist_ok=True)
    sources = [*manifest, *sorted((ROOT / 'tests').glob('*.do')), ROOT / 'examples' / 'command_gallery.do', ROOT / 'examples' / 'synthetic_panel.do', ROOT / 'fegraph.pkg', ROOT / 'stata.toc']
    receipt = {'source_sha256': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}, 'suites': {}}
    suites = [('smoke','FEGRAPH_SMOKE_OK'), ('contracts','FEGRAPH_CONTRACTS_OK'), ('interface','FEGRAPH_INTERFACE_OK'), ('quantiles','FEGRAPH_QUANTILES_OK'), ('advanced','FEGRAPH_ADVANCED_OK'), ('routing','FEGRAPH_ROUTING_OK'), ('manybins','FEGRAPH_MANYBINS_OK'), ('help','FEGRAPH_HELP_OK'), ('package','FEGRAPH_PACKAGE_OK'), ('gallery','FEGRAPH_GALLERY_OK')]
    if args.fesim:
        suites.append(('integration', 'FEGRAPH_INTEGRATION_OK'))
    if args.fereg:
        suites.append(('reports', 'FEGRAPH_REPORTS_OK'))
    if args.reports_only:
        suites = [('reports', 'FEGRAPH_REPORTS_OK')]
    for suite, marker in suites:
        driver = out / f'fegraph_test_{suite}.do'
        source = 'examples/command_gallery.do' if suite == 'gallery' else f'tests/{suite}.do'
        command = 'do ' + stata_quote(ROOT / source)
        if suite in ('integration', 'reports'):
            command += ' ' + stata_quote(args.fesim.resolve()) + ' ' + stata_quote(args.ferank.resolve())
        if suite == 'reports':
            command += ' ' + stata_quote(args.fereg.resolve()) + ' ' + stata_quote(args.texpdf.resolve())
        driver.write_text('version 16.0\nset more off\ncd ' + stata_quote(ROOT) + '\n' + command + '\n')
        batch_log = ROOT / f'{driver.stem}.log'
        if batch_log.exists():
            batch_log.unlink()
        result = subprocess.run([stata, '-b', 'do', str(driver)], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        output = batch_log.read_text(errors='replace') if batch_log.exists() else ''
        # Only a standalone printed line counts; echoed do-file source does not.
        passed = result.returncode == 0 and marker in [line.strip() for line in output.splitlines()]
        destination = out / f'{suite}.log'
        destination.write_text(output + '\n' + result.stdout)
        receipt['suites'][suite] = {'passed': passed, 'log': str(destination.relative_to(ROOT))}
        (out / ('reports-receipt.json' if args.reports_only else 'receipt.json')).write_text(json.dumps(receipt, indent=2) + '\n')
        print(f'{suite}: {"PASS" if passed else "FAIL"}', flush=True)
        if not passed:
            print(output[-5000:] or result.stdout)
            return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
