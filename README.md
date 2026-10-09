# fegraph

`fegraph` draws firm networks, worker–firm match graphs, job ladders and flow
heatmaps in Stata from simulated or real linked employer–employee data.

It accepts firm effects, ranks and other attributes supplied by the user. It
works alongside `fesim` and `ferank`, with explicit `worker()`/`firm()` IDs
as in `fevc` and `feset`, without requiring any of these packages. The runtime uses official Stata and Mata only.

**Version 0.2.0, private development package.** Source targets Stata 16+; licensed
execution is qualified on macOS Stata/MP 19. Other versions/platforms remain
unqualified. There is no SSC release or selected redistribution license yet.

## Install

The repository is private. Clone it using your authorized GitHub account, then
install from the local checkout in Stata:

```stata
net install fegraph, from("/path/to/fegraph") replace
fegraph, selftest
help fegraph
```

Restart Stata before updating an already-loaded version so cached ado/Mata code
is replaced. For development from the repository root, `adopath ++ stata` works.

## Panel syntax

```stata
* The optional first variable is the firm score, not the firm ID.
fegraph psi_hat, worker(workerid) firm(firmid) time(year) ///
    type(firm) net name(firm_network, replace)

* A match graph needs no score or time variable.
fegraph, worker(workerid) firm(firmid) type(bipartite)

* Rank by revealed preference, plot the supplied wage effect vertically.
fegraph rank_pct, worker(workerid) firm(firmid) time(year) type(ladder) ///
    level(psi_hat) nodecolor(psi_hat) bins(10)

* Ten score-quantile groups and destination shares.
fegraph psi_hat, worker(workerid) firm(firmid) time(year) ///
    type(heatmap) bins(10) statistic(share)
```

The score supplies ordering and default firm color/ladder height. `level()` and
`nodecolor()` can specify different attributes. Heatmap color always shows flows.
`order()` is an equivalent explicit alternative to the positional score;
conflicting specifications are errors. Scores must be numeric and constant
within firm among observed values. They are never estimated or implicitly
averaged over worker observations. `ferank` scores and increasing percentiles
work directly; add `descending` for raw ranks where 1 is best.

`time()` is required for directed panel flows; it may be omitted for match/shared
views. Job ladders automatically route arrows on both sides of the firm-to-firm
chord, with separate lanes for conflicting links and reciprocal flows.

## Prepared-flow syntax

```stata
preserve
clear
input origin destination moves effect_o effect_d
1 2 100 -.2 .1
2 1  98  .1 -.2
2 3  25  .1 .3
3 2   5  .3 .1
end

fegraph effect_o effect_d, origin(origin) destination(destination) ///
    flow(moves) net edgecolor(effect) layout(circle)
restore
```

The optional positional scores and supplied endpoint attributes take two
variables, origin then destination. The ID options identify the endpoints.
`flow()` retains its `ferank` meaning: a nonnegative count/weight variable;
without it, each row contributes one move. `net` selects net flows. Numeric
and string IDs are supported. Panel and prepared-flow ID options cannot mix.

## Migrating from 0.1

```stata
* Old: fegraph firmid, worker(workerid) time(year) order(psi_hat) type(ladder)
fegraph psi_hat, worker(workerid) firm(firmid) time(year) type(ladder)

* Old: fegraph origin destination, flow(moves)
fegraph, origin(origin) destination(destination) flow(moves)
```

Version 0.2 rejects old positional-ID calls with a migration message. Restart
Stata and reinstall when upgrading. Positional variables now supply scores.

## Choose the economic meaning

- **Gross moves** (default): count direct observed transitions; retain each direction.
- **Net moves** (`net`): difference between gross directions; keep both gross
  counts in the exported edge table. 100 A→B and 98 B→A become a net arrow of 2.
- **Shared workers** (`edge(shared)`): undirected counts of distinct workers
  observed at both firms, whether or not they moved directly between them.
- **Bipartite matches**: one edge per worker–firm match; repeated observations
  do not create duplicate links.

