# Validation and support

Version 0.8.0, checked 2026-10-13 on macOS with licensed Stata/MP 19.
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
| `interface.do` | Optional scores, explicit panel/endpoint IDs, attribute defaults/overrides, required-ID rejection, qualifiers, outside-score missingness and state preservation |
| `quantiles.do` | Native `xtile` reference comparisons with ties/skew/weights/descending scores, `collapse` bin means, worker-record multiplicity invariance, outside exclusion and move conservation |
| `consistency.do` | Common bins/outcomes across all five views, unique worker-bin/shared-bin counts, symmetric shared heatmaps, independent employment weights, score sorting, sample/exclusion checks, canonical names and independent HTML period counts |
| `routing.do` | Above/below separation, shared-endpoint lanes, reciprocal arrows, input-order invariance, curved marker clearance, tied ranks, nonmonotone levels, unchanged node values/counts, and a gross-flow render |
| `manybins.do` | 50/100/200-bin dense prepared-flow fixtures; conserved mass, node-scaling invariance, canonical names and scale guards |
| `help.do` | Stata SMCL rendering at widths 79/120, independent checks for literal directives and merged headings/paragraphs; fourteen native/HTML help blocks preserving data and estimates; missing-block failure |
| `reports.do` | All five optional help blocks: three individual DGP PDFs, combined PDF, compact pipeline; real fesim/fereg/ferank/latexlog/texpdf, paths with spaces, state restoration and overwrite guard |
| `classic.do` | Counts/node/edge/coordinate invariance across styles, input-order invariance, label quotas and ties, outside labels, empty graphs, option guards, directed arrows and two network renders |
| `palettes.do` | Named/custom palettes and reversal, all four views, worker/categorical colors, invalid-input guards, unchanged exported graphs and caller state; SVG checks verify marker, legend, arrow and heatmap colors |
| `animation.do` | All four views, aggregate/time frames, bins/outside/shared histories, rates/exposures, reversed net pairs, wage statistics, zero edges, nested paths/replacement, hostile labels, exact IDs and caller-state preservation; independent JSON and DOM/Canvas mock checks |
| `eventstudy.do` | Known wage paths; balanced windows and hierarchical exclusions; fixed endpoint groups; native quantile references including weights and ties; normalization; repeated-worker cluster SEs; exact string IDs; fractional time units; cohort filtering; invalid/overwrite guards; caller preservation and independent JSON checks |
| `package.do` | `net install` into an isolated local ado directory, fresh-process loading of installed ado/Mata/help, installed selftest, all four installed examples |
| `command_gallery.do` | Four figures written as PNG and PDF, with caller data restored; visual inspection of arrowheads, labels, legends and outside-state band |
| `integration.do` | Actual fesim AKM output, ferank Bradley–Terry percentiles/components, ranked ladder with externally supplied effects, heatmap, retained ferank estimation results and simulation RNG |

Tests verify data signatures and original row order, preserved estimation
coefficients and RNG state, both success and failure cases, and exact reuse of
exported coordinates. Graph geometry is deterministic for a given layout seed.
Numeric tolerances are used for floating-point wage changes and bin levels.


## Cross-view consistency (0.8)

All 17 licensed macOS Stata/MP 19 suites pass, including installation, the
14 ordinary help blocks, integration and five optional report blocks. The final
source hashes match the suite receipt.

The new consistency suite compares bin maps and gross/net totals across flow
views, worker-bin and shared-worker deduplication, equal/match/flow node sizing,
node-size-independent employment weights, explicit means versus externally
computed means, selected/original outcome samples, outside-state exclusion,
attribute overrides, bipartite score sorting and generic event outcomes. It
also checks bins(0) for eventstudy and rejection of undefined option combinations.
Independent JSON checks verify observed-period bipartite counts and cumulative
shared-worker connections after binning. Eight network HTML fixtures execute
against the DOM/Canvas mock; actual browser inspection separately checks binned
bipartite nodes, symmetric shared heatmap cells and general outcome profiles,
with playback/stepping and no console errors. Browser inspection uses loopback
HTTP on the desktop; this does not claim new Android hardware qualification.

