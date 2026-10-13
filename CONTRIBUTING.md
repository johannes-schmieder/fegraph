# Developing fegraph

The authoritative installed files are in `stata/`, enumerated in `fegraph.pkg`.
All installed basenames start with `fegraph`. The viewer uses an uppercase `F`
manifest entry so `net install` includes its HTML resource automatically. Generation uses official Stata/Mata;
HTML playback uses ordinary browser JavaScript. Do not require an external compiler,
server or third-party graph package. Node.js is used only for viewer unit tests.

- `fegraph.ado`: syntax, private frame lifecycle, output and returned diagnostics.
- `fegraph.mata`: ID dictionaries, matches/transitions, attributes, aggregation,
  weak components, display selection, force layout, geometry and export tables.
- `fegraph__draw.ado`: bounded style layers and ordinary Stata `twoway` rendering.
- `fegraph__palette.ado`: named/custom seven-color palettes, validation and reversal.
- `fegraph__animation.ado` / `fegraph__rgb.ado`: nested HTML options and color resolution.
- `fegraph__html.mata`: frame calculations and safe standalone JSON/HTML serialization.
- `fegraph__viewer.html`: embedded Canvas renderer and accessible playback controls.
- `fegraph__eventstudy.ado`: balanced mover windows, grouping, event-weighted means,
  worker-cluster pointwise uncertainty and native panel/overlay graphs.
- `fegraph__eventhtml.mata` / `fegraph__eventviewer.html`: standalone mover-profile
  serialization, event-time highlighting and arrival-cohort playback.
- `fegraph__load.ado`: loads installed Mata source on demand.
- `fegraph_example.ado`: preserving examples and the installation selftest.
- `fegraph_run.ado`: extracts runnable blocks directly from the help.
- `fegraph_report.ado`: optional six-command simulation and PDF workflow.
- `fegraph.sthlp`: public interface and statistical definitions.

Read the help and validation note before changing behavior. Positional inputs are
firm scores; IDs belong in worker()/firm() or origin()/destination(). Quantile
contracts compare with official xtile on one observation per firm. Keep caller data,
estimates and RNG unchanged. Preserve gross flow counts and full denominators;
never silently alter the graph to make it look more convenient. New options
must have a statistical definition and relevant contract checks. Update help,
README and changelog when changing the interface. Keep data, generated graphs,
logs and machine configuration out of source control. The two synthetic PNGs
in `docs/images/` are deliberate documentation assets; their reproduction
scripts are listed in `examples/README.md`. Do not add self-hosted
runners or unlicensed Stata binaries to GitHub.

Run from the repository root:

```sh
STATA_BIN=/path/to/stata-mp python3 scripts/test.py
```

With optional sibling checkouts available:

```sh
STATA_BIN=/path/to/stata-mp python3 scripts/test.py \
    --fesim ../fesim --ferank ../ferank
```

The runner checks package files, runs each suite in a fresh licensed Stata
process, and requires an explicit success marker. An OS exit code alone is
insufficient because Stata batch failures can return zero. Logs and a source
hash receipt stay under ignored `build/test-runs/`. Integration companions must
be installed or supplied using the two path arguments. They are never package
dependencies. Test drivers assume the repository is the working directory.

Only claim compatibility for versions/platforms actually checked. No release
tag, public visibility change or SSC submission is part of ordinary development.

For the complete optional report checks, also supply `--fereg ../fereg` and
`--texpdf ../texpdf`, with latexlog installed. `--reports-only` runs only those
checks. The graph command itself must continue to work without these companions.

## Repository layout

- `README.md`: installation, quick start and examples for new users.
- `INSTALLATION.md`: upgrades, local installation and troubleshooting.
- `docs/usage.md`: graph semantics and longer recipes; installed help is authoritative.
- `docs/options.md`: cross-view option matrix and aggregation contracts.
- `examples/`: runnable galleries and their synthetic input fixtures.
- `tests/` and `scripts/`: licensed Stata contracts and independent export checks.
- `build/`: ignored generated results and verification evidence.

The original design sketch and rendering prototype remain available in Git
history; maintained examples call the current command.
