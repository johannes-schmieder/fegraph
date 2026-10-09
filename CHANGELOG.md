# Changelog

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
