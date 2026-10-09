# fegraph design discussion

Original design discussion: 2026-10-09. This document preserves the motivation
and initial proposals. Johannes subsequently authorized implementation with
syntax consistent with `ferank`. The implemented interface and exact supported
options are authoritative in [help fegraph](../stata/fegraph.sthlp) and the
[README](../README.md); the subcommand syntax sketches below are historical.

Version 0.1.0 implements the firm, bipartite, ladder and heatmap views, both
panel and prepared-flow inputs, explicit outside states, rank bins, gross/net
flows, supplied attributes, layouts, display selection and audit tables.
The additional research figures in section 10 (beyond the heatmap) remain
possible extensions, not commands in this version. See [validation](validation.md)
for the actual qualification boundary.

## 1. Purpose and scope

The requested tool visualizes linked worker–firm datasets in Stata. It must be
useful for both simulation output and real administrative or survey panels.
The three initial views are a firm network, a worker–firm graph, and a job
ladder. Firm effects, firm ranks and other attributes come from outside the
command. The repository starts private.

Recommended scope: descriptive graphs with transparent statistical definitions,
reproducible layouts and ordinary Stata graph output. Estimation of AKM effects,
ranking models and causal wage gains belongs in other commands. `fesim` and
`ferank` are useful companions, not required runtime dependencies.

No screenshot was available with the initial request. The worker–firm design
therefore follows the written description; the gallery's two-row arrangement
is illustrative, not a reconstruction of a reference image.

## 2. Firm network: three distinct meanings of a link

Let F(j,k) count observed transitions from employer j to employer k among
eligible adjacent observations, excluding stayers.

| Mode | Definition | Direction | Recommended use |
| --- | --- | --- | --- |
| Shared workers | Number of distinct workers observed at both j and k in the selected window | Undirected | Connectivity of the worker–firm incidence graph |
| Gross moves | F(j,k), retaining F(k,j) separately | Origin to destination | Mobility volume and asymmetry |
| Net moves | F(j,k) − F(k,j) | Direction of the positive difference | Compact visualization of net reallocation |

A worker observed at A, B, then C contributes to the shared-worker A–C link
even without an A→C move. A worker who switches back and forth contributes
multiple transition events but only one distinct worker to a shared link.
An option to count distinct movers instead of move events must have a different
name and label. The default for a time-ordered panel should be gross moves;
shared-worker projection must be explicitly requested.

Net flows should be formed after gross counts are computed. Preserve both gross
directions in the exported edge table. A zero net link can conceal substantial
two-way movement: a caption should report gross movement hidden by netting.
For example, 100 A→B and 98 B→A gives net 2, not evidence of weak connectivity.

Recommended visual mapping:

- Node area: mean employment over the selected time window. Alternatives include
  employment at a specified date, unique workers and a supplied firm size.
- Node color: supplied firm effect, rank percentile, industry or another
  explicitly supplied attribute. Missing attributes get a neutral category.
- Edge width: move count, net magnitude, or a clearly defined flow rate.
- Edge color: mean observed wage change for movers, or destination minus origin
  firm effect. These are separate statistics with separate labels.
- Arrow direction: worker movement. Wage losses should change color, not reverse
  the direction of the move.

Width may optionally encode absolute wage change, with a diverging color for
its sign, but movement volume is the better default. A signed quantity cannot
be represented by width alone. Mean log wage change, percentage wage growth and
a difference in estimated firm effects must never share an ambiguous label.

For net arrows, the safest initial color is the destination–origin attribute
difference. Mean wage change for a synthetic net worker flow is not naturally
defined: if later allowed, specify whether it describes gross movers in the
displayed direction or a different explicit statistic.

Display reciprocal gross flows as offset or curved arrows. Clip arrow endpoints
at node boundaries so arrowheads remain visible. Use restrained labels, a
legend with actual widths and areas, a diverging scale centered at zero for
signed changes, and a common color scale across panels.

Offer deterministic circular layout first, followed by a seeded force-directed
Mata layout. Distances in these layouts have no economic units. Firm attributes
should color nodes without silently changing the coordinates. Allow saved
coordinates to be reused across dates and simulation designs.

## 3. Worker–firm graph

Use a bipartite graph with separate ID namespaces for workers and firms. A
worker whose ID equals a firm ID must remain a different node.

The default edge is one distinct worker–firm match over the selected window.
Repeated worker-period observations must not produce duplicate edges. Optional
edge weight can represent observed periods or explicitly measured spell
duration; these are not interchangeable in an irregular panel. Multiple spells
at the same firm should collapse to one match unless a spell-based view is
explicitly requested.