With `wage(lnwage) wagescale(log) edgecolor(wage)`, arrow color represents mean
observed mover log wage changes. `wagescale(level)` instead computes percentage
changes and requires positive wages. `edgesize(wage|effect)` can encode absolute
changes; arrow direction still follows worker movement. Observed wage changes,
firm-effect differences and causal effects are distinct quantities.

`nonemployment(indicator)` explicitly supplies a panel outside state. Use
`outsidelabel(Unemployment)` only when the observations support that label.
Missing firms otherwise remain unknown and break chains. Outside states occupy
a schematic band on ladders; they have no measured firm effect or rank.

## Sample, aggregation and comparisons

The default `maxgap(1)` and selected-sample adjacency follow `ferank`. Use
`sample(original)` to prevent `if`/`in` exclusions from joining records across
an excluded observation. Duplicate worker-time keys are errors; choose a main
job upstream when workers hold multiple simultaneous jobs.

`bins(10)` forms score deciles, using **one observation per selected firm** by
default. `bins(4)` forms quartiles; `bins(1)` pools all firms; `bins(0)` retains
individual firms. This works for ladders and heatmaps. The cutpoint convention
matches Stata's default [`xtile`](https://www.stata.com/manuals/dpctile.pdf).
Equal scores stay together and boundary ties enter the lower bin. Empty bins
are omitted (labels retain their quantile numbers); `r(N_bins)` reports the
actual count, which may be smaller than requested. Unemployment stays separate.

`binweight(employment)` explicitly requests weighted quantiles and weighted bin
means using node sizes (mean employment by default for panels). Firm scores,
levels and colors are averaged within bins; sizes/exposures and gross moves
are summed. Bin boundaries are computed after firm selection and before edge
filtering. There is no automatic binning by equal-width score intervals.

For large data, use quantile bins, `component()`, `ego()`/`steps()`, `minflow()` or
`top()`. The default keeps all weak components. Graphs report displayed gross
flow coverage, boundary flow and within-bin movement. Probabilities and mover
shares retain full denominators after display filtering. Bins aggregate gross
flows before netting or thresholding; tied ordering values remain together.

`effectgroup()` checks that externally supplied effects/ranks share a comparison
group. It is distinct from `component()`, which selects **weak graph components**.
Comparing independently normalized estimation components requires deliberate
judgment; `pooled` explicitly overrides the supplied group check.

Seeded force layouts do not change the caller's RNG. Save and reuse coordinates
with `nodefile()` and `coordinates()`. Fix `colorlimits()`, `edgelimits()`,
`sizemax()` and `widthmax()` for comparisons. Marker areas and line widths use
four disclosed global classes; colors use seven classes or explicit categorical
codes. Choose common populations/weights when deriving bins across figures.

## Output and customization

```stata
fegraph psi_hat, worker(workerid) firm(firmid) time(year) ///
    nodefile("nodes.dta") edgefile("edges.dta") mapfile("mapping.dta") ///
    saving("network.gph") replace ///
    graphopts(title("Worker mobility") legend(position(6)))

graph export "network.pdf", replace
graph export "network.png", width(2000) replace
```

The command preserves caller data, observation order, active frame, estimation
results and RNG state on success and failure. It returns diagnostics in `r()`.
Saved node/edge tables retain hidden observations and original IDs so a figure
can be checked against its inputs. Output files are written sequentially after
rendering; see help for their schemas and overwrite rules.

## Examples and validation

- `fegraph_example, type(firm|bipartite|ladder|heatmap)` runs a preserving example.
- `do examples/command_gallery.do` creates four figures from the synthetic fixture.
- [`help fegraph`](stata/fegraph.sthlp) documents all options, statistics and outputs.
- [Validation](docs/validation.md) describes counts, preservation checks, scale,
  real `fesim`/`ferank` integration and installation evidence.
- [Development](CONTRIBUTING.md) explains the source and test entry points.
- [Original design discussion](docs/design.md) records motivation and optional
  future ideas; its initial syntax sketches are superseded by the command help.

The historical `examples/concept_gallery.do` remains as the initial rendering
prototype. New work should use the implemented command and command gallery.
