version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/tests
clear
set obs 40000
generate origin = ceil(_n/200)
generate destination = mod(_n-1,200)+1
drop if origin==destination
generate origin_score = origin/200
generate destination_score = destination/200
generate moves = 1+mod(17*origin+31*destination,13)
quietly summarize moves, meanonly
local mass = r(sum)
local args "origin(origin) destination(destination) flow(moves)"
foreach bins in 50 100 200 {
    timer clear 1
    timer on 1
    fegraph origin_score destination_score, `args' type(ladder) bins(`bins') ///
        net top(60) nodescale(.35) nolabels nodraw ///
        nodefile(build/tests/manybins-`bins'.dta) replace
    assert r(N_bins)==`bins'
    assert r(N_shown_nodes)==`bins'
    assert r(N_shown_edges)==60
    assert r(flow_total)==`mass'
    timer off 1
    timer list 1
}
// Display scaling must preserve the statistical graph, coordinates and maps.
fegraph origin_score destination_score, `args' type(ladder) bins(50) net top(60) ///
    nodraw nodefile(build/tests/manybins-full.dta) replace
preserve
use build/tests/manybins-full.dta, clear
cf _all using build/tests/manybins-50.dta
restore
foreach scale in 0 -1 5.1 . {
    capture noisily fegraph origin_score destination_score, `args' ///
        type(ladder) bins(50) top(60) nodescale(`scale') nodraw
    assert _rc==198
}
// Canonical type name and invalid graph names.
fegraph origin_score destination_score, `args' type(firmgraph) top(1) iterations(1) nodraw
assert "`r(type)'"=="firmgraph"
capture noisily fegraph origin_score destination_score, `args' type(firm) nodraw
assert _rc==198
fegraph origin_score destination_score, `args' top(1) iterations(1) nodraw
assert "`r(type)'"=="firmgraph"
display "FEGRAPH_MANYBINS_OK"
