{smcl}
{* *! version 0.1.0 09oct2026}{...}
{title:Title}
{pstd}{cmd:fegraph} {hline 2} Graphs for linked worker-firm data

{title:Syntax}
{pstd}Worker-period panel (same positional firm and worker/time convention as {cmd:ferank}):
{p 8 16 2}{cmd:fegraph} {it:firm} [{help if}] [{help in}],
{cmd:worker(}{it:workerid}{cmd:)} [{cmd:time(}{it:time}{cmd:)} {it:options}]

{pstd}Prepared moves or aggregated flows:
{p 8 16 2}{cmd:fegraph} {it:origin destination} [{help if}] [{help in}],
[{cmd:flow(}{it:count}{cmd:)} {it:options}]

{pstd}Each row contributes one move if {cmd:flow()} is omitted. It retains its
{cmd:ferank} meaning: an input weight, never a gross/net selector. Use {cmd:net}
to request net flows. Weights may be fractional; Stata weight syntax is not accepted.

{pstd}Firm/worker IDs may be numeric or string. Prepared endpoints must have the
same broad storage type. {cmd:nodecolor()}, {cmd:nodesize()} with variables,
{cmd:order()}, {cmd:level()}, {cmd:label()} and {cmd:effectgroup()} take one
variable for panels or two variables for flows, origin first and destination second.
Firm attributes must be constant within firm among their observed values.
Contradictions are errors. All data and estimation results remain unchanged.

{title:Quick start}
{pstd}Run self-contained examples, restoring your data:
{p 8}{stata fegraph_example, type(firm):fegraph_example, type(firm)}
{p 8}{stata fegraph_example, type(bipartite):fegraph_example, type(bipartite)}
{p 8}{stata fegraph_example, type(ladder):fegraph_example, type(ladder)}
{p 8}{stata fegraph_example, type(heatmap):fegraph_example, type(heatmap)}

{pstd}With your panel:
{cmd}
    fegraph firmid, worker(workerid) time(year) nodecolor(psi_hat) net
    fegraph firmid, worker(workerid) time(year) type(bipartite)
    fegraph firmid, worker(workerid) time(year) type(ladder) ///
        order(rank_pct) level(psi_hat) nodecolor(psi_hat) bins(10)
    fegraph firmid, worker(workerid) time(year) type(heatmap) ///
        order(psi_hat) bins(10) statistic(share)
{txt}
{pstd}These variable names are placeholders. Supply estimated effects or ranks
from outside fegraph. No estimation is performed.

{title:Views and edge definitions}
{phang}{cmd:type(firm|bipartite|ladder|heatmap)} selects the view; default {cmd:firm}.
Firm networks show firms and directed moves. Bipartite graphs show distinct
worker-firm matches, with large firm nodes and small worker nodes. Ladders
place a supplied level against the percentile of a supplied ordering attribute.
Heatmaps show origin (y) by destination (x).

{phang}{cmd:edge(moves|shared)} defaults to moves. Shared-worker graphs are
undirected: a worker seen at A, B, C links all three pairs, even without an A-C
move. Each worker counts once per pair. They require worker-firm data.
Bipartite edges count each match once regardless of repeated observations.
Time may be omitted for bipartite/shared views. With time supplied, duplicate
worker-time keys are errors. Without time, repeated matches are allowed.

{phang}{cmd:net} uses gross A-B minus gross B-A after aggregation. Network arrows
show only positive net differences. Heatmaps show signed net cells in both
directions, including implied reverse cells absent from the input. Balanced
pairs disappear; raw gross counts remain in the saved edge table. Net applies
to outside-state flows too. It cannot be combined with wage-change edge styling
or normalized statistics. Shared-worker and bipartite graphs are undirected counts.

