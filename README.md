# fegraph

`fegraph` draws firm networks, worker–firm match graphs, job ladders and flow
heatmaps in Stata from simulated or real linked employer–employee data.

It accepts firm effects, ranks and other attributes supplied by the user. It
works alongside `fesim` and `ferank`, using the same panel/prepared-flow syntax,
without requiring either package. The runtime uses official Stata and Mata only.

**Version 0.1.0, private development package.** Source targets Stata 16+; licensed
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
* Firms: arrow width shows flows, color shows supplied firm effects.
fegraph firmid, worker(workerid) time(year) ///
    nodecolor(psi_hat) net name(firm_network, replace)

* Workers and firms, with one edge per distinct match.
fegraph firmid, worker(workerid) time(year) type(bipartite) ///
    nodecolor(psi_hat)

* Firm rank and firm wage effect are separate inputs.
fegraph firmid, worker(workerid) time(year) type(ladder) ///
    order(rank_pct) level(psi_hat) nodecolor(psi_hat) bins(10)

* Large-data alternative: destination shares by origin rank bin.
fegraph firmid, worker(workerid) time(year) type(heatmap) ///
    order(psi_hat) bins(10) statistic(share)
```

Replace these example variable names with yours. `ferank` percentiles increase
with attractiveness, so they work directly in `order()`. For raw ranks (1 is
best), add `descending`. Effects/ranks are never estimated by `fegraph`.

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

fegraph origin destination, flow(moves) net ///
    nodecolor(effect_o effect_d) edgecolor(effect) ///
    layout(circle) name(net_flows, replace)
restore
```

`flow()` retains its `ferank` meaning: a nonnegative count/weight variable.
Use `net` for net flows. Endpoint attributes take **two variables, origin then
destination**, matching `ferank`'s output convention. Without `flow()`, each
row contributes one move. Numeric and string IDs are supported.

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

For large data, use rank bins, `component()`, `ego()`/`steps()`, `minflow()` or
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
fegraph firmid, worker(workerid) time(year) nodecolor(psi_hat) ///
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
