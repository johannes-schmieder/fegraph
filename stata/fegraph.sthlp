{smcl}
{* *! version 0.8.0 13oct2026}{...}
{.-}
help for {cmd:fegraph} {right:(Johannes F. Schmieder)}
{.-}

{title:Title}
{pstd}
{cmd:fegraph} {hline 2} Graphs for linked worker-firm data
{p_end}

{pstd}
{cmd:fegraph} visualizes linked worker-firm data as firm networks, worker-firm
match graphs, job ladders, flow heatmaps, and mover wage profiles. It uses
externally supplied firm effects, ranks, or other scores, with options to group
firms into score quantiles and show observed worker flows or unemployment.
The command produces editable Stata graphs and can export standalone HTML
animations; it does not estimate firm effects or ranks.
{p_end}

{pstd}
{help fegraph##quickstart:Example} | {help fegraph##syntax:Syntax} |
{help fegraph##views:Graph types} | {help fegraph##classic:Classic networks} | {help fegraph##sample:Sample and unemployment} |
{help fegraph##attributes:Appearance} | {help fegraph##common:Common options}
{p_end}

{pstd}
{help fegraph##bins:Scores and bins} | {help fegraph##selection:Selection} |
{help fegraph##examples:Runnable examples} | {help fegraph##reports:DGP reports} |
{help fegraph##animation:Animations} | {help fegraph##eventstudy:Mover event studies} | {help fegraph##output:Output} | {help fegraph##stored:Stored results}
{p_end}

{marker quickstart}{...}
{title:Start with a firm graph}
{pstd}
The following complete example draws a firm network, colored by a supplied
wage effect. Worker and firm identifiers belong in options; the variable before
the comma supplies the score. Click below to run it and restore your original data.
{p_end}

{cmd}{...}
        preserve
{* example_start - firmgraph}{...}
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate byte unemployed = year==3 & mod(workerid,4)==0
        replace firmid = . if unemployed
        generate psi = (firmid-3.5)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(firmgraph) nonemployment(unemployed) outsidelabel(Unemployment) ///
            net name(fegraph_firmgraph, replace)
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run firmgraph using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{marker syntax}{...}
{title:Syntax}
{pstd}
Worker-period panel; the optional positional variable is a supplied firm score:
{p_end}
{p 8 16 2}
{cmd:fegraph} [{it:firmscore}] [{help if}] [{help in}],
{cmd:worker(}{it:workerid}{cmd:)} {cmd:firm(}{it:firmid}{cmd:)}
[{cmd:time(}{it:time}{cmd:)} {it:options}]
{p_end}

{pstd}
Prepared moves or aggregated flows; optional scores are origin then destination:
{p_end}
{p 8 16 2}
{cmd:fegraph} [{it:score_origin score_destination}] [{help if}] [{help in}],
{cmd:origin(}{it:origin_id}{cmd:)} {cmd:destination(}{it:destination_id}{cmd:)}
[{cmd:flow(}{it:count}{cmd:)} {it:options}]
{p_end}

{pstd}
Scores are numeric firm attributes supplied externally, not variables to
estimate or implicitly average over workers. They must be constant within firm among observed
values. They set the ordering and default {cmd:level()} and {cmd:nodecolor()};
explicit level/color options override those defaults. Heatmap color always
represents flows. Networks may omit a score; ladders and quantile bins require
one (a supplied score or a mean from explicit outcome()). {cmd:order()} is an equivalent explicit alternative. Conflicting positional
scores and order() are errors. Higher scores rank firms higher; {cmd:descending}
handles ordinal ranks where 1 is best. A force layout does not position firms by rank.
{p_end}

{pstd}
{cmd:worker()} and {cmd:firm()} identify panel IDs. Directed panel flows
require {cmd:time()}; match/shared-worker graphs may omit it. Prepared inputs use
both {cmd:origin()} and {cmd:destination()}; do not mix panel and endpoint ID options.
Each prepared row contributes one move if {cmd:flow()} is omitted. flow() retains
its ferank meaning: an input weight, never a gross/net selector. Use {cmd:net}
for net flows or {cmd:gross} for gross flows (the default). Weights may be fractional; Stata weight syntax is not accepted.
{p_end}

{pstd}
Firm/worker IDs may be numeric or string. Prepared endpoints must have the
same broad storage type. {cmd:nodecolor()}, {cmd:nodesize()} with variables,
{cmd:order()}, {cmd:level()}, {cmd:label()} and {cmd:effectgroup()} take one
variable for panels or two for flows, origin first and destination second.
All data and estimation results remain unchanged.
{p_end}

{pstd}
Add {cmd:animation(filename.html, options)} to export an animated HTML version;
see {help fegraph##animation:Animations}.
{p_end}

{marker views}{...}
{title:Views and edge definitions}
{phang}
{cmd:type(firmgraph|bipartite|ladder|heatmap|eventstudy)} selects the view; default {cmd:firmgraph}.
Firm networks show firms and directed moves. Bipartite graphs show distinct
worker-firm matches, with large firm nodes and small worker nodes. Ladders
place a supplied level against the percentile of a supplied ordering attribute.
Heatmaps show origin (y) by destination (x).
{p_end}

{pstd}
Ladder links use deterministic arcs on both sides of the line between
firms. Short links receive inner lanes; overlapping rank intervals and links
sharing endpoints use different lanes. Reciprocal gross arrows use opposite
sides. Above/below placement is only visual routing: arrowheads show movement,
and colors retain their supplied meaning. Equal-rank firms with distinct levels
use lateral arcs. Firm coordinates, statistics and outside-state flows are unchanged.
Dense graphs can still benefit from bins(), top() or minflow().
{p_end}

{phang}
{cmd:edge(moves|shared)} defaults to moves. Shared-worker graphs are
undirected: a worker seen at A, B, C links all three pairs, even without an A-C
move. Each worker counts once per pair. They require worker-firm data.
Bipartite edges count each match once regardless of repeated observations.
Omit edge() for bipartite; its links always represent worker-firm matches.
With bins(), count a worker once per worker-bin match or unordered bin pair.
Repeated jobs at different firms in the same bin do not multiply the link.
Time may be omitted for bipartite/shared views. With time supplied, duplicate
worker-time keys are errors. Without time, repeated matches are allowed.
{p_end}

{phang}
{cmd:gross} retains both observed flow directions (default).
{cmd:net} uses gross A-B minus gross B-A after aggregation. Specify at most one. Network arrows
show only positive net differences. Heatmaps show signed net cells in both
directions, including implied reverse cells absent from the input. Balanced
pairs disappear; raw gross counts remain in the saved edge table. Net applies
to outside-state flows too. It cannot be combined with wage-change edge styling
or normalized statistics. Shared-worker and bipartite graphs are undirected counts.
{p_end}

{marker sample}{...}
{title:Panel sample and outside states}
{phang}
{cmd:maxgap(}{it:#}{cmd:)} is the largest allowed time difference; default 1,
in the units of time(). Moves compare consecutive observations with changed,
known employers and a positive gap no larger than maxgap. Duplicate worker-time
keys, missing workers and missing times are errors. Missing firms break chains.
Snapshot moves are not latent events or event hazards. Irregular intervals
require a deliberate maxgap or a prepared edge table.
{p_end}

{phang}
{cmd:sample(selected|original)} defaults to selected, matching ferank:
if/in select rows before forming adjacent observations. With maxgap above one,
selection can connect across excluded records. {cmd:sample(original)} instead
forms adjacencies in the original panel and requires both endpoints selected;
excluded records break chains. It validates original worker-time keys.
{p_end}

{phang}
{cmd:nonemployment(}{it:indicator}{cmd:)} explicitly identifies panel
outside-state rows (1=outside, 0=otherwise). It overrides any employer ID on
those rows. Default label is Nonemployment. Unknown employers with indicator 0
remain unknown, not outside. Outside rows are excluded from bipartite/shared
matches. {cmd:outside(}{it:id}{cmd:)} identifies an existing outside node in
prepared flows. Both options are explicit; firm 0 has no automatic meaning.
{p_end}

{phang}
{cmd:outsidelabel(}{it:text}{cmd:)} changes that label. Use Unemployment
only when the observed state supports it. On ladders, outside states occupy a
schematic band, with no estimated rank or effect. Boundaries/attrition do not
create outside-state flows. A-U-B contributes A-U and U-B, not A-B.
{p_end}

{marker common}{...}
{title:Common options across graph types}
{pstd}
All five views accept the positional score or order(), bins(), binweight(),
descending, outcome(), palette(), sample(), nonemployment(), effectgroup(),
animation(), saving(), name(), nodraw and graphopts(). Their defaults and the
quantity plotted remain view-specific; use explicit bins() for comparisons.
{p_end}

{pstd}
Firmgraph, ladder and heatmap show directed moves and accept gross/net,
statistic(), minflow() and top(). All three also support undirected
shared-worker counts with edge(shared); shared heatmaps display symmetric cells
while exports and coverage count each unordered pair once.
Bipartite shows distinct job matches; eventstudy shows mean outcome paths.
These two views reject net/gross because neither plots directed flow totals.
{p_end}

{pstd}
Nodecolor(), level(), nodesize() and workercolor() describe nodes, heights or
links in the relevant network view. Heatmap cells always color flow statistics;
nodecolor() and categorical are rejected there. Event-study lines are colored
by destination group; palette() selects that sequence. Nonemployment remains
a separate state in directed flows, is excluded from job/shared matches, and
breaks event-study windows. These distinctions avoid assigning the same option
a different statistical meaning across graphs.
{p_end}

{marker attributes}{...}
{title:Attributes and visual encoding}
{phang}
{cmd:style(default|classic)} selects the appearance of a firmgraph.
Classic uses thin gray edges, smaller markers, neutral gray nodes when no color
attribute is supplied, and labels for the 15 largest displayed firms. Supplied
firm/edge colors remain active; directed moves retain their arrows. It does not
change graph counts, node sizes in the data, selection or coordinates. The
force layout remains the default; choose {cmd:layout(circle)} explicitly for a
circle. Other graph types accept only style(default).
{p_end}

{phang}
{cmd:labeltop(}{it:#}{cmd:)} labels at most the # largest displayed firms
by nodesize(), with ties broken by internal ID order. It is available for
firmgraph only. The default is all labels in style(default), or 15 in
style(classic). Zero suppresses firm labels; an outside-state label remains.
Use nolabels to hide every label, or labeltop(2000) to label every allowed firm.
Classic places labels in one of eight directions to reduce collisions and draws
them above the markers. Long labels and dense graphs may still require fewer
labels or a larger graph. Exported labels are never truncated by labeltop().
{p_end}

{phang}
{cmd:outcome(}{it:var}{cmd:)} explicitly computes firm means from selected,
nonmissing employed observations in panel data. Observations have equal weight;
repeated worker-period observations contribute once per row. Outside-state and
unknown-firm rows do not contribute. Means are pooled over the selected history,
including in HTML time playback. They supply default color and level, and the
ordering when no positional score/order() is supplied. Explicit nodecolor() and
level() override these defaults. With bins(), firm means are averaged using
binweight(); this is not necessarily the pooled person-row mean of the bin.
A firm with no observed outcomes has a missing mean. It cannot enter scored bins
or a ladder without another score/level. Prepared flows must supply attributes
externally. Fegraph computes descriptive means, never AKM effects or ranks.
{p_end}

{phang}
For eventstudy, outcome() supplies the individual variable to plot, without a
transformation or positivity restriction. Without a score/group(), its pooled
firm means also supply ordering. Wage() with wagescale(log|level) is the
wage-specific alternative with unit labels and positive-level validation;
supply exactly one of wage() and outcome(). Both plot the supplied values.
{p_end}

{phang}
{cmd:nodecolor(}{it:vars}{cmd:)} colors firms using seven equal-width numeric
classes. Missing attributes are gray. {cmd:categorical} instead assigns distinct
colors to up to seven numeric category codes; encode string categories first.
Categorical colors cannot be averaged into bins. Legends show codes, not value labels.
{p_end}

{phang}
{cmd:palette(}{it:name}{cmd:[, reverse])} selects node colors (including
workercolor()) and heatmap cell colors. Names are {cmd:viridis}, {cmd:blues},
{cmd:greens}, {cmd:grays}, {cmd:redblue}, and {cmd:brownteal}.
The default is viridis, except that net heatmaps default to brownteal.
These are fixed seven-color sequences, not continuous gradients. The reverse
suboption reverses colors without reversing scores, ranks, classes or labels.
For example: {cmd:palette(blues, reverse)}.
{p_end}

{phang}
{cmd:edgepalette(}{it:name}{cmd:[, reverse])} selects the colors of links
and arrowheads when edgecolor(effect) or edgecolor(wage) is active; default
brownteal. Use palette(), not edgepalette(), for heatmaps, including net cells.
Edgepalette has no effect with edgecolor(none). Uncolored/missing nodes, outside
nodes, missing changes and zero/hidden heatmap cells retain their neutral colors.
{p_end}

{pstd}
Both options also accept exactly seven colors, in low-to-high order,
instead of a name. Use plain named Stata colors or individually quoted RGB
triplets with integer components from 0 through 255. For example:
{cmd:palette(navy blue cyan gs14 yellow orange "190 30 45")}.
Append {cmd:, reverse} to reverse a custom list. Opacity/intensity modifiers,
hex, HSV and CMYK specifications are not supported in these lists. These options
set colors explicitly, so a graph scheme does not override them.
{p_end}

{pstd}
Palettes change appearance only. Color limits, class membership, supplied
attributes, graph selection, counts and coordinates are unchanged. Redblue runs
from red through a light center to blue; brownteal runs from brown/orange through
a gray center to teal. Edge changes and net heatmaps have symmetric limits about
zero. For a diverging node palette centered at zero, also set symmetric
colorlimits(), such as {cmd:palette(redblue) colorlimits(-.5 .5)}.
With categorical, colors follow ascending category codes; fewer than seven
categories use the first colors of the resolved sequence.
{p_end}

{phang}
{cmd:nodesize(employment|matches|flow|equal|}{it:vars}{cmd:)} defaults to mean
employment for panels (selected records divided by the number of selected time
values) and total incident flow for prepared edges. Missing firm-date cells
contribute zero in the selected calendar. Without time, the panel default is
distinct matched workers. {cmd:matches} counts distinct workers even with time.
Supplied sizes must be nonnegative and nonmissing at employed firms. Sizes use
four common classes with upper bounds M/16, M/4, 9M/16, M. Positive marker area
represents each class, not an exact continuous area; zero sizes remain visible.
Worker markers have a fixed small size. Outside nodes use diamonds.
{p_end}

{phang}
{cmd:nodescale(}{it:#}{cmd:)} multiplies marker diameters and the matching
arrow clearance. Default 1, or .35 with style(classic); positive values up to 5 are accepted. For many bins,
try {cmd:nodescale(.35) nolabels top(60)}. It changes appearance only, leaving
sizes, score quantiles, flows and saved coordinates unchanged. Use the same
nodescale and sizemax across panels when comparing marker areas.
{p_end}

{phang}
{cmd:label(}{it:vars}{cmd:)} supplies firm labels; default original IDs.
{cmd:nolabels} hides node labels. Display labels are truncated at 80 characters;
full IDs/labels are retained in saved data. Worker labels are prefixed with w:.
{p_end}

{phang}
{cmd:workercolor(}{it:var}{cmd:)} gives a separate continuous worker-color
scale for bipartite graphs. It must be constant within worker.
{p_end}

{phang}
{cmd:edgecolor(none|effect|wage)} defaults to a common teal. Effect means
destination minus origin level(), or nodecolor() if level is absent. With
categorical colors, supply a separate level(). Wage means average observed mover
wage change. Diverging colors are centered at zero; missing changes are gray.
{p_end}

{phang}
{cmd:edgesize(flow|effect|wage)} uses flow/statistic by default or the
absolute effect/wage change. It is independent of edgecolor(). Four common
width classes have upper bounds M/16, M/4, 9M/16, M. Missing change statistics
receive the thinnest line. Arrows always follow movement, including wage losses.
{p_end}

{phang}
{cmd:wage(}{it:var}{cmd:)} with {cmd:wagescale(log|level)} is panel-only.
Log wages yield destination minus origin log wage. Positive level wages yield
100*(destination/origin-1). Edge means use only moves with both wages observed;
the edge table reports the contributing count. Outside transitions have no wage
change. This is descriptive, not a causal effect.
{p_end}

{phang}
{cmd:colorlimits(}{it:lo hi}{cmd:)}, {cmd:edgelimits(}{it:lo hi}{cmd:)},
{cmd:sizemax(}{it:#}{cmd:)} and {cmd:widthmax(}{it:#}{cmd:)} fix scales for comparisons.
Values beyond fixed bounds are capped into end classes. Edge limits must be
symmetric around zero. Colorlimits also sets the worker continuous scale when
workercolor is supplied. Heatmap colors use colorlimits, or edgelimits for net
cells. Defaults derive from displayed values. For legends, end classes include
clipped values. A zero size/width maximum requests automatic scaling.
{p_end}

{marker bins}{...}
{title:Statistics and rank aggregation}
{phang}
{cmd:statistic(count|share|probability)} defaults to count. Share divides by
all departures from the origin, including hidden destinations. Probability
divides by all eligible known-state adjacent origin observations, including
stayers; it describes the observed interval, not an annualized hazard. Prepared
probabilities require {cmd:exposure(}{it:var}{cmd:)}, a constant full origin
exposure repeated on origin rows. Total departures cannot exceed exposure.
Self-moves in prepared input and same-firm continuations in panels are omitted.
Consequently probability rows need not sum to one.
{p_end}

{phang}
{cmd:order(}{it:vars}{cmd:)} is the explicit alternative to the positional
firm score. With either form, higher scores normally receive higher percentiles.
Use {cmd:descending} for raw ferank ranks where 1 is best. Tied scores receive
a common midrank. Ordering is separate from {cmd:level(}{it:vars}{cmd:)}, which
supplies ladder height and defaults to the score. Selected ladder/binned firms
need known scores; ladder firms also need known heights. Missing scores on an
explicit outside state are allowed. Coincident connected nodes require binning.
{p_end}

{phang}
{cmd:bins(}{it:#}{cmd:)} combines firms into {it:#} score-quantile bins
for every graph type, analogous to binned scatterplots. Default 0 retains
individual firms; eventstudy defaults to 4 but also accepts 0.
A value of 1 pools all selected firms. Bipartite retains individual worker nodes.
Maximum requested bins is 2000,
subject to the graph's displayed-node limits. Quantiles use one observation per
selected firm, not one per worker-period record. Cutpoints follow Stata's default
{help xtile} definition; a score equal to a cutpoint goes in the lower bin.
Ties are never split, so unequal sizes and fewer nonempty bins are possible.
Empty bins are omitted, retaining original quantile numbers in labels/IDs.
Unemployment is outside the score distribution and remains a separate node.
{p_end}

{phang}
{cmd:binweight(firm|employment)} defaults to equal firm weights. Employment
uses mean observed employment for panels and requires time(); changing nodesize()
does not change these weights. For prepared flows, supply employment values
explicitly in nodesize(origin_employment destination_employment). Zero weights do not determine cutpoints; an all-zero
bin is an error. Bin height, ordering, color and ladder percentile are weighted
means of the member-firm values; employment, supplied size and exposure are summed.
With nodesize(equal), bins remain equally sized. With nodesize(matches), bin
size counts distinct workers; flow sizes use the aggregated incident links. Quantiles are
computed after component/ego selection but before edge thresholds. Gross flows
are summed before netting, rates or thresholds. Within-bin moves remain in
exports and heatmaps; firmgraphs and ladders omit self-arrows and report their mass.
For shared-worker graphs, within-bin mass counts workers connected to at least
two member firms, once per bin. It is distinct from directed within-bin moves. Repeated
same-firm observations are not moves. Use a common sample/weights for comparisons.
{p_end}

{phang}
{cmd:effectgroup(}{it:vars}{cmd:)} supplies external comparability groups,
such as ferank component IDs. Selected firms must have a single known group.
Select a group first or explicitly use {cmd:pooled} to acknowledge comparability.
fegraph cannot infer the normalization of external effects. Its weak components
are distinct from ferank's strongly connected estimation components.
{p_end}

{marker selection}{...}
{title:Display selection and layouts}
{phang}
{cmd:component(all|largest|}{it:#}{cmd:)} selects weak components; default all.
The outside-state node does not join otherwise disconnected firm components.
Largest chooses most firms; ties use deterministic ID order. Numeric IDs are
internally represented as exact strings, so component numbering is lexical.
Stayers and isolates are retained. Display selection keeps full denominators.
{p_end}

{phang}
{cmd:ego(}{it:id}{cmd:)} and {cmd:steps(}{it:#}{cmd:)} retain an undirected
neighborhood of the named firm; default one step. Bipartite steps traverse match
edges. Outside states do not connect the neighborhood but remain visible.
{p_end}

{phang}
{cmd:minflow(}{it:#}{cmd:)} removes displayed edges below the gross count,
or absolute net count, after aggregation. {cmd:top(}{it:#}{cmd:)} keeps the largest
absolute displayed statistics, breaking ties by endpoints; 0 retains all.
Net heatmaps select unordered pairs and show their reversals together.
{p_end}

{phang}
{cmd:layout(force|circle|bipartite)} defaults to force for firms and
bipartite for match graphs. Circle layouts and the bipartite firm row follow
score order (reversed by descending); force positions express connectivity.
Ladders and heatmaps use their data-defined coordinates.
{cmd:seed(}{it:#}{cmd:)} and {cmd:iterations(}{it:#}{cmd:)} control reproducible force
layout; defaults 1 and 200 (up to 2000). Force layout starts from a deterministic disk and applies mild centering so
isolates do not spread arbitrarily far from the connected graph.
Layout uses no Stata/Mata random draws.
Layout distances have no economic units. Reciprocal arrows use opposite curves.
{p_end}

{phang}
{cmd:coordinates(}{it:nodes.dta}{cmd:)} reuses saved free-network coordinates
matched by kind and original ID. All displayed nodes require unique finite x/y.
It is unavailable for ladders/heatmaps. New unmatched nodes are errors.
{p_end}

{phang}
{cmd:maxnodes(}{it:#}{cmd:)} and {cmd:maxedges(}{it:#}{cmd:)} are explicit
readability limits, default 200 and 1000. Exceeding them is an error suggesting
aggregation/selection, never silent sampling. Hard ceilings are 2000 nodes,
20000 edges and 100 heatmap nodes. Force repulsion is quadratic in displayed
nodes. Shared-worker projection permits at most five million pair contributions.
These are guards, not promises of readable figures at the upper limits.
Ladders work with 50, 100 or 200 nonempty bins, subject to those limits. The
outside state counts as one additional node. Use maxnodes(201) for 200 bins
plus unemployment. Dense ladders can have quadratically many edges; reduce
arrows with top()/minflow() or use a heatmap with fewer bins. Removing labels
and shrinking markers does not change which flows are included.
{p_end}

{marker examples}{...}
{title:More self-contained examples}
{pstd}
Examples below need only fegraph, except those in Reports. Every clickable
block contains its own data generation and can be run independently. The runner
reads the code displayed in this help file; it restores data and estimation results even on failure.
{p_end}

{title:Common syntax with score bins and outcome means}
{pstd}
The same score, outcome and bins work in all five views. Worker nodes remain
individual in bipartite. Eventstudy uses the individual outcome as its y-axis.
The example saves one HTML artifact per view in fegraph_examples/.
{p_end}
{cmd}{...}
        preserve
{* example_start - common_options}{...}
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate psi = (firmid-3.5)/10
        generate double lnwage = 4+psi+.02*workerid+.01*year
        capture mkdir fegraph_examples
        foreach view in firmgraph bipartite ladder heatmap eventstudy {
            fegraph psi, worker(workerid) firm(firmid) time(year) ///
                type(`view') bins(3) outcome(lnwage) palette(blues) ///
                name(fegraph_common, replace) ///
                animation("fegraph_examples/common-`view'.html", mode(time) replace)
        }
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run common_options using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Worker--firm matches}
{pstd}
Select complete histories for a handful of workers. Outside observations
are excluded because unemployment is not a worker--firm match.
{p_end}

{cmd}{...}
        preserve
{* example_start - bipartite}{...}
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate byte unemployed = year==3 & mod(workerid,4)==0
        replace firmid = . if unemployed
        generate psi = (firmid-3.5)/10
        fegraph psi if workerid<=6, worker(workerid) firm(firmid) time(year) ///
            type(bipartite) nonemployment(unemployed) ///
            name(fegraph_bipartite, replace)
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run bipartite using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Quantile ladder with unemployment}
{pstd}
Three bins group the six firms by their supplied score. Unemployment stays separate.
{p_end}

{cmd}{...}
        preserve
{* example_start - ladder}{...}
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate byte unemployed = year==3 & mod(workerid,4)==0
        replace firmid = . if unemployed
        generate psi = (firmid-3.5)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(ladder) bins(3) nonemployment(unemployed) ///
            outsidelabel(Unemployment) name(fegraph_ladder, replace)
        display "Nonempty firm bins: " r(N_bins)
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run ladder using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Flow heatmap}
{pstd}
Shares use all departures from each origin as their denominator.
{p_end}

{cmd}{...}
        preserve
{* example_start - heatmap}{...}
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate byte unemployed = year==3 & mod(workerid,4)==0
        replace firmid = . if unemployed
        generate psi = (firmid-3.5)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(heatmap) bins(3) statistic(share) ///
            nonemployment(unemployed) outsidelabel(Unemployment) ///
            name(fegraph_heatmap, replace)
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run heatmap using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Fifty bins from a prepared flow table}
{pstd}
This artificial 200-firm flow matrix illustrates scale and syntax, not a labor-market model.
{p_end}

{cmd}{...}
        preserve
{* example_start - manybins}{...}
        clear
        set obs 40000
        generate origin = ceil(_n/200)
        generate destination = mod(_n-1,200)+1
        drop if origin==destination
        generate origin_score = origin/200
        generate destination_score = destination/200
        generate moves = 1+mod(17*origin+31*destination,13)
        fegraph origin_score destination_score, origin(origin) ///
            destination(destination) flow(moves) type(ladder) bins(50) ///
            net top(60) nodescale(.35) nolabels name(fegraph_manybins, replace)
        assert r(N_bins)==50
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run manybins using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}


{marker classic}{...}
{title:Classic force-directed networks}
{pstd}
This illustrative network has twelve hubs and sixty peripheral firms.
Each synthetic worker has jobs at two firms; edge(shared) joins those employers.
It is a complete constructed example, not an empirical or calibrated labor market.
All 80 firm pairs and 289 shared-worker connections are retained. Larger markers
represent more distinct matched workers. Node position has no economic units.
The monochrome style follows the typical hub-and-periphery appearance in
{browse "https://noduslabs.com/research/knowledge-graphs-type-document/attachment/hitech-companies-graph-connections/":this Nodus Labs reference}.
{p_end}

{title:Monochrome network}
{cmd}{...}
        preserve
{* example_start - classic}{...}
        clear
        set obs 80
        generate origin = ceil(_n/5)
        generate destination = 12+_n
        replace origin = _n-60 if _n>60
        replace destination = mod(origin,12)+1 if _n>60
        replace origin = _n-72 if _n>72
        replace destination = origin+4 if _n>72
        generate connections = 1+mod(_n,4)
        replace connections = 4+mod(_n,7) if _n>60
        expand connections
        generate workerid = _n
        expand 2
        bysort workerid: generate year = _n
        generate firmid = cond(year==1,origin,destination)
        generate psi = (cond(firmid<=12,firmid,ceil((firmid-12)/5))-6.5)/12
        generate str16 firmname = "Firm " + string(firmid)
        keep workerid year firmid psi firmname
        fegraph , worker(workerid) firm(firmid) time(year) ///
            type(firmgraph) edge(shared) style(classic) nodesize(matches) ///
            label(firmname) labeltop(12) iterations(600) seed(7) ///
            name(fegraph_classic, replace) ///
            graphopts(xsize(9) ysize(8))
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run classic using fegraph.sthlp:Click to run this example}
(your original data and estimates are restored).
{p_end}

{title:Network colored by supplied firm effect}
{cmd}{...}
        preserve
{* example_start - classic_color}{...}
        clear
        set obs 80
        generate origin = ceil(_n/5)
        generate destination = 12+_n
        replace origin = _n-60 if _n>60
        replace destination = mod(origin,12)+1 if _n>60
        replace origin = _n-72 if _n>72
        replace destination = origin+4 if _n>72
        generate connections = 1+mod(_n,4)
        replace connections = 4+mod(_n,7) if _n>60
        expand connections
        generate workerid = _n
        expand 2
        bysort workerid: generate year = _n
        generate firmid = cond(year==1,origin,destination)
        generate psi = (cond(firmid<=12,firmid,ceil((firmid-12)/5))-6.5)/12
        generate str16 firmname = "Firm " + string(firmid)
        keep workerid year firmid psi firmname
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(firmgraph) edge(shared) style(classic) nodesize(matches) ///
            label(firmname) labeltop(12) iterations(600) seed(7) ///
            name(fegraph_classic_color, replace) ///
            graphopts(xsize(9) ysize(8))
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run classic_color using fegraph.sthlp:Click to run this example}
(your original data and estimates are restored).
{p_end}

{pstd}
For your own panel, use {cmd:edge(shared)} for undirected connections
between employers sharing workers over the selected window. This differs from
adjacent moves: a worker seen at A, B and C connects all three pairs. Use the
default {cmd:edge(moves)} with {cmd:time()} for directed adjacent transitions,
and add {cmd:net} for net arrows. All variants accept {cmd:style(classic)};
supplying a score before the comma colors firms by that score.
{p_end}

{title:Choose palettes for firms and flow arrows}
{pstd}
This complete seven-firm example uses a blue node gradient and red-to-blue
arrows for changes in the supplied effect. Replace palette(blues) with a custom
list or palette(blues, reverse) to change its direction. Titles and notes can
be suppressed independently through graphopts().
{p_end}

{cmd}{...}
        preserve
{* example_start - palettes}{...}
        clear
        set obs 7
        generate workerid = _n
        expand 2
        bysort workerid: generate year = _n
        generate firmid = cond(year==1,workerid,mod(workerid,7)+1)
        generate psi = (firmid-4)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(firmgraph) style(classic) layout(circle) ///
            palette(blues) edgecolor(effect) edgepalette(redblue) ///
            name(fegraph_palettes, replace) ///
            graphopts(title("Custom palettes") subtitle("") note(""))
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run palettes using fegraph.sthlp:Click to run this example}
(your original data and estimates are restored).
{p_end}

{marker animation}{...}
{title:Standalone HTML animations}
{phang}
{cmd:animation(}{it:filename.html}{cmd:[, }{it:options}{cmd:])} creates one
self-contained HTML file alongside the ordinary Stata graph. Quote paths with spaces
or commas. All animation settings, including {cmd:replace}, belong inside this option.
Top-level replace does not authorize replacing the HTML file. {cmd:nodraw} suppresses
the Stata graph window. Open the HTML file in a modern browser; it contains the viewer,
styles and plotted data and makes no network requests. No Python, Node or server is required.
If an in-app preview shows a blank plot, download/save the HTML and open it directly
in a browser. The downloaded example has been confirmed working in Chrome on Android
when the Codex file preview showed a blank graph.
{p_end}

{phang}
{cmd:mode(aggregate|time)} defaults to aggregate. Aggregate motion illustrates
the specified pooled graph, not calendar time or individual worker trajectories.
Time mode requires time() for panels or prepared flows. Directed transitions belong
to their arrival period after applying sample()/maxgap(). Bipartite links show observed
jobs in each period. Shared-worker connections accumulate through the displayed period;
a worker contributes once after first being observed at both firms. Missing jobs are
not imputed. Unemployment follows the existing rules for the selected graph type.
{p_end}

{pstd}
Layout, selected nodes/edges, score bins and supplied attributes remain fixed
across frames. Pooled top()/minflow()/net selection is retained: pairs with zero pooled
net flow do not appear, even if they have offsetting period flows. Selected net pairs
can reverse direction by period. Employment/matches/flow node sizes are period-specific;
equal or supplied sizes stay fixed. Worker markers show observed current employment.
Shares use full departures; panel probabilities include eligible stayers in exposure.
Prepared probabilities are not supported in time mode because period-specific exposures
are not provided. Prepared count/share inputs may include time() for time playback only.
{p_end}

{phang}
{cmd:theme(auto|light|dark)} defaults to the browser's system preference.
{cmd:speed(}{it:#}{cmd:)} sets playback speed, default 1, positive and at most 20.
The viewer provides pause/restart, period stepping/scrubbing, hover details and network
zoom/pan. It respects reduced motion by starting paused. Particle counts are capped
for performance without changing displayed statistical values.
{p_end}

{phang}
{cmd:title(}{it:text}{cmd:)}, {cmd:subtitle(}{it:text}{cmd:)}, and
{cmd:note(}{it:text}{cmd:)} replace HTML annotations. {cmd:notitle},
{cmd:nosubtitle}, {cmd:nonotes}, {cmd:nolegend}, and {cmd:nocommand} suppress them
or the export metadata panel. These are suboptions of animation(). Native graphopts()
applies only to the Stata graph; exporting HTML with graphopts() prints a notice.
{p_end}

{pstd}
Existing palette(), edgepalette(), limits, node scaling and label selection
apply. Time color/size/width scales are fixed over all frames. HTML resolves bg/fg
colors to white/black. Maximum 500 periods and two million displayed node/edge frames,
in addition to normal graph limits. HTML contains plotted data, including worker IDs
in bipartite graphs. r(animation), r(animation_mode), and r(N_frames) describe the export.
Playback controls appear above the plot. An explanatory message accompanies periods
with no moves; the first period normally has no earlier observation to compare.
Checks cover licensed Stata generation, exported values, viewer unit execution and
actual browser rendering/playback of the gallery over local HTTP. The user also
confirmed the downloaded example in Chrome on Android; a full Android test suite
has not been run.
{p_end}

{title:Animate a firm network}
{cmd}{...}
        preserve
{* example_start - animation}{...}
        capture mkdir fegraph_examples
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate psi = (firmid-3.5)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(firmgraph) style(classic) palette(viridis) ///
            animation("fegraph_examples/network.html", theme(auto) replace) ///
            name(fegraph_animation, replace)
        display "Open in a browser: " r(animation)
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run animation using fegraph.sthlp:Click to create this animation}
(your original data and estimates are restored).
{p_end}

{title:Replay a binned ladder with unemployment}
{cmd}{...}
        preserve
{* example_start - animation_time}{...}
        capture mkdir fegraph_examples
        clear
        set obs 120
        generate workerid = ceil(_n/6)
        generate year = mod(_n-1,6)+1
        generate firmid = mod(floor((workerid-1)/3)+floor((year-1)/2),6)+1
        generate byte unemployed = year==3 & mod(workerid,4)==0
        replace firmid = . if unemployed
        generate psi = (firmid-3.5)/10
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(ladder) bins(3) nonemployment(unemployed) ///
            outsidelabel(Unemployment) ///
            animation("fegraph_examples/ladder-time.html", mode(time) ///
                theme(dark) speed(.5) replace) name(fegraph_time, replace)
        display "Open in a browser: " r(animation)
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run animation_time using fegraph.sthlp:Click to create this time animation}
(your original data and estimates are restored).
{p_end}

{marker eventstudy}{...}
{title:Mover event studies}
{pstd}
{cmd:type(eventstudy)} plots worker wage profiles around observed employer
changes, inspired by Figures V and VII of Card, Heining and Kline (2013),
{it:Quarterly Journal of Economics} 128(3), 967-1015, doi:10.1093/qje/qjt006.
These are descriptive event-weighted means, not regression coefficients or a
causal estimator. A flat pre-profile does not establish exogenous mobility.
{p_end}

{p 8 12 2}
{cmd:fegraph} {it:firmscore}, {cmd:worker(}{it:id}{cmd:)}
{cmd:firm(}{it:id}{cmd:)} {cmd:time(}{it:period}{cmd:)}
{cmd:type(eventstudy) outcome(}{it:var}{cmd:)}
{cmd:bins(4) window(-2 1)}
{p_end}

{phang}
{cmd:outcome()} supplies a general outcome without transformation.
Alternatively, {cmd:wage()} supplies wages, separately from the ranking score.
With {cmd:wagescale(log)}, values are already log wages; with
{cmd:wagescale(level)}, positive wage levels are plotted directly. No automatic
logarithm, percent-change conversion, regression or residualization is performed
in this view. Residual log wages may be supplied under wagescale(log).
{p_end}

{phang}
{cmd:window(}{it:first last}{cmd:)} defaults to {cmd:-2 1}; first must be
negative, last nonnegative, and at most 101 periods are allowed. Period 0 is the
first observation at the new employer. {cmd:delta(}{it:#}{cmd:)} defaults to 1
and defines one period in the units of time(). Every window observation must be
present exactly at arrival + event_time*delta(), selected, employed, and at the
origin before 0 or destination from 0 onward. Windows are always balanced.
Missing outcomes (or nonpositive wage levels) exclude the entire event.
There is no maxgap() bridging in this view.
{p_end}

{pstd}
Candidates are adjacent selected employed observations with different known
firm IDs. Gaps then fail the window check. Missing employers and explicit
{cmd:nonemployment()} observations break spells; they are never assigned zero log
wages. With sample(original), excluded original rows also break windows; default
sample(selected) first removes them. Duplicate worker-time keys are errors.
Annual snapshots do not establish uninterrupted job-to-job moves between dates.
{p_end}

{phang}
{cmd:bins()} defaults to 4 here (nonnegative integer, at most 2000);
0 retains individual firms ordered by score. Equal-firm quantiles
use the shared Stata-percentile engine on one record per selected employed firm with an observed score, before event
restrictions. Tied scores stay together. Missing scores are filled only from
other selected records of the same firm; conflicting scores are errors.
{cmd:binweight(employment)} weights firms by selected employed observations;
{cmd:descending} reverses the score before binning. Bins remain fixed across
arrival cohorts. Wage/profile means still weight events equally.
{p_end}

{phang}
{cmd:group(}{it:varname}{cmd:)} instead supplies positive integer group codes
up to 2000. Omit the positional score, bins(), binweight() and descending.
Groups may vary within firm and worker over time; the origin group is read at
period -1 and destination at 0 and held fixed throughout that event. This permits
externally prepared coworker-wage groups. It is not arbitrary graph aggregation
for other fegraph views. Missing endpoint groups exclude the event.
{p_end}

{pstd}
CHK Figure V uses person-year quantiles of coworker wages, excluding the mover,
with groups measured at the last old-job and first new-job years. That differs
from equal-firm score bins. The coworker example below illustrates this grouping
logic with artificial log wages; it is not a replication of their administrative
data, wage processing or exact sample. Figure VII motivates supplied AKM scores.
{p_end}

{phang}
{cmd:normalize(}{it:period}{cmd:)} subtracts each event's own outcome at a
period inside window(); for example normalize(-1). The default plots levels.
Normalization occurs before averaging and calculating uncertainty.
{p_end}

{phang}
{cmd:frombins(}{it:numlist}{cmd:)} and {cmd:tobins(}{it:numlist}{cmd:)} select
displayed groups after constructing the full event sample. {cmd:mincell(}{it:#}{cmd:)}
defaults to 1 and hides paths with fewer qualifying events, separately by cohort.
No events are silently sampled. More than 64 pooled paths or 16 origin panels
requires explicit selection or fewer bins.
{p_end}

{phang}
{cmd:overlay} draws all selected paths in one plot, with destination colors
and origin line patterns. Default is one panel per origin group. Patterns repeat
after six origins; the seven-color palette can also repeat with many destinations.
Use frombins()/tobins() for readable larger-bin displays. {cmd:palette()} is shared
by the Stata and HTML renderers; graphopts() customizes the Stata graph only.
Ordinary title(), subtitle() and note() overrides, including empty strings, apply
to the overall figure in both panel and overlay layouts.
{p_end}

{phang}
{cmd:ci} adds pointwise intervals. {cmd:cilevel(}{it:#}{cmd:)} defaults to 95.
Events are equally weighted; repeated moves of a worker form one cluster within
each origin-destination/event-time cell. For N events and G workers, the mean's
variance is G/(G-1) times the sum of squared worker sums of centered outcomes,
divided by N squared; t critical values have G-1 degrees of freedom. Intervals are
missing with one worker. These are not simultaneous bands, do not cluster by firm,
and do not account for uncertainty in estimated scores or group membership.
{p_end}

{phang}
{cmd:profilefile(}{it:file.dta}{cmd:)} saves cohort, origin_bin,
destination_bin, event_time, mean, se, lower, upper, n_events, n_workers and shown.
A missing cohort identifies pooled profiles; dated cohorts are additionally saved
with animation(..., mode(time)). Tables retain paths hidden by display filters.
{cmd:eventfile(}{it:file.dta}{cmd:)} saves retained event-period observations,
including original worker/firm IDs, arrival time, frozen groups, transformed
outcome, cell_events, selected and shown. These files contain individual data;
HTML embeds only displayed aggregate profiles. {cmd:replace} applies to these
Stata outputs and saving(); HTML replacement remains nested in animation().
{p_end}

{pstd}
Other supported common options are sample(), nonemployment(), effectgroup(),
pooled, palette(), name(), saving(), nodraw and graphopts(). The effectgroup()
comparability check is retained. Network layout/edge/selection options and prepared
origin()/destination() flow inputs are not applicable to event studies.
{p_end}

{pstd}
Returned results: r(N_candidates), r(N_excluded_window),
r(N_excluded_outcome), r(N_excluded_group) are sequential event-selection counts;
r(N_events), r(N_workers) describe all retained balanced events;
r(N_shown_events), r(N_paths) describe the pooled display. r(N_input), r(N_bins),
r(bins_requested), r(window_start), r(window_end), r(delta), r(score), r(group),
r(sample), r(palette), r(palette_colors), r(type) and r(version) are also returned.
Prepared groups return bins_requested=0. Counts refer to observed events, not
necessarily distinct people. Errors leave caller data, estimates and RNG unchanged.
{p_end}

{title:Event-study HTML}
{pstd}
{cmd:animation(filename.html, options)} supports the same nested filenames,
replace, themes, speed and annotation controls as the other views. In default
{cmd:mode(aggregate)}, complete pooled profiles remain visible while a cursor
highlights successive event periods. In {cmd:mode(time)}, complete profiles switch
between arrival-period cohorts; only cohorts with displayed qualifying paths
are included. This is calendar cohort comparison, not cumulative pooling or
individual wage trajectories. r(N_frames) reports event periods or cohorts.
{p_end}

{pstd}
The standalone viewer has play/pause, restart, stepping, scrubbing, origin
selection, destination checkboxes, panel/overlay display, hover/tap counts and
pointwise confidence intervals. Axes and colors are fixed across frames and
filters; turning intervals on expands axes to include their bounds. Reduced-motion
preferences disable autoplay. No network connection, Python, Node, D3 or server is
needed by users. Download/save the HTML and open it in a browser if an app preview
is blank. For this view, more than two million event-period rows (including pooled
and cohort copies) requires an explicit smaller sample or window.
{p_end}

{title:Firm-score mover profiles}
{cmd}{...}
        preserve
{* example_start - eventstudy}{...}
        clear
        set obs 3840
        generate long workerid = ceil(_n/8)
        generate year = mod(_n-1,8)+1
        generate origin = 1+floor((workerid-1)/120)
        generate destination = 1+mod(floor((workerid-1)/30),4)
        generate arrival = 4+mod(workerid,3)
        generate firmid = cond(year<arrival,origin,destination+4)
        generate psi = cond(firmid<=4,firmid,firmid-4)/5
        generate double lnwage = 4+psi+.12*origin+.15*sin(workerid) ///
            +.01*year+.015*cos(workerid*year)
        capture mkdir fegraph_examples
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(eventstudy) wage(lnwage) wagescale(log) bins(4) ci ///
            name(fegraph_events, replace) ///
            animation("fegraph_examples/eventstudy.html", replace)
        graph export "fegraph_examples/eventstudy.png", width(1800) replace
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run eventstudy using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Coworker-wage groups and the eight-line display}
{cmd}{...}
        preserve
{* example_start - eventstudy_coworker}{...}
        clear
        set obs 3840
        generate long workerid = ceil(_n/8)
        generate year = mod(_n-1,8)+1
        generate origin = 1+floor((workerid-1)/120)
        generate destination = 1+mod(floor((workerid-1)/30),4)
        generate arrival = 4+mod(workerid,3)
        generate firmid = cond(year<arrival,origin,destination+4)
        generate psi = cond(firmid<=4,firmid,firmid-4)/5
        generate double lnwage = 4+psi+.12*origin+.15*sin(workerid) ///
            +.01*year+.015*cos(workerid*year)
        capture mkdir fegraph_examples
        bysort firmid year: egen double wagesum = total(lnwage)
        bysort firmid year: egen long wagecount = count(lnwage)
        generate double coworker = (wagesum-lnwage)/(wagecount-1) if wagecount>1
        xtile coworker_group = coworker, nq(4)
        fegraph, worker(workerid) firm(firmid) time(year) ///
            type(eventstudy) wage(lnwage) wagescale(log) group(coworker_group) ///
            frombins(1 4) overlay name(fegraph_coworker, replace) ///
            animation("fegraph_examples/eventstudy-coworker.html", replace)
        graph export "fegraph_examples/eventstudy-coworker.png", width(1800) replace
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run eventstudy_coworker using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{title:Normalized profiles by arrival cohort}
{cmd}{...}
        preserve
{* example_start - eventstudy_cohorts}{...}
        clear
        set obs 3840
        generate long workerid = ceil(_n/8)
        generate year = mod(_n-1,8)+1
        generate origin = 1+floor((workerid-1)/120)
        generate destination = 1+mod(floor((workerid-1)/30),4)
        generate arrival = 4+mod(workerid,3)
        generate firmid = cond(year<arrival,origin,destination+4)
        generate psi = cond(firmid<=4,firmid,firmid-4)/5
        generate double lnwage = 4+psi+.12*origin+.15*sin(workerid) ///
            +.01*year+.015*cos(workerid*year)
        capture mkdir fegraph_examples
        fegraph psi, worker(workerid) firm(firmid) time(year) ///
            type(eventstudy) wage(lnwage) wagescale(log) bins(4) ///
            normalize(-1) frombins(1 4) overlay ci ///
            name(fegraph_cohorts, replace) ///
            profilefile("fegraph_examples/eventstudy-cohorts.dta") replace ///
            animation("fegraph_examples/eventstudy-cohorts.html", mode(time) replace)
        graph export "fegraph_examples/eventstudy-cohorts.png", width(1800) replace
{* example_end}{...}
        restore
{txt}{...}
{pstd}
{stata fegraph_run eventstudy_cohorts using fegraph.sthlp:Click to run this example}
(your original data are restored).
{p_end}

{marker reports}{...}
{title:Simulation, estimation, ranking and PDF reports}
{pstd}
These optional examples require Stata 19 and installed {help fesim},
{help fereg}, {help ferank}, {help latexlog}, and {help texpdf}, including the
native plugins supplied with fereg and texpdf. They are not dependencies of the
graph command. No example installs packages or downloads data automatically.
Find the companion packages at
{browse "https://github.com/johannes-schmieder/fesim":fesim},
{browse "https://github.com/johannes-schmieder/fereg":fereg},
{browse "https://github.com/johannes-schmieder/ferank":ferank},
{browse "https://github.com/johannes-schmieder/latexlog":latexlog}, and
{browse "https://github.com/johannes-schmieder/texpdf":texpdf}.
{p_end}

{pstd}
Each report below uses 6,000 workers, 80 firms, 12 annual observations
and a fixed seed. It estimates worker/firm wage effects with fereg, estimates
Bradley--Terry mobility scores with ferank, and draws all five graph types,
including mover profiles by AKM effect, coworker wage and mobility score,
plus a fifty-bin ladder and a ladder using the mobility score on the x-axis
and the estimated wage effect on the y-axis. The complete workflow is installed
as {cmd:fegraph_report.ado}; view it with {cmd:viewsource fegraph_report.ado}.
{p_end}

{pstd}
Reports check that the fixture's effects and scores are identified in one
comparison component before plotting. Figures use illustrative parameters and
observed snapshot transitions, not event hazards. The AKM example has exogenous
mobility; the job-ladder example uses {cmd:dgp(akm) network(ladder)} with an
upward-biased destination rule; {cmd:dgp(bm)} is the separate Burdett--Mortensen
wage-posting equilibrium. Annual BM endpoint moves can be downward following an
unobserved unemployment spell even though accepted on-the-job offers are upward.
{p_end}

{pstd}
{cmd:fegraph_report, outdir(directory) [dgp(all|akm|ladder|bm) replace view]}
creates report.tex, report.pdf and nine figure PDFs per model in that directory.
Each model also has three event-study HTML files and three profile tables.
Its parent directory must exist. Existing report/figure files require replace.
It restores caller data, working directory and estimation results. On errors,
partial output files can remain. r(pdf) and r(tex) give the result paths.
The one-click examples below replace only their dedicated example outputs and
print the output path; each can run independently. Add view to open the PDF. The combined report includes
all three DGPs in one PDF.
{p_end}

{title:AKM report}

{cmd}{...}
        preserve
{* example_start - report_akm}{...}
        capture mkdir "fegraph_examples"
        fegraph_report, dgp(akm) outdir("fegraph_examples/akm") replace
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run report_akm using fegraph.sthlp:Click to generate this report}
(your original data are restored).
{p_end}

{title:Job-ladder report}

{cmd}{...}
        preserve
{* example_start - report_ladder}{...}
        capture mkdir "fegraph_examples"
        fegraph_report, dgp(ladder) outdir("fegraph_examples/ladder") replace
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run report_ladder using fegraph.sthlp:Click to generate this report}
(your original data are restored).
{p_end}

{title:Burdett--Mortensen report}

{cmd}{...}
        preserve
{* example_start - report_bm}{...}
        capture mkdir "fegraph_examples"
        fegraph_report, dgp(bm) outdir("fegraph_examples/bm") replace
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run report_bm using fegraph.sthlp:Click to generate this report}
(your original data are restored).
{p_end}

{title:Combined report: all three DGPs}

{cmd}{...}
        preserve
{* example_start - report_all}{...}
        capture mkdir "fegraph_examples"
        fegraph_report, dgp(all) outdir("fegraph_examples/all") replace
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run report_all using fegraph.sthlp:Click to generate this report}
(your original data are restored).
{p_end}

{title:A compact report workflow to adapt}
{pstd}
This smaller example shows the six commands together explicitly. It writes
one ranking ladder; the reports above include the complete figure collection.
{p_end}

{cmd}{...}
        preserve
{* example_start - pipeline}{...}
        capture mkdir "fegraph_examples"
        fesim, dgp(akm) workers(2000) firms(20) periods(10) ///
            seed(10404) truth(basic) noreport clear
        fereg lnwage if employed, absorb(worker_fe=workerid firm_fe=firmid)
        bysort firmid: egen double psi = mean(firm_fe)
        ferank firmid, worker(workerid) time(time) method(bradleyterry) ///
            score(mobility) componentid(component)
        local report "fegraph_examples/pipeline.tex"
        latexlog `report': open, replace
        latexlog `report': title "Mobility ranking and firm wage effects"
        fegraph mobility if !missing(mobility,psi), worker(workerid) ///
            firm(firmid) time(time) type(ladder) bins(5) level(psi) ///
            nodecolor(psi) effectgroup(component) net nodescale(.7) ///
            name(fegraph_pipeline, replace)
        latexlog `report': addfig, filename(pipeline-ladder.pdf) width(.95)
        latexlog `report': close
        texpdf using "`report'", replace
{* example_end}{...}
        restore
{txt}{...}

{pstd}
{stata fegraph_run pipeline using fegraph.sthlp:Click to run the compact workflow}
(your original data are restored).
{p_end}

{marker output}{...}
{title:Graph and data output}
{phang}
{cmd:name(}{it:name}{cmd:[, replace])}, {cmd:saving(}{it:file.gph}{cmd:)},
{cmd:nodraw} and {cmd:graphopts(}{it:twoway options}{cmd:)} control ordinary Stata
graphs. graphopts are applied last. For example,
{cmd:graphopts(title("") subtitle("") note(""))} suppresses automatic text;
add {cmd:legend(off)} inside graphopts() to hide the color legend too.
Use {cmd:graph export} for PNG, SVG or PDF.
{p_end}

{phang}
{cmd:nodefile(}{it:file.dta}{cmd:)}, {cmd:edgefile(}{it:file.dta}{cmd:)}, and
{cmd:mapfile(}{it:file.dta}{cmd:)} optionally save the audit data. {cmd:replace}
authorizes overwriting those files and saving(). Require explicit .dta/.gph
extensions and distinct paths. Files are written sequentially after rendering;
an I/O error can leave already-written files. Caller data remain unchanged.
{p_end}

{pstd}
Node table: node index, original string id, label, kind (0 firm/bin,
1 worker, 2 outside), size, color, ordering, level, x/y, weak component,
displayed, exposure, effectgroup. Hidden nodes remain. Coordinates of hidden
nodes may be missing. Bins have IDs bin:1, etc. Normal-length IDs use str# for
merge compatibility; very long IDs use strL.
{p_end}

{pstd}
Edge table: numeric origin/destination indices; string origin_id and
destination_id; gross, reverse, signed net, value (requested statistic), color,
width_value, displayed, wage_sum, wage_n and mean_wage_change. All gross pairs
remain, including hidden and within-bin pairs. A net arrow's wage mean is never
computed; saved wage means always describe that gross direction.
{p_end}

{pstd}
Map table: original firm/outside ID to final node index and node_id,
including bin membership. The map excludes worker nodes in bipartite mode.
{p_end}

{marker stored}{...}
{title:Stored results}
{pstd}
{cmd:r(summary)} contains the following scalars, also returned individually:
{p_end}
{p 8 8 2}
N_input, N_workers, N_firms, N_matches, N_eligible, N_gaps, N_unknown,
N_components, N_nodes, N_edges, N_shown_nodes, N_shown_edges, flow_total,
flow_shown, flow_boundary, flow_within, flow_hidden_net, N_missing_color.
{p_end}

{pstd}
N_firms counts known input firms before display selection; N_nodes counts
final nodes including hidden nodes and any bins/workers/outside state. N_edges
counts aggregated gross pairs, including within-bin pairs. N_eligible includes
stayers and explicit outside-state continuations; N_unknown counts adjacent
pairs with an unknown endpoint, within maxgap. Panel-only diagnostics are zero
for prepared input. N_missing_color counts displayed firm/bin nodes lacking color.
{p_end}

{pstd}
flow_total is gross transition/match mass before display filtering.
flow_shown is gross mass represented by displayed edges; for net networks it
includes both underlying directions of each displayed pair. flow_boundary is
gross mass with exactly one displayed endpoint. flow_within is displayed-node
self-flow after aggregation, whether drawn or not. flow_hidden_net is total
gross mass minus summed positive net differences (including within-bin mass).
N_shown_edges counts displayed original gross pairs in net heatmaps, not all
rendered cells. Captions report coverage; there is no silent component selection.
{p_end}

{pstd}
Additional scalars: r(N_bins) is the number of nonempty firm bins (0 without
aggregation); r(bins_requested) is the requested count. Macros: r(type), r(input),
r(style), r(sample), r(score) (supplied score variables), r(outcome), r(version).
When outcome() supplies the ordering from firm means, r(score) is empty. {cmd:fegraph, version}
reports the version. r(palette) and r(edgepalette) identify the resolved palette
names (or custom), with reverse when requested. r(palette_colors) and
r(edgepalette_colors) contain the seven resolved colors in display order.
{cmd:fegraph, selftest} runs a small preserving smoke test
and returns r(passed)=1 on success. It creates a named example graph.
{p_end}

{title:Requirements and qualification}
{pstd}
Generation uses official Stata/Mata. Optional HTML playback uses browser JavaScript. Source targets Stata 16 or newer. Licensed
execution has been checked on macOS Stata/MP 19; Stata 16-18 and Windows/Linux
have not been qualified. fesim, fereg, ferank, latexlog and texpdf are optional companions, not runtime
dependencies. The repository includes contract, scale, integration, rendering
and fresh-install checks. The current package is distributed on GitHub; there is no SSC release.
{p_end}