Large nodes represent firms and small nodes represent workers. Movers connect
firms, stayers appear as leaves. Worker attributes can color the worker nodes;
firm attributes can independently color firm nodes. The initial two-mode
layout places firms and workers in separate rows; a later clustered layout can
place workers near their firms and movers between firms.

This is the best view for teaching identification and inspecting small samples.
Dense real datasets need explicit worker selection, an ego neighborhood, a
selected component, or aggregation. Sampling individual rows is inappropriate
because it destroys job histories. Selecting whole workers preserves their
within-window matches but still changes the graph; disclose that selection.
Do not claim that visible bridges establish leave-one-worker-out identification.

## 4. Job ladder

Place firms on an empirical distribution curve:

- x: percentile of an ordering attribute, increasing from low to high.
- y: level of a supplied attribute, often the same firm wage effect.
- arrows: gross flows between firms or bins; optionally net flows.
- node area: employment or another declared firm-size measure.

Ordering and height should be separate options. For example, order by `ferank`
percentile while displaying AKM firm effects vertically; disagreement between
the two becomes substantively interesting. When both use AKM effects, the curve
is a quantile function rather than a freely positioned network.

`ferank` rank 1 is best, while its percentile increases toward better firms.
Recommend its supplied percentile for a left-to-right ladder. If raw ranks are
used, require or document their direction. Tied attributes should share a
midrank; never break economic ties using arbitrary firm IDs. State whether the
percentile distribution is firm-weighted or employment-weighted; recommend
firm-weighted percentiles initially, with size shown independently.

For real data, start with about ten explicitly requested rank bins. Define bin
boundaries from the selected firm population; offer firm and employment
weights explicitly and keep equal attribute values together even if this
yields fewer bins. Sum raw firm-to-firm flows into bin pairs before netting,
computing rates or thresholding. Retain within-bin moves in the data and report
them even if no self-loop is drawn. Bin heights should be the mean supplied
level under the declared weighting rule. In comparisons, fix bin boundaries
and coordinate/color scales across panels.

### Unemployment and missing observations

Show an observed unemployment state in a separated band below the ladder,
with a label and axis break or separator. Its location is schematic: it has no
AKM firm effect and no firm percentile. Do not set its effect to zero or to a
low numerical value that looks estimated.

An employment indicator alone identifies nonemployment, not necessarily
unemployment. Use the label “Nonemployment” unless an explicit labor-force
state supports “Unemployment.” A missing employer is not enough to infer either
state. Gaps, attrition and unknown employers break transition chains by
default. Observed A→U→B should generate A→U and U→B; it must not become a direct
A→B move. Entrants and exits at the sample boundaries are not assumed to have
come from or gone to unemployment.

Flow choices must state their denominators:

- Counts: total observed transitions in the window; initial recommended default.
- Destination share among movers: F(j,k) divided by all departures from j.
- Endpoint transition probability: F(j,k) divided by eligible observed origin
  person-periods, including stayers; specify interval length.
- Event hazard: event count divided by measured exposure time; requires event
  or spell inputs and is outside the first panel implementation.

Never normalize only over visible destination firms unless explicitly requested.
The initial gallery shows net job-to-job counts and gross unemployment flows;
both choices are stated in its subtitle.

## 5. Input contract and sample construction

### Initial input

A long panel with worker ID, firm ID and, for directed flows, a time variable.
IDs may be strings or numeric labels; internally map them to compact indices
without assuming IDs are consecutive integers. Require one job/state per
worker-time. Reject duplicate keys rather than choosing a main job implicitly.
Multiple simultaneous jobs need a user-specified main-job rule or a later
spell/match input mode.

Time is an observed snapshot, not a latent event time. Require the expected
interval to be known, allow explicit `delta()` and count only adjacent periods
at that interval. Report other gaps. `fesim` annual endpoints may hide several
latent monthly events; do not substitute latent transitions for observed flows.

The analysis window and graph display selection need separate semantics.
`if`/`in` should mark the analysis sample on the original rows. Form candidate
adjacencies on the original ordered panel, then require both endpoints to be
selected. Do not delete excluded rows and reconnect the remaining records.
Report selected observations, workers, firms, eligible transitions, unknown
states, time gaps and exclusions. Build transitions before graph-level edge
thresholding or subgraph display selection.

### Supplied attributes

