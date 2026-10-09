version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/tests

* Independent reference: official xtile on one observation per firm.
program define check_quantiles
    syntax , BINS(integer) [WEIGHTED DESCENDING]
    preserve
    generate double ordering=score
    if "`descending'"!="" replace ordering=-score
    local wt
    local bw firm
    if "`weighted'"!="" {
        local wt "[aw=weight]"
        local bw employment
    }
    if `bins'>1 xtile expected=ordering `wt', nquantiles(`bins')
    else generate expected=1
    egen byte tag=tag(expected)
    quietly count if tag
    local nb=r(N)
    tempfile expected_data
    generate str20 original_id=string(firm)
    save `expected_data'
    fegraph score score, origin(firm) destination(firm) type(ladder) bins(`bins') ///
        nodesize(weight weight) binweight(`bw') `descending' ///
        mapfile(build/tests/quantiles_map.dta) nodefile(build/tests/quantiles_nodes.dta) replace nodraw
    assert r(N_bins)==`nb' & r(bins_requested)==`bins'
    use build/tests/quantiles_map.dta, clear
    merge 1:1 original_id using `expected_data', assert(match) nogen
    assert node_id=="bin:"+string(expected)
    * Verify bin levels separately using official collapse.
    collapse (mean) mean_score=score `wt', by(node_id)
    rename node_id id
    tempfile means
    save `means'
    use build/tests/quantiles_nodes.dta, clear
    merge 1:1 id using `means', assert(match) nogen
    assert abs(level-mean_score)<1e-10
    restore
end

clear
input double score double weight
-20 3
-2 2
0 1
0 1
0 1
1 4
3 2
8 1
10 3
100 2
1000 4
end
generate firm=_n
foreach bins in 1 2 3 4 5 10 {
    check_quantiles, bins(`bins')
    check_quantiles, bins(`bins') weighted
    check_quantiles, bins(`bins') descending
    check_quantiles, bins(`bins') weighted descending
}
* No ties, a dominant weight, and all-equal scores.
replace score=firm^3
replace weight=50 if firm==5
check_quantiles, bins(4)
check_quantiles, bins(4) weighted
replace weight=weight/7
check_quantiles, bins(4) weighted
replace score=1
check_quantiles, bins(4)
check_quantiles, bins(4) weighted
keep in 1
check_quantiles, bins(1)

* Repeating worker records must not change equal-firm quantiles.
clear
set obs 12
generate firm=_n
generate double score=firm^3
xtile expected=score, nquantiles(4)
generate str20 original_id=string(firm)
tempfile reference
save `reference'
expand firm
generate worker=_n
generate time=1
fegraph score, worker(worker) firm(firm) time(time) type(ladder) bins(4) ///
    mapfile(build/tests/panel_quantiles_map.dta) replace nodraw
assert r(N_bins)==4
preserve
use build/tests/panel_quantiles_map.dta, clear
merge 1:1 original_id using `reference', assert(match) nogen
assert node_id=="bin:"+string(expected)
restore

* Binning aggregates moves (including within-bin mass) and excludes U from cuts.
quietly do examples/synthetic_panel.do
fegraph psi, worker(workerid) firm(firmid) time(time) type(ladder) bins(3) ///
    nonemployment(unemployed) nodefile(build/tests/quantile_u_nodes.dta) ///
    mapfile(build/tests/quantile_u_map.dta) edgefile(build/tests/quantile_u_edges.dta) replace nodraw
assert r(N_bins)==3 & r(flow_total)==41 & r(N_nodes)==4
preserve
use build/tests/quantile_u_map.dta, clear
assert node_id=="bin:"+string(ceil(real(original_id)/2)) if original_id!="[outside]"
assert node_id=="[outside]" if original_id=="[outside]"
use build/tests/quantile_u_nodes.dta, clear
assert missing(ordering,level) if kind==2
use build/tests/quantile_u_edges.dta, clear
quietly summarize gross, meanonly
assert r(sum)==41
restore
display "FEGRAPH_QUANTILES_OK"
