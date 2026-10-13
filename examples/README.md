# fegraph examples

## Installed examples

Install fegraph, then run any example with:

```stata
fegraph_run example_name using fegraph.sthlp
```

The runner uses the exact code shown in `help fegraph`. Each example creates its
own data and restores your original data and estimation results. Saved outputs
use `fegraph_examples/` relative to Stata's current directory; examples replace
their own previously generated files. Start in a writable working directory.

| Example name | Result |
| --- | --- |
| `firmgraph` | Directed firm network with explicit unemployment |
| `bipartite` | Worker–firm match graph |
| `ladder` | Wage-effect ladder and worker flows |
| `heatmap` | Flows between score bins |
| `manybins` | Detailed ladder with smaller markers and selected arrows |
| `classic` | Conventional network with thin gray links |
| `classic_color` | Classic network colored by supplied firm effects |
| `palettes` | Customizable node and edge gradients |
| `animation` | Standalone animated firm network |
| `animation_time` | Period-by-period binned ladder with unemployment |
| `eventstudy` | Firm-score quartiles, Stata mover profiles and HTML |
| `eventstudy_coworker` | Leave-worker-out coworker-wage groups and eight-path overlay |
| `eventstudy_cohorts` | Normalized profiles with arrival-cohort HTML playback |

For example:

```stata
fegraph_run classic using fegraph.sthlp
fegraph_run eventstudy_coworker using fegraph.sthlp
```

These examples need only fegraph. All data are synthetic.

## Simulation reports

Five additional examples integrate `fesim → fereg → ferank → fegraph` and use
`latexlog` and `texpdf` to build PDFs. They require Stata 19 and installed
[companions](../INSTALLATION.md#optional-simulation-reports).

| Example name | Output PDF |
| --- | --- |
| `report_akm` | `fegraph_examples/akm/report.pdf` |
| `report_ladder` | `fegraph_examples/ladder/report.pdf` |
| `report_bm` | `fegraph_examples/bm/report.pdf` |
| `report_all` | `fegraph_examples/all/report.pdf` |
| `pipeline` | `fegraph_examples/pipeline.pdf` |

```stata
fegraph_run report_all using fegraph.sthlp
```

Each full DGP report has nine figures: a firm network, worker–firm matches,
ten-bin and fifty-bin ladders, a flow heatmap, a mobility-score ladder, and mover
profiles grouped by AKM effects, coworker wages and mobility ranks. Mover profiles
also produce standalone HTML and aggregate `.dta` tables beside the PDF.

The models use 6,000 workers, 80 firms and 12 annual snapshots. They illustrate
AKM with exogenous mobility, AKM with `network(ladder)`, and the separate
Burdett–Mortensen wage-posting model. Effects and ranks are estimated externally;
these are illustrative simulations, not empirical calibrations or exact
replications of Card–Heining–Kline (2013).

## Galleries from a checkout

Run these scripts from the repository root. They add the local `stata/`
directory to the Ado path and write outputs under ignored `build/` folders.

| Do-file | Output directory |
| --- | --- |
| [command_gallery.do](command_gallery.do) | `build/command-gallery/`: four native views, PNG and PDF |
| [classic_network.do](classic_network.do) | `build/classic/`: gray and colored firm networks |
| [palettes.do](palettes.do) | `build/palettes/`: four-palette comparison |
| [animations.do](animations.do) | `build/animation-gallery/`: four HTML views |
| [eventstudy.do](eventstudy.do) | `build/eventstudy-gallery/fegraph_examples/`: three mover examples |
| [reports.do](reports.do) | `build/reports/all/`: complete DGP report and companions |

```stata
do examples/command_gallery.do
do examples/eventstudy.do
```

[synthetic_panel.do](synthetic_panel.do) and [network_panel.do](network_panel.do)
are input fixtures used by the galleries. They clear the current data when run
directly; use the installed example runner for a preserving demonstration.

The README images are reproduced by `classic_network.do` (`network.png`) and
`command_gallery.do` (`ladder.png`). Generated research data, HTML exports,
reports and test logs are not checked into the repository.

The `common_options` help example uses the same score, outcome and bins across all
five views, and writes `fegraph_examples/common-<view>.html`.