Start with attributes merged into the panel. Require a single firm-level value
per selected firm (allowing repeated copies); reject contradictory values.
Missing attributes are retained with neutral styling and reported coverage.
Time-varying effects or size need an explicit reference date or aggregation rule.
Separate firm-level node-table input can follow when the core contract is stable.

External AKM effects may have component-specific normalizations. Supplied
`ferank` scores/ranks may be comparable only within their estimation components.
Accept a component identifier and keep incomparable groups in separate panels
or require an explicitly justified common scale. Weak components, strong
components and estimator-specific connected sets are different objects.

### Additional input later

A prepared edge table with origin, destination and flow count, plus an optional
node table. This supports spell-defined transitions, concurrent jobs handled
upstream, aggregate data and large datasets without rebuilding microdata.
Validate nonnegative gross weights and unique node keys; aggregate duplicate
edge rows explicitly. Precomputed signed net flows need their own declaration.

## 6. Proposed command shape

All syntax here is provisional and unimplemented.

```stata
* Direct flows, supplied firm effects, no dependence on fesim.
fegraph firm, worker(workerid) firm(firmid) time(time) delta(1) ///
    edge(moves) flow(gross) nodecolor(psi_hat) nodesize(employment)

* Same source data, net flows.
fegraph firm, worker(workerid) firm(firmid) time(time) delta(1) ///
    edge(moves) flow(net) nodecolor(psi_hat) nodesize(employment)

* Match incidence needs no time variable for its binary links.
fegraph bipartite, worker(workerid) firm(firmid) nodecolor(psi_hat)

* AKM quantile curve with bin-to-bin flows.
fegraph ladder, worker(workerid) firm(firmid) time(time) delta(1) ///
    order(psi_hat) level(psi_hat) bins(10) flow(gross)

* Ranking and wage premia on different axes.
fegraph ladder, worker(workerid) firm(firmid) time(time) delta(1) ///
    order(sorkin_pct) level(psi_hat) bins(10) flow(gross)
```

Potential shared options: `layout()`, `seed()`, `component()`, `minflow()`,
`nodesize()`, `nodecolor()`, `edgecolor()`, `edgesize()`, `labels()`,
`name()`, `saving()` and passthrough `graphopts()`. Avoid freezing the complete
option vocabulary until a real vertical slice demonstrates the defaults.
For observed wage changes, require a wage variable and explicit log/level units.
Outside-state syntax and the prepared-edge interface still need a concrete design.

## 7. Large datasets and honest reduction

Large microdata and large displayed graphs are separate problems. Aggregate a
large panel efficiently using sorted adjacent rows and sparse edge lists. Do
not allocate a firms-by-firms dense matrix. Shared-worker projection can grow
quadratically in the number of employers per worker; guard that path separately.

A readable figure usually needs tens of nodes, not every firm in a national
dataset. Provide explicitly requested rank bins, industry/region groups,
ego neighborhoods, components, or top flows. Aggregate first, then filter.
Never silently show only the largest component or drop small firms.

Report displayed versus full-sample workers, firms and gross flow, including
flow crossing the displayed boundary. Keep full-sample denominators when
showing rates for a subgraph. For too-large individual-node plots, stop with an
actionable suggestion to aggregate or select a subgraph. Calibrate numerical
limits using benchmarks rather than promising an arbitrary scale now.

## 8. Implementation and Stata feasibility

Recommended runtime: official Stata and Mata only. Stata's paired-coordinate
plots provide edges and arrows; scatter plots provide nodes. Ado code can
validate/aggregate data and build graph layers, while Mata computes layouts.
This is a recommendation aligned with the intended workflow, not an inherited
technical constraint from another repository.

