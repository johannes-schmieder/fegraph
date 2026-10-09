version 16.0
set more off
args fesim_path ferank_path
adopath ++ stata
if `"`fesim_path'"'!="" adopath ++ `"`fesim_path'"'
if `"`ferank_path'"'!="" adopath ++ `"`ferank_path'/stata"'
capture mkdir build
capture mkdir build/tests
fegraph, selftest
assert r(passed)==1
fesim, dgp(akm) preset(simple) workers(500) firms(20) periods(8) ///
    seed(12345) truth(basic) clear
local rng `"`c(rngstate)'"'
fegraph, firm(firmid) worker(workerid) time(time) nodecolor(psi_true) net ///
    nodefile(build/tests/fesim_nodes.dta) replace name(fesim_network, replace)
assert r(N_firms)==20
graph export build/tests/fesim_network.png, width(1800) replace
assert `"`c(rngstate)'"'==`"`rng'"'
ferank firmid, worker(workerid) time(time) method(bradleyterry) ///
    score(rank_score) percentile(rank_pct) componentid(rank_component)
local previous_eN=e(N_firms)
fegraph rank_pct if !missing(rank_pct), firm(firmid) worker(workerid) time(time) ///
    type(ladder) level(psi_true) nodecolor(psi_true) bins(5) ///
    effectgroup(rank_component) name(ranked_ladder, replace)
assert e(N_firms)==`previous_eN'
graph export build/tests/ranked_ladder.png, width(1800) replace
fegraph psi_true, firm(firmid) worker(workerid) time(time) type(heatmap) ///
    bins(10) statistic(share) name(fesim_heatmap, replace)
graph export build/tests/fesim_heatmap.png, width(1800) replace
display "FEGRAPH_INTEGRATION_OK"