`docs/options.md` records the option matrix and statistical differences between
flows, job matches and outcome profiles. The nineteenth runnable help block,
common_options, shares score/outcome/bins syntax across all five views. The
Stata help continues to pass the actual SMCL rendering checks at widths 79/120.
Exact-source suite receipts and logs remain in build/test-runs; analytic
fixtures and generated HTML are in build/consistency.

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
- This version implements firm, bipartite, ladder, heatmap and mover event-study
  views. Sorting maps remain a separate potential extension. Mover HTML highlights
  pooled event time or compares arrival cohorts; it does not animate individuals.

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
contain ten pages; the combined report contains twenty-eight, including twenty-seven
figures and nine companion event-study HTML files. Each model includes AKM-effect,
coworker-wage and mobility-score mover profiles. The report requires Stata 19, while the graph runtime still targets 16.

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

The runner requires Node.js for viewer unit checks (not for fegraph users). The
0.6 animation change retained earlier report qualification; 0.7 requalifies all
report workflows with the new mover profiles.

## Mover profiles (0.7)

Fifteen graph/integration suites plus the optional report suite qualify the
installed 0.7 interface on macOS Stata/MP 19. The event suite uses analytic wage
paths and an independent Python check of exported HTML means and cluster variances.
A repeated-mover fixture has changes 1 and 2 for one worker and 6 for another:
the event-weighted mean is 3 and the worker-cluster standard error is 2. Normalized
profiles subtract each event's baseline before both mean and uncertainty calculations.
Native xtile references check employment-weighted inputs; the shared percentile
engine preserves equal-firm semantics and supports more bins than distinct scores.

Cases include missing wages/groups, outside-state breaks, incomplete spells,
selected/original sampling, fractional time units, same-bin employer changes,
one-worker intervals, absent/suppressed cohorts, paths with spaces, HTML text
escaping and caller data/order/estimates/RNG preservation. Native annotations
can be overridden or suppressed on both panel and overlay graphs. Two-line notes
avoid clipping when embedded in portrait reports. Profile exports retain hidden
cells; HTML embeds only displayed aggregate means and counts.

The self-contained gallery is `build/eventstudy-gallery/fegraph_examples/`.
Actual reports use 6,000 workers, 80 firms and 12 annual observations for each
AKM, ladder and BM model. The combined PDF has 28 pages and 27 figures; all nine
new profile figures have matching standalone HTML and data tables. Event samples
contain 5,414, 5,281 and 3,711 moves respectively under the current seeded fixtures.
The reports preserve caller data, estimates, directory and RNG.

Browser checks use the supported loopback HTTP preview and cover actual canvases,
play/pause, restart, stepping, scrubbing, speed/theme controls, origin/destination
filtering, panel/overlay layouts, interval display, hover/tap details and cohort
counts. Screenshots and final artifact hashes are retained under
`build/eventstudy-review/`. A 390-by-844 viewport checks responsive layout; it is
not Android hardware qualification. The earlier user-confirmed download/open
workflow remains the delivery guidance for restricted in-app previews.

## Public installation preparation (2026-10-13)

The README and installation guide now use the raw GitHub package URL. The
0.7.0 runtime, report helper and test sources are byte-identical to the earlier
16-suite qualification; only help text and package descriptions changed.
A fresh isolated local installation and replacement installation pass with
all 16 installed files byte-matching the manifest sources. The README's panel
recipes, HTML/export commands and all 13 non-report help examples run against
the installed package. The five report entry points and their implementation
are unchanged from the full 0.7 report qualification.

Installation drivers, logs and exact file hashes are saved under ignored
`build/publication-20261013/`. Fresh and replacement installs from the public raw GitHub URL also pass,
including all 16 exact file hashes, the README commands and 13 non-report help
examples. Anonymous requests retrieve the exact README, installation guide,
manifest and preview images. Public and local receipts are stored separately.

## Help rendering (2026-10-13)

Explicit SMCL paragraph endings fix a reproduced rendering failure that exposed
formatting directives and merged the syntax and later sections. The opening
summary precedes navigation; installation instructions live in the README and
installation guide. `help.do` now translates the help through Stata's `smcl2txt`
renderer at widths 79 and 120. `check_help_render.py` checks for literal paragraph
directives, missing/merged headings and distinct syntax and late-file paragraphs.
All 18 runnable code blocks are unchanged. This checks actual Stata-rendered
output; direct GUI Viewer inspection was unavailable while the Mac was locked.
