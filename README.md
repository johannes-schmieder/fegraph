# fegraph

Stata graphs for linked worker–firm data: mobility networks, worker–firm matches,
and job ladders, using simulated or real datasets.

**Status: design and graphics prototype.** There is no installable `fegraph`
command yet. The interface below is a proposal, not executable syntax.

## Three views of the same data

| View | Nodes | Connections | Main question |
| --- | --- | --- | --- |
| Firm network | Firms | Shared workers or directed moves | Which firms are connected, and where do workers move? |
| Worker–firm graph | Large firm nodes, small worker nodes | Observed worker–firm matches | Which workers connect which employers? |
| Job ladder | Firms or rank bins, plus an explicit outside state | Flows along a ranked firm distribution | How do workers move up, down, into, and out of employment? |

Firm effects, rankings, size, industry and other attributes are supplied by the
user. `fegraph` will not estimate AKM effects or firm rankings. Data from
[`fesim`](https://github.com/johannes-schmieder/fesim) and variables produced by
[`ferank`](https://github.com/johannes-schmieder/ferank) should work through the
same explicit interface as other datasets.

## Proposed use

```stata
* PROPOSED syntax: the command is not implemented.
fegraph firm, worker(workerid) firm(firmid) time(time) ///
    edge(moves) flow(net) nodecolor(psi_hat) nodesize(employment)

fegraph bipartite, worker(workerid) firm(firmid) ///
    nodecolor(psi_hat)

fegraph ladder, worker(workerid) firm(firmid) time(time) ///
    order(psi_hat) level(psi_hat) bins(10) flow(gross)
```

See [the design discussion](docs/design.md) for definitions, proposed syntax,
nonemployment, aggregation, implementation stages and unresolved decisions.

## Run the graphics prototype

From this repository's root in Stata:

```stata
do examples/concept_gallery.do
```

The script creates a small, entirely synthetic panel and renders the three
views using official Stata graphics. It restores the user's data. It writes
PNG, PDF and `.gph` files to ignored `build/gallery/`. No external package,
Python, graph library, `fesim`, or `ferank` is needed to run the gallery.

The gallery uses fixed illustrative coordinates and simple styling. It proves
the basic rendering path; it does not implement a layout engine or the proposed
command. Source is written with `version 16.0`; the initial execution check was
on macOS Stata/MP 19. Earlier versions and other platforms are unqualified.

## Implementation direction

Use Stata for validation, data preparation and graph construction, and Mata for
layouts. Return ordinary editable Stata graphs plus optional node/edge tables.
For large real datasets, offer explicit aggregation and subgraph selection,
with counts and flow coverage reported for the displayed sample.

There is no package release or selected distribution license yet.
