# Consistent graph options

The common unit is a supplied **firm score**, with IDs in `worker()` and `firm()`.
Every view accepts `bins(k)`, `binweight(firm|employment)`, `descending`,
`outcome()`, `palette()`, `sample()`, `nonemployment()`, `effectgroup()`/`pooled`,
`animation()`, `saving()`, `name()`, `nodraw` and `graphopts()`.

| Option or quantity | Firmgraph | Bipartite | Ladder | Heatmap | Eventstudy |
| --- | --- | --- | --- | --- | --- |
| Score / `order()` | Bins, default color; circle order | Bins, default color; firm-row order | Percentile x-axis | Axis order and bins | Endpoint groups |
| `bins(k)` | Firm-bin nodes | Firm-bin nodes, individual workers | Firm-bin nodes | Firm-bin cells | Endpoint score groups |
| Default bins | 0 | 0 | 0 | 0 | 4 |
| `outcome(y)` | Firm mean color/level | Firm mean color | Firm mean height/color | Firm means can sort/bin axes | Individual outcome profiles |
| `nodecolor()` | Yes | Firm nodes | Yes | Cells encode counts/rates | Lines encode destination group |
| `level()` | Effect edge differences | No height axis | Height, effect edge differences | No height axis | Outcome sets y-axis |
| `nodesize()` | Yes | Firm nodes | Yes | No markers | No markers |
| `workercolor()` | — | Yes | — | — | — |
| `gross` / `net` | Directed moves | — | Directed moves | Directed moves | — |
| `edge(shared)` | Shared workers | Matches are intrinsic | Shared workers | Symmetric shared-worker cells | — |
| `statistic(count/share/probability)` | Directed moves | Counts only | Directed moves | Directed moves | Outcome means |
| `edgecolor()` / `edgesize()` | Directed links | Count links only | Directed links | Cells encode statistic | Destination-group lines |
| `component()` / `ego()` | Yes | Yes | Yes | Yes | Use explicit sample/group filters |
| `top()` / `minflow()` | Yes | Yes | Yes | Yes | Use `frombins()`, `tobins()`, `mincell()` |
| Outside state | Separate node | Excluded from matches | Schematic bottom band | Separate row/column | Breaks complete windows |
| Prepared origin/destination input | Yes | — | Yes | Yes | — |

A dash means the quantity has no interpretation for that view. Flow controls
are rejected for incidence graphs and profiles. Heatmap `nodecolor()` is rejected;
cell color always carries the plotted statistic. The node/edge table options,
free-layout options and scaling controls apply to network views; event studies
have profile/event tables and outcome-specific controls. Some common internal
attributes can be exported without appearing on a given view (e.g. `level()` in
a bipartite node table); the table above describes their visual role.

## Scores, outcomes and colors

```stata
* Rank by an external AKM effect, color by firm mean log wages.
fegraph psi, worker(i) firm(j) time(t) type(firmgraph) bins(10) outcome(lnwage)

* Same firms and bins, viewed as job matches.
fegraph psi, worker(i) firm(j) time(t) type(bipartite) bins(10) outcome(lnwage)

* No supplied score: explicitly rank by pooled firm mean log wages.
fegraph, worker(i) firm(j) time(t) type(ladder) bins(10) outcome(lnwage)

* Rank by psi, plot mean log wages around moves.
fegraph psi, worker(i) firm(j) time(t) type(eventstudy) bins(4) outcome(lnwage)
```

Supplied scores, `nodecolor()` and `level()` are firm-constant attributes. Only
explicit `outcome()` computes firm means from selected nonmissing employed rows.
Means set color/height, and ordering if no score is supplied. Explicit `nodecolor()`
and `level()` take precedence. Means are fixed over the pooled selected history
in HTML time playback. Within bins, firm means use the chosen bin weights;
equal-firm averaging differs from pooling all worker observations in the bin.
`wage()`/`wagescale()` remains the wage-specific input for mover wage-change links
or wage profiles; general `outcome()` profiles allow zero and negative values.
They are distinct inputs, not alternative spellings for the same option.

`order()` sorts heatmap axes, ladder percentiles, circle layouts and the bipartite
firm row. Force positions reflect connectivity. `descending` reverses score order.
A palette reversal changes colors only.

## Aggregation contracts

- All five views use the same Stata-percentile quantile engine. Ties stay together.
  Use the same selected firm population, score and weights for identical bins.
  Eventstudy forms groups before balanced-window exclusions; component/ego
  selection in network views can intentionally change the grouping population.
- `bins(0)` retains individual firms; `bins(1)` pools all firms. Bipartite bins
  never merge workers, so large worker samples still need deliberate selection.
- Directed moves sum original firm-to-firm counts, then compute net differences,
  rates and thresholds. Within-bin moves remain in exports and heatmap diagonals;
  network views omit self-arrows. Missing employers do not create artificial moves.
- Bipartite counts each worker-bin match once. Shared graphs count each worker
  once per unordered bin pair, including within-bin connections when the worker
  held jobs at two member firms. Shared heatmaps mirror cells visually; exports
  and coverage count each unordered pair once.
- Panel `binweight(employment)` uses mean observed employment and requires time,
  regardless of node sizing. Prepared flows need employment variables supplied
  in `nodesize()`. Equal-firm weights remain the default.
- `nodesize(matches)` counts distinct workers in a bin; `nodesize(equal)` gives
  each bin equal size; employment/supplied sizes and exposures sum. Flow size
  uses incident aggregated links. Worker markers remain small.
- Time playback maps all dated contributions to fixed pooled bins. Bipartite
  links show current matches; shared links accumulate from the first date each
  worker was observed in both bins. `nodesize(matches)` in a time frame shows
  currently observed workers, not cumulative matched workers.

No compatibility layer is retained while the command is a prototype. The network
name is `type(firmgraph)`; identifiers always belong in explicit ID options.
Use `fegraph_run common_options using fegraph.sthlp` for a self-contained five-view
example with matching HTML artifacts.
