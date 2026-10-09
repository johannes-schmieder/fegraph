version 16.0
set more off
mata: mata set matalnum on
adopath ++ stata
capture mkdir build
capture mkdir build/tests
do examples/synthetic_panel.do
generate double firm = firmid
replace firm=. if unemployed
fegraph, firm(firm) worker(workerid) time(time) type(firmgraph) net nodecolor(psi) ///
    nodefile(build/tests/nodes.dta) edgefile(build/tests/edges.dta) replace name(smoke, replace)
return list
assert r(flow_total)==37
assert r(N_shown_edges)==8
graph export build/tests/firm.png, width(1600) replace
fegraph psi, firm(firm) worker(workerid) time(time) type(ladder) net ///
    nodecolor(psi) nonemployment(unemployed) outsidelabel(Unemployment) bins(3) ///
    nodefile(build/tests/ladder_nodes.dta) edgefile(build/tests/ladder_edges.dta) ///
    mapfile(build/tests/map.dta) replace name(ladder, replace)
graph export build/tests/ladder.png, width(1600) replace
assert r(flow_total)==41
fegraph psi if inlist(workerid,1,3,5,7,8,9,12,13), firm(firm) worker(workerid) time(time) ///
    type(bipartite) nodecolor(psi) name(bip, replace)
assert r(N_matches)==23
graph export build/tests/bipartite.png, width(1600) replace
fegraph psi, firm(firm) worker(workerid) time(time) type(heatmap) bins(3) ///
    nonemployment(unemployed) outsidelabel(Unemployment) name(heat, replace)
graph export build/tests/heatmap.png, width(1600) replace
display "FEGRAPH_SMOKE_OK"