{title:Panel sample and outside states}
{phang}{cmd:maxgap(}{it:#}{cmd:)} is the largest allowed time difference; default 1,
in the units of time(). Moves compare consecutive observations with changed,
known employers and a positive gap no larger than maxgap. Duplicate worker-time
keys, missing workers and missing times are errors. Missing firms break chains.
Snapshot moves are not latent events or event hazards. Irregular intervals
require a deliberate maxgap or a prepared edge table.

{phang}{cmd:sample(selected|original)} defaults to selected, matching ferank:
if/in select rows before forming adjacent observations. With maxgap above one,
selection can connect across excluded records. {cmd:sample(original)} instead
forms adjacencies in the original panel and requires both endpoints selected;
excluded records break chains. It validates original worker-time keys.

{phang}{cmd:nonemployment(}{it:indicator}{cmd:)} explicitly identifies panel
outside-state rows (1=outside, 0=otherwise). It overrides any employer ID on
those rows. Default label is Nonemployment. Unknown employers with indicator 0
remain unknown, not outside. Outside rows are excluded from bipartite/shared
matches. {cmd:outside(}{it:id}{cmd:)} identifies an existing outside node in
prepared flows. Both options are explicit; firm 0 has no automatic meaning.

{phang}{cmd:outsidelabel(}{it:text}{cmd:)} changes that label. Use Unemployment
only when the observed state supports it. On ladders, outside states occupy a
schematic band, with no estimated rank or effect. Boundaries/attrition do not
create outside-state flows. A-U-B contributes A-U and U-B, not A-B.

{title:Attributes and visual encoding}
{phang}{cmd:nodecolor(}{it:vars}{cmd:)} colors firms using seven equal-width numeric
classes. Missing attributes are gray. {cmd:categorical} instead assigns distinct
colors to up to seven numeric category codes; encode string categories first.
Categorical colors cannot be averaged into bins. Legends show codes, not value labels.

{phang}{cmd:nodesize(employment|matches|flow|equal|}{it:vars}{cmd:)} defaults to mean
employment for panels (selected records divided by the number of selected time
values) and total incident flow for prepared edges. Missing firm-date cells
contribute zero in the selected calendar. Without time, the panel default is
distinct matched workers. {cmd:matches} counts distinct workers even with time.
Supplied sizes must be nonnegative and nonmissing at employed firms. Sizes use
four common classes with upper bounds M/16, M/4, 9M/16, M. Positive marker area
represents each class, not an exact continuous area; zero sizes remain visible.
Worker markers have a fixed small size. Outside nodes use diamonds.

{phang}{cmd:label(}{it:vars}{cmd:)} supplies firm labels; default original IDs.
{cmd:nolabels} hides node labels. Display labels are truncated at 80 characters;
full IDs/labels are retained in saved data. Worker labels are prefixed with w:.

{phang}{cmd:workercolor(}{it:var}{cmd:)} gives a separate continuous worker-color
scale for bipartite graphs. It must be constant within worker.

{phang}{cmd:edgecolor(none|effect|wage)} defaults to a common teal. Effect means
destination minus origin level(), or nodecolor() if level is absent. With
categorical colors, supply a separate level(). Wage means average observed mover
wage change. Diverging colors are centered at zero; missing changes are gray.

{phang}{cmd:edgesize(flow|effect|wage)} uses flow/statistic by default or the
absolute effect/wage change. It is independent of edgecolor(). Four common
width classes have upper bounds M/16, M/4, 9M/16, M. Missing change statistics
receive the thinnest line. Arrows always follow movement, including wage losses.

{phang}{cmd:wage(}{it:var}{cmd:)} with {cmd:wagescale(log|level)} is panel-only.
Log wages yield destination minus origin log wage. Positive level wages yield
100*(destination/origin-1). Edge means use only moves with both wages observed;
the edge table reports the contributing count. Outside transitions have no wage
change. This is descriptive, not a causal effect.

{phang}{cmd:colorlimits(}{it:lo hi}{cmd:)}, {cmd:edgelimits(}{it:lo hi}{cmd:)},
{cmd:sizemax(}{it:#}{cmd:)} and {cmd:widthmax(}{it:#}{cmd:)} fix scales for comparisons.
Values beyond fixed bounds are capped into end classes. Edge limits must be
symmetric around zero. Colorlimits also sets the worker continuous scale when
workercolor is supplied. Heatmap colors use colorlimits, or edgelimits for net
cells. Defaults derive from displayed values. For legends, end classes include
clipped values. A zero size/width maximum requests automatic scaling.

{title:Statistics and rank aggregation}
{phang}{cmd:statistic(count|share|probability)} defaults to count. Share divides by
all departures from the origin, including hidden destinations. Probability
divides by all eligible known-state adjacent origin observations, including
stayers; it describes the observed interval, not an annualized hazard. Prepared
probabilities require {cmd:exposure(}{it:var}{cmd:)}, a constant full origin
exposure repeated on origin rows. Total departures cannot exceed exposure.
Self-moves in prepared input and same-firm continuations in panels are omitted.
Consequently probability rows need not sum to one.

{phang}{cmd:order(}{it:vars}{cmd:)} supplies the ladder ordering or heatmap/bin
ordering. Higher values normally receive higher percentiles. Use {cmd:descending}
for raw ferank ranks, where rank 1 is best, or use its increasing percentile.
Tied values get a common midrank. Ordering is separate from {cmd:level(}{it:vars}{cmd:)},
which supplies ladder height and defaults to order. Missing ordering/height among
selected ladder firms is an error. Coincident connected nodes require binning.

{phang}{cmd:bins(}{it:#}{cmd:)} aggregates selected firms for ladder/heatmap views;
0 (default) retains firms. Ties remain together and may yield fewer bins.
{cmd:binweight(firm|employment)} defaults to equal firm weights; employment uses
nodesize values. Boundaries derive from weighted cumulative order. Heights and
colors are weighted firm means; size and exposure are summed. Gross flows are
summed before netting, rates or thresholds. Within-bin moves remain in edge
exports and heatmaps; network ladders omit self-arrows but report their mass.
For comparisons, use a common analysis population/weights when deriving bins.

{phang}{cmd:effectgroup(}{it:vars}{cmd:)} supplies external comparability groups,
such as ferank component IDs. Selected firms must have a single known group.
Select a group first or explicitly use {cmd:pooled} to acknowledge comparability.
fegraph cannot infer the normalization of external effects. Its weak components
are distinct from ferank's strongly connected estimation components.

{title:Display selection and layouts}
{phang}{cmd:component(all|largest|}{it:#}{cmd:)} selects weak components; default all.
The outside-state node does not join otherwise disconnected firm components.
Largest chooses most firms; ties use deterministic ID order. Numeric IDs are
internally represented as exact strings, so component numbering is lexical.
Stayers and isolates are retained. Display selection keeps full denominators.

{phang}{cmd:ego(}{it:id}{cmd:)} and {cmd:steps(}{it:#}{cmd:)} retain an undirected
neighborhood of the named firm; default one step. Bipartite steps traverse match
edges. Outside states do not connect the neighborhood but remain visible.

{phang}{cmd:minflow(}{it:#}{cmd:)} removes displayed edges below the gross count,
or absolute net count, after aggregation. {cmd:top(}{it:#}{cmd:)} keeps the largest
absolute displayed statistics, breaking ties by endpoints; 0 retains all.
Net heatmaps select unordered pairs and show their reversals together.

{phang}{cmd:layout(force|circle|bipartite)} defaults to force for firms and
bipartite for match graphs. Ladders and heatmaps use their data-defined coordinates.
{cmd:seed(}{it:#}{cmd:)} and {cmd:iterations(}{it:#}{cmd:)} control reproducible force
layout; defaults 1 and 200 (up to 2000). Layout uses no Stata/Mata random draws.
Layout distances have no economic units. Reciprocal arrows use opposite curves.

{phang}{cmd:coordinates(}{it:nodes.dta}{cmd:)} reuses saved free-network coordinates
matched by kind and original ID. All displayed nodes require unique finite x/y.
It is unavailable for ladders/heatmaps. New unmatched nodes are errors.

{phang}{cmd:maxnodes(}{it:#}{cmd:)} and {cmd:maxedges(}{it:#}{cmd:)} are explicit
readability limits, default 200 and 1000. Exceeding them is an error suggesting
aggregation/selection, never silent sampling. Hard ceilings are 2000 nodes,
20000 edges and 100 heatmap nodes. Force repulsion is quadratic in displayed
nodes. Shared-worker projection permits at most five million pair contributions.
These are guards, not promises of readable figures at the upper limits.

{title:Graph and data output}
{phang}{cmd:name(}{it:name}{cmd:[, replace])}, {cmd:saving(}{it:file.gph}{cmd:)},
{cmd:nodraw} and {cmd:graphopts(}{it:twoway options}{cmd:)} control ordinary Stata
graphs. graphopts are applied last. Use {cmd:graph export} for PNG, SVG or PDF.

{phang}{cmd:nodefile(}{it:file.dta}{cmd:)}, {cmd:edgefile(}{it:file.dta}{cmd:)}, and
{cmd:mapfile(}{it:file.dta}{cmd:)} optionally save the audit data. {cmd:replace}
authorizes overwriting those files and saving(). Require explicit .dta/.gph
extensions and distinct paths. Files are written sequentially after rendering;
an I/O error can leave already-written files. Caller data remain unchanged.

{pstd}Node table: node index, original string id, label, kind (0 firm/bin,
1 worker, 2 outside), size, color, ordering, level, x/y, weak component,
displayed, exposure, effectgroup. Hidden nodes remain. Coordinates of hidden
nodes may be missing. Bins have IDs bin:1, etc. Normal-length IDs use str# for
merge compatibility; very long IDs use strL.

{pstd}Edge table: numeric origin/destination indices; string origin_id and
destination_id; gross, reverse, signed net, value (requested statistic), color,
width_value, displayed, wage_sum, wage_n and mean_wage_change. All gross pairs
remain, including hidden and within-bin pairs. A net arrow's wage mean is never
computed; saved wage means always describe that gross direction.

{pstd}Map table: original firm/outside ID to final node index and node_id,
including bin membership. The map excludes worker nodes in bipartite mode.

{title:Stored results}
{pstd}{cmd:r(summary)} contains the following scalars, also returned individually:
{p 8}N_input, N_workers, N_firms, N_matches, N_eligible, N_gaps, N_unknown,
N_components, N_nodes, N_edges, N_shown_nodes, N_shown_edges, flow_total,
flow_shown, flow_boundary, flow_within, flow_hidden_net, N_missing_color.

{pstd}N_firms counts known input firms before display selection; N_nodes counts
final nodes including hidden nodes and any bins/workers/outside state. N_edges
counts aggregated gross pairs, including within-bin pairs. N_eligible includes
stayers and explicit outside-state continuations; N_unknown counts adjacent
pairs with an unknown endpoint, within maxgap. Panel-only diagnostics are zero
for prepared input. N_missing_color counts displayed firm/bin nodes lacking color.

{pstd}flow_total is gross transition/match mass before display filtering.
flow_shown is gross mass represented by displayed edges; for net networks it
includes both underlying directions of each displayed pair. flow_boundary is
gross mass with exactly one displayed endpoint. flow_within is displayed-node
self-flow after aggregation, whether drawn or not. flow_hidden_net is total
gross mass minus summed positive net differences (including within-bin mass).
N_shown_edges counts displayed original gross pairs in net heatmaps, not all
rendered cells. Captions report coverage; there is no silent component selection.

{pstd}Macros: r(type), r(input), r(sample), r(version). {cmd:fegraph, version}
reports the version. {cmd:fegraph, selftest} runs a small preserving smoke test
and returns r(passed)=1 on success. It creates a named example graph.

{title:Requirements and qualification}
{pstd}Official Stata and Mata only. Source targets Stata 16 or newer. Licensed
execution has been checked on macOS Stata/MP 19; Stata 16-18 and Windows/Linux
have not been qualified. fesim and ferank are optional companions, not runtime
dependencies. The repository includes contract, scale, integration, rendering
and fresh-install checks. This is a private development package, not an SSC release.
