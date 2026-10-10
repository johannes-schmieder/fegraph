version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/tests
quietly do examples/network_panel.do
quietly regress psi year
local b=_b[year]
quietly datasignature
local signature `"`r(datasignature)'"'
local rng `"`c(rngstate)'"'
local args "worker(workerid) firm(firmid) time(year) type(firmgraph) edge(shared) nodesize(matches) label(firmname) iterations(250) seed(7)"
fegraph, `args' nodescale(.35) nodefile(build/tests/classic-default.dta) ///
    edgefile(build/tests/classic-default-edges.dta) replace nodraw
assert "`r(style)'"=="default"
fegraph, `args' style(classic) labeltop(12) ///
    nodefile(build/tests/classic-styled.dta) edgefile(build/tests/classic-styled-edges.dta) replace nodraw
assert "`r(style)'"=="classic"
assert r(N_firms)==72 & r(N_shown_edges)==80 & r(flow_total)==289
assert abs(_b[year]-`b')<1e-12
assert `"`c(rngstate)'"'==`"`rng'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
preserve
use build/tests/classic-default.dta, clear
cf _all using build/tests/classic-styled.dta
assert !missing(x,y,label)
restore
preserve
use build/tests/classic-default-edges.dta, clear
cf _all using build/tests/classic-styled-edges.dta
restore
// Row ordering does not change the deterministic force layout.
gsort -workerid -year
fegraph, `args' style(classic) nodefile(build/tests/classic-reordered.dta) replace nodraw
preserve
use build/tests/classic-default.dta, clear
cf _all using build/tests/classic-reordered.dta
restore
// Label selection is a quota over displayed firms only; outside labels survive.
mata:
g=fegraph__new()
g.N=J(6,11,0); g.N[,2]=(5\10\10\2\1\50); g.N[6,1]=2
g.labels=("one"\"two"\"three"\"four"\"five"\"Unemployment")
ni=(1::6)
assert(fegraph__plotlabels(g,ni,2)==(""\"two"\"three"\""\""\"Unemployment"))
assert(fegraph__plotlabels(g,ni,0)==(""\""\""\""\""\"Unemployment"))
assert(fegraph__plotlabels(g,ni,20)==g.labels)
assert(fegraph__plotlabels(g,ni,-1)==g.labels)
assert(fegraph__plotlabels(g,6,1)=="Unemployment")
assert(g.labels[1]=="one")
// A nearby marker on the right makes a left label preferable.
xy=(0,0\.04,0\1,0)
p=fegraph__labelpositions(xy, ("Hub"\""\""), (4\1\1), .35)
assert(xy==(0,0\.04,0\1,0))
assert(p[1]==9)
end
foreach style in bad CLASSICAL {
    capture noisily fegraph, `args' style(`style') nodraw
    assert _rc==198
}
capture noisily fegraph, `args' labeltop(-2) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) time(year) type(ladder) style(classic) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) time(year) type(heatmap) labeltop(2) nodraw
assert _rc==198
// A single node, an edgeless graph and zero labels must all render.
clear
input origin destination
1 1
end
fegraph, origin(origin) destination(destination) style(classic) labeltop(0) nodraw
assert r(N_shown_nodes)==1 & r(N_shown_edges)==0
// Classic directed moves retain counts, outside states, colors and arrowheads.
quietly do examples/synthetic_panel.do
fegraph psi, worker(workerid) firm(firmid) time(time) style(classic) net ///
    nonemployment(unemployed) outsidelabel(Unemployment) edgecolor(effect) ///
    labeltop(4) name(classic_directed, replace)
assert r(flow_total)==41
graph export build/tests/classic-directed.png, width(1600) replace
do examples/classic_network.do
display "FEGRAPH_CLASSIC_OK"
