# Changelog

## 0.8.0 — 2026-10-13

- Extend score-quantile bins to firmgraph and bipartite; eventstudy also accepts
  bins(0). Shared-worker bin pairs and worker-bin matches count each worker once.
- Add outcome() across all views: explicit pooled firm means for network defaults
  and sorting, individual outcome profiles for eventstudy. Supplied scores and
  explicit level/color remain independent. General outcomes can be zero/negative.
- Add explicit gross alongside net for directed flow views; reject ambiguous or
  undefined combinations. Remove obsolete graph spellings and migration paths.
- Sort bipartite/circle layouts by score; separate panel employment bin weights
  from node sizing. Make equal/match/flow bin sizes follow their stated definitions.
- Document the cross-view option matrix and add a runnable five-view example.
- Add independent aggregation, outcome, state-preservation and HTML frame checks.

## Help formatting — 2026-10-13

- Begin the help with a one-paragraph command summary; keep installation
  instructions in the README and installation guide.
- Explicitly end SMCL paragraphs so syntax, option descriptions and later
  sections render with proper breaks instead of displaying formatting tags.
- Check Stata-rendered help at two text widths, including late-file headings
  and paragraph boundaries. Runnable example code is unchanged.

## Public repository preparation — 2026-10-13

- Add direct GitHub installation instructions, a concise README with synthetic
  graph previews, a detailed usage guide and a complete example index.
- Remove the superseded design sketch and initial rendering prototype from the
  current tree; their history remains in Git.
- Keep the 0.7.0 command interface and statistical behavior unchanged.

## 0.7.0 — 2026-10-10 (private development)

- Add `type(eventstudy)` with score-first syntax, wage outcomes, fixed endpoint
  groups, balanced event windows, exact time spacing and nonemployment breaks.
- Preserve equal-firm score quantiles and add explicit employment weighting or
  prepared `group()` labels for coworker-wage and time-varying classifications.
- Add origin panels, overlaid selected paths, within-event normalization,
  minimum cell counts, palettes and optional pointwise worker-cluster intervals.
- Export retained event-period data and aggregate profiles with selection counts.
- Add standalone HTML event-time highlighting and arrival-cohort playback,
  origin/destination filters, panel/overlay controls, hover details and fixed scales.
- Add three runnable help examples and three profile figures/HTML artifacts per
  AKM, ladder and BM report, with supplied AKM effects, coworker groups and ranks.
- Add known-path and repeated-worker contracts, independent JSON/variance checks,
  annotation suppression, package checks and actual browser inspection.

## 0.6.1 — 2026-10-10 (private development)

- Move HTML playback controls above the graph so they are visible on opening.
- Explain periods with no observed moves and selected graphs with no nonzero
  values, including the first period's missing predecessor. Keep every period
  and its statistical values unchanged.
- Show a visible diagnostic if startup fails, canvas is unavailable, or the
  viewer template is opened without exported data; explain disabled JavaScript.
- Keep ladder percentile endpoints and the unemployment label inside the plot
  without overlapping the x-axis.
- Qualify the generated gallery in a real browser through a local HTTP preview,
  including playback, stepping, scrubbing, themes and all four rendered views.
  Direct file opening is distinct from this browser check.

## 0.6.0 — 2026-10-09 (private development)

- Add `animation(filename.html, options)` with embedded offline HTML/Canvas output
  for all four views, aggregate animation and actual-period playback.
- Keep statistics in Stata/Mata; preserve pooled selection/layout/bins and retain
  dated transitions, matches and eligible exposure for frame calculations.
- Add nested file replacement, themes, playback speed, annotation controls,
  frame navigation, hover details and network zoom/pan.
- Add runnable help/gallery examples, JSON/statistical contracts and viewer unit
  checks. Browser visual qualification remains outstanding (file-URL tool restriction).

## 0.5.0 — 2026-10-09 (private development)

- Expose palette() for nodes and heatmaps and edgepalette() for effect/wage arrows,
  with six named palettes, independent reversal and seven-color custom lists.
- Validate named colors and RGB triplets, preserve previous defaults and fixed
  color classes, and return the resolved palettes for reproducibility.
- Add a one-click palette help example, a four-panel gallery, render-level color
  checks, and graph/data/state invariance checks.

## 0.4.0 — 2026-10-09 (private development)

- Add `style(classic)` for familiar force-directed firm networks: thin gray
  links, small markers, optional supplied colors and directed arrows.
- Add `labeltop()` with a size-based label quota; classic labels use an eight-way
  placement heuristic and draw above nodes. Preserve complete exported labels.
- Improve force layout with deterministic disk initialization and mild centering,
  limiting isolate drift and the resulting compression of connected firms. Saved coordinates remain reusable.
- Add two self-contained help examples, a reproducible network gallery, display
  invariance checks and an actual fesim block-network integration figure.

## 0.3.0 — 2026-10-09 (private development)

- Name the network view `type(firmgraph)`.
- Add `nodescale()` with consistent arrow clearance for larger ladders.
- Add navigable ferank-style help, ten independently runnable example blocks,
  a preserving example runner, and optional six-command DGP PDF reports.
- Check 50/100/200-bin ladders and complete AKM, job-ladder and Burdett–Mortensen
  simulation/estimation/ranking/graph/report workflows.

## 0.2.0 — 2026-10-09 (private development)

- Move panel IDs into `worker()`/`firm()` and prepared-flow IDs into
  `origin()`/`destination()`. Optional positional variables now supply firm scores.
  Require explicit panel or endpoint ID options.
- Use the score for ordering and default firm color/level, retaining explicit
  overrides and `order()` as an alternative. Allow score-free network calls.
- Define `bins(#)` using score-quantile cutpoints matching default Stata `xtile`
  on one row per firm. Keep ties together and unemployment outside the bins;
  retain explicit employment weighting and original nonempty quantile labels.
- Return requested/actual bin counts and resolved score variables. Add independent
  native-`xtile` comparisons, syntax contracts, examples and help.

## 0.1.0 — 2026-10-09 (private development)

- Spread job-ladder links across deterministic above/below lanes, separating
  overlapping rank intervals and reciprocal arrows. Clip along each curve for
  visible arrowheads; retain supplied coordinates and flow statistics.
- Implement firm networks, worker-firm match graphs, job ladders and flow heatmaps.
- Match ferank's positional panel/edge interface, flow weights, endpoint attributes,
  maxgap default and selected-sample adjacency; add optional original adjacency.
- Support gross/net/shared-worker edges, observed wage changes, explicit outside
  states, full-denominator rates, rank bins with ties and external comparison groups.
- Add weak component and ego selection, explicit display limits, deterministic
  layouts, coordinate reuse, fixed comparison scales and categorical node colors.
- Save ordinary Stata graphs and auditable node/edge/mapping tables; preserve caller
  data, estimates, frame and RNG. Add help, examples, local installer and tests.
