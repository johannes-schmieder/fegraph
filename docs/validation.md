# Validation and support

Version 0.6.1, checked 2026-10-10 on macOS with licensed Stata/MP 19.
Source targets Stata 16 syntax. No licensed Stata 16–18, Windows or Linux
qualification is claimed. Generation uses official Stata/Mata; HTML playback uses browser JavaScript.

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
| `interface.do` | Optional scores, explicit panel/endpoint IDs, attribute defaults/overrides, legacy-call rejection, qualifiers, outside-score missingness and state preservation |
| `quantiles.do` | Native `xtile` reference comparisons with ties/skew/weights/descending scores, `collapse` bin means, worker-record multiplicity invariance, outside exclusion and move conservation |
| `routing.do` | Above/below separation, shared-endpoint lanes, reciprocal arrows, input-order invariance, curved marker clearance, tied ranks, nonmonotone levels, unchanged node values/counts, and a gross-flow render |
| `manybins.do` | 50/100/200-bin dense prepared-flow fixtures; conserved mass, node-scaling invariance, default/alias names and scale guards |
| `help.do` | Eight native help blocks run through the installed-style parser, preserving data and estimates; missing-block failure |
| `reports.do` | All five optional help blocks: three individual DGP PDFs, combined PDF, compact pipeline; real fesim/fereg/ferank/latexlog/texpdf, paths with spaces, state restoration and overwrite guard |
| `classic.do` | Counts/node/edge/coordinate invariance across styles, input-order invariance, label quotas and ties, outside labels, empty graphs, option guards, directed arrows and two network renders |
| `palettes.do` | Named/custom palettes and reversal, all four views, worker/categorical colors, invalid-input guards, unchanged exported graphs and caller state; SVG checks verify marker, legend, arrow and heatmap colors |
| `animation.do` | All four views, aggregate/time frames, bins/outside/shared histories, rates/exposures, reversed net pairs, wage statistics, zero edges, nested paths/replacement, hostile labels, exact IDs and caller-state preservation; independent JSON and DOM/Canvas mock checks |
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
  are separate potential extensions; HTML aggregate/time playback is implemented in 0.6.

## Optional reports

With companions and native plugins available, and latexlog on the Stata adopath:

```sh
STATA_BIN=/path/to/stata-mp python3 scripts/test.py \
  --fesim ../fesim --ferank ../ferank --fereg ../fereg --texpdf ../texpdf
```

`--reports-only` runs the report suite alone and writes a separate hash receipt.
The suite executes the exact five optional blocks embedded in the help file.
Outputs remain under ignored `build/report examples/fegraph_examples/` (the space
in the path deliberately tests working-directory handling). Individual reports
contain seven pages; the combined report contains nineteen, including eighteen
figures. The report requires Stata 19, while the graph runtime still targets 16.

The 200-firm dense flow-table fixture has 39,800 directed pairs. With 60 displayed
net arrows, 50/100/200 nonempty ladder bins completed in approximately 0.6–0.9
seconds each on this machine. This establishes functionality, not legibility of
all possible arrows. The DGP report uses 30 net arrows for fifty-bin ladders.
The report's firm networks use circle layouts to keep nodes visible when edge
filtering would leave disconnected clusters and isolates in a force layout.

## Classic networks (0.4)

The classic gallery uses a constructed panel with 72 firms, 80 linked firm
pairs, and 289 distinct shared-worker connections. Both monochrome and supplied
firm-effect colors retain every connection. Tests compare complete exported
node and edge tables across styles, check input-order invariance, and verify
that the label quota leaves exported labels intact. An actual fesim AKM block
mobility example supplies an additional 60-firm network preview with relatively
balanced firm sizes (firm_size_sd .3), strong community preference
(block_log_bonus 4), the largest 140 links and nodescale(.15). Edge selection
can leave isolates; centering does not guarantee readable dense clusters.

Force-layout coordinates change in 0.4: disk initialization and mild centering
replace the initial circular perturbation and unbounded isolate drift. Circle,
ladder, bipartite and reused-coordinate layouts keep their definitions. Label
placement uses approximate screen-relative boxes and eight clock positions;
it reduces overlap but cannot guarantee collision-free text in arbitrary dense
graphs. Classic defaults to smaller markers; use common explicit nodescale()
values when comparing styles or panels.

The five optional report blocks were qualified in 0.3; this change does not add
or change report figures. Versions 0.4 and 0.5 check the graph suites and integration;
the earlier delivered PDF remains the version-0.3 report.

## User palettes (0.5)

The renderer accepts six named seven-color sequences and exactly seven plain
Stata names or RGB triplets. Both options can reverse the sequence. palette()
controls nodes, worker colors and heatmaps, including net heatmaps;
edgepalette() controls effect/wage-colored links and arrowheads. Existing
classes, bounds and default colors are unchanged. Opacity/intensity modifiers,
hex, HSV and CMYK custom formats are deliberately rejected.

The palette suite exports SVGs; scripts/check_palette_svg.py checks actual
rendered colors, matching marker/legend entries, reversed assignments, arrow
strokes/fills, and signed heatmap cells. It also compares full node and edge
exports across palettes and checks successful/failed calls preserve data,
estimates and RNG. The four-panel Stata gallery is build/palettes/comparison.png.

## HTML animation qualification (0.6)

Stata exports are checked against independently specified small histories, including
arrival-period counts, per-period employment, cumulative shared-worker links, hidden
destination denominators, selected/original adjacency and reversed net pairs. JSON
parsing checks ensure labels cannot terminate the inline script and large IDs remain
strings. Each artifact is audited for external scripts, fonts and network fetches.
The viewer executes against a minimal DOM/Canvas mock in Node, exercising drawing,
playback, stepping, scrubbing, theme, reset and pointer handlers with finite drawing
arguments. A missing canvas context must produce a visible diagnostic rather
than a blank graph. This is not a browser rendering test.

On 2026-10-10, the generated four-view gallery was also opened in the Codex in-app
browser through a loopback-only HTTP preview. Checked actual rendered canvases,
automatic period advancement, pause/play, restart, stepping, keyboard scrubbing,
speed/theme changes and empty-period notices, with no console errors. Browser
screenshots are retained under ignored `build/browser-checks/`. The initial ladder
periods have no observed moves; controls now appear above the plot and these periods
have an explanation. Ladder axes include 0 and 100 and leave room for the outside
label, fixing overlap visible in the browser but missed by the mock.

For developer reproduction, run `do examples/animations.do` in Stata, then serve
only `build/animation-gallery/` on a loopback address and open its four HTML files
through HTTP in the supported browser tool. Reload after regenerating artifacts.
Check both the first empty period and a populated period, not only page load or
console output. The HTTP preview is a development testing step, not a fegraph user
dependency. The automated/browser-tool checks did not exercise direct file opening.

The user subsequently clarified on 2026-10-10 that the blank graph occurred only
inside the Codex app's file preview. Downloading the same HTML and opening it in
Chrome on Android worked. This resolves the suspected Android-renderer failure
for that example. It is a user-confirmed device check, not a complete Android
qualification. The precise cause inside the preview has not been established;
do not describe a particular JavaScript or CSP restriction as confirmed. Delivery
instructions now say to download/save the HTML and open it in a browser if an
in-app preview shows a blank graph.

The runner requires Node.js for viewer unit checks (not for fegraph users). Optional
report workflows remain qualified at 0.3 and are not part of this animation change.
