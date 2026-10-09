# Developing fegraph

The authoritative installed files are in `stata/`, enumerated in `fegraph.pkg`.
All installed basenames start with `fegraph`. The runtime uses only official
Stata/Mata; do not require a compiler or a third-party graph package.

- `fegraph.ado`: syntax, private frame lifecycle, output and returned diagnostics.
- `fegraph.mata`: ID dictionaries, matches/transitions, attributes, aggregation,
  weak components, display selection, force layout, geometry and export tables.
- `fegraph__draw.ado`: bounded style layers and ordinary Stata `twoway` rendering.
- `fegraph__load.ado`: loads installed Mata source on demand.
- `fegraph_example.ado`: preserving examples and the installation selftest.
- `fegraph.sthlp`: public interface and statistical definitions.

Read the help and validation note before changing behavior. Positional inputs are
firm scores; IDs belong in worker()/firm() or origin()/destination(). Quantile
contracts compare with official xtile on one observation per firm. Keep caller data,
estimates and RNG unchanged. Preserve gross flow counts and full denominators;
never silently alter the graph to make it look more convenient. New options
must have a statistical definition and relevant contract checks. Update help,
README and changelog when changing the interface. Keep data, generated graphs,
logs and machine configuration out of source control. Do not add self-hosted
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