- [pcarrow](https://www.stata.com/manuals/g-2graphtwowaypcarrow.pdf) draws directed
  paired-coordinate arrows and combines with other `twoway` plots.
- [pcspike](https://www.stata.com/manuals/g-2graphtwowaypcspike.pdf) supplies
  undirected segments for match links.
- [colorvar options](https://www.stata.com/manuals/g-3colorvar_options.pdf) support
  coloring by numeric variables in modern Stata. Older-version support can use
  a small number of explicit color groups.
- [graph export](https://www.stata.com/manuals/g-2graphexport.pdf) supports the
  output path; save `.gph` as well as exportable figures.

Straight edges and fixed layouts are straightforward. Variable edge widths,
curved reciprocal arrows, collision-free labels, clipped endpoints and stable
force layouts require custom work. Group edges into a bounded number of style
layers to avoid a plot per edge at scale. If widths/colors are binned, display
the bins honestly in the legend. The tiny gallery uses per-edge layers and illustrative Bezier curves for
clarity and makes no scalability claim; it is not a general arrow-routing engine.

Existing [nwcommands](https://nwcommands.org/) is a useful comparison for network
capabilities. The reason to build `fegraph` is the worker–firm data contract and
economic views, rather than a new general-purpose network toolkit. The initial
recommendation is a self-contained renderer, avoiding a required network package.

Suggested internal pipeline:

1. Validate IDs, time, states, attributes and sample; record diagnostics.
2. Construct matches/transitions once and retain gross counts.
3. Compute attributes and aggregations; calculate rates from full denominators.
4. Apply display selection; record omitted mass and boundary flows.
5. Compute or reuse coordinates; map visual scales.
6. Draw a named Stata graph and optionally save node/edge/diagnostic tables.

Preserve caller data, sort order and RNG state on success and error. Do not
overwrite estimation results. Layout seeds must not alter later simulations.
Optional saved tables should include original IDs, components, coordinates,
counts, denominators, wage-change coverage and the displayed-sample indicator.
Saved coordinates and a machine-readable settings record should reproduce a
figure across sessions.

Proposed baseline: Stata 16 syntax with grouped color fallbacks; qualify actual
versions before promising support. The gallery has only been executed on
macOS Stata/MP 19. Every eventually installed file should use the `fegraph`
prefix, with `fegraph__*` for helpers, to keep packaging compatible with SSC
namespace conventions. No installer should be advertised before code exists.

## 9. Development sequence and evidence

1. **Design/gallery (current):** inspect these three views and settle defaults.
2. **First usable command:** panel validation, shared transition tables, firm
   graph with circular layout and gross/net moves, basic bipartite layout,
   node attributes, ordinary graph saving and transparent sample diagnostics.
3. **Job ladder:** firm/bin percentiles, heights, correct bin aggregation,
   explicit unemployment/nonemployment and fixed comparison scales.
4. **Large-data and polish:** prepared edges, subgraphs, force layout, saved
   coordinates, curved reciprocal flows, annotations and performance tuning.
5. **Additional views:** flow heatmap first, then targeted diagnostic figures.

Meaningful implementation checks should use small panels with hand-computed
answers: repeat moves, stayers, A→U→B, unknown states, excluded rows, time gaps,
duplicate worker-time keys, tied ranks, repeated matches, string IDs, worker/firm
ID collisions, disconnected components and zero-net/high-gross pairs. Verify
bin flow conservation, full denominators, attribute missingness, observation
order and RNG restoration. Add `fesim` integration examples with known truths
and externally supplied `ferank` output without making either a dependency.
Rendering checks need visual inspection in addition to count assertions.

## 10. Further graph ideas, in priority order

1. **Origin–destination heatmap:** origin rank bins on one axis, destination
   bins on the other, color for counts or declared probabilities. More legible
   than dense arrows; include the outside state and within-bin mobility.
2. **Rank–effect comparison:** supplied revealed-preference percentile against
   firm wage effect, size by employment, color by sector; expose disagreement
   between pay and broader revealed attractiveness.
3. **Mover wage profiles:** event-time wages around moves, grouped by origin and
   destination firm bins; descriptive selection should be explicit.
4. **Sorting map:** supplied worker effects against firm effects, aggregated as
   a heatmap for real data. Estimation and normalization stay external.
5. **Connectivity diagnostics:** components and bridge/mover counts, carefully
   distinguished from estimator-specific leave-out admissibility.
6. **Worker trajectories and comparison panels:** selected complete careers,
   or the same firm coordinates before/after a simulated design change.

## 11. Decisions to discuss before implementation

- Is the first priority teaching with small simulations or exploring large real
  datasets? Recommendation: share one data model but ship the small-data views
  first, then add rank aggregation and prepared edges promptly.
- Is official Stata/Mata-only runtime the desired constraint? Recommendation: yes.
- Which Stata versions must be supported? Recommendation: start with a version
  16 target but qualify only the versions actually tested.
- Should rank percentiles be firm-weighted or employment-weighted by default?
  Recommendation: firm-weighted, with size shown by node area.
- What observed state variables will real datasets supply for unemployment?
  Recommendation: explicit mapping, never infer it solely from missing firm IDs.
- What license should apply when code is distributed? Leave unselected for now.

The original repository-creation request did not freeze these choices. Johannes
subsequently authorized full implementation of the visualization command; current
behavior and limitations are documented in the command help.
