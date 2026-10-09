# Validation and support

Version 0.1.0, checked 2026-10-09 on macOS with licensed Stata/MP 19.
Source targets Stata 16 syntax. No licensed Stata 16–18, Windows or Linux
qualification is claimed. The runtime uses only official Stata and Mata.

## Reproduce

```sh
STATA_BIN=/path/to/stata-mp python3 scripts/test.py
STATA_BIN=/path/to/stata-mp python3 scripts/test.py --fesim ../fesim --ferank ../ferank
```

The runner checks that all package entries exist and use the `fegraph` prefix,
runs suites in fresh Stata sessions, and checks explicit printed terminal
success markers. It records hashes for installed files, fixtures, test sources
and package manifests in ignored `build/test-runs/receipt.json`. Corresponding
raw logs are in that directory. No licensed logs, data or generated graphs are
tracked. A zero batch process exit code alone is insufficient.

## Checked behavior

| Suite | Evidence |
| --- | --- |
| `smoke.do` | All four graph types, known synthetic transition/match counts, explicit outside state, rank aggregation, graph/data exports |
| `contracts.do` | Fractional/duplicate flows, zero/self rows, balanced net pairs, exact string IDs, full denominators under filtering, ego boundary mass, gap/unknown/outside distinctions, sample adjacency, shared workers, ties, bin means, no-edge graphs, duplicate-key failures, worker/firm ID collisions, and independently selectable width/color statistics |
| `advanced.do` | More than 65,536 string workers, exact large numeric IDs, million-row aggregation, component-aware employment-weighted bins, external comparability groups, prepared exposures, paired net heatmap filtering, reproducible layouts, categorical colors, distinct-worker node sizes |
| `routing.do` | Above/below separation, shared-endpoint lanes, reciprocal arrows, input-order invariance, curved marker clearance, tied ranks, nonmonotone levels, unchanged node values/counts, and a gross-flow render |
| `package.do` | `net install` into an isolated local ado directory, fresh-process loading of installed ado/Mata/help, installed selftest, all four installed examples |
| `command_gallery.do` | Four figures written as PNG and PDF, with caller data restored; visual inspection of arrowheads, labels, legends and outside-state band |
| `integration.do` | Actual fesim AKM output, ferank Bradley–Terry percentiles/components, ranked ladder with externally supplied effects, heatmap, retained ferank estimation results and simulation RNG |

Tests verify data signatures and original row order, preserved estimation
coefficients and RNG state, both success and failure cases, and exact reuse of
exported coordinates. Graph geometry is deterministic for a given layout seed.
Numeric tolerances are used for floating-point wage changes and bin levels.

## Scale observation

The deterministic scale fixture contains 1,000,000 worker-period rows,
100,000 workers, 1,000 firms and 900,000 observed moves. It aggregates to ten
rank bins and preserves all 900,000 moves in its edge table. Local runs took
about 8–9 seconds for the command, including aggregation, graph construction
with `nodraw`, and edge export. This is one sparse synthetic fixture, not a
universal performance claim for arbitrary administrative datasets.

The large-ID fixture separately has 70,000 distinct string workers and exact
numeric firm IDs near the largest exactly represented integer range. It
checks that worker dictionaries do not depend on Stata's value-label ceiling.

## Interpretation and practical limits

- Snapshot moves are observed endpoint changes, not latent events or hazards.
  `maxgap()` and `sample()` explicitly control adjacency.
- Supplied effects/ranks are descriptive inputs; comparability across separately
  normalized estimation components is the user's substantive responsibility.
- Graph layouts are descriptive. Force repulsion is quadratic in displayed
  nodes. Readability guards require explicit aggregation or selection for large
  displayed graphs; there is no hidden sampling.
- Colors use seven classes; marker areas and line widths use four global
  classes. Legends/captions and help describe their scales. Geometry uses
  approximate screen-relative clipping; very crowded plots still benefit from
  fewer nodes, binning, supplied coordinates or customized graph options.
- Node IDs are exact string representations in exported tables. Long labels
  are shortened only in figures. Very long IDs use strL and may need adaptation
  before a native Stata merge.
- Categorical colors have at most seven explicit numeric codes; encoded labels
  are not automatically substituted in legends. Bins cannot average categories.
- Bin boundaries depend on the selected firm population and weights. Common
  samples/weights are needed for comparable automatic bins across figures.
- File exports are sequential. The original in-memory dataset is preserved if
  rendering or a later file write fails, but already-written outputs can remain.
- This version implements firm, bipartite, ladder and heatmap views. Mover event
  profiles, sorting maps and animated trajectories from the original ideas list
  are separate potential extensions.
