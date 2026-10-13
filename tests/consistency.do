version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/consistency
clear
input worker t firm
1 1 1
1 2 2
1 3 3
1 4 4
1 5 1
2 1 4
2 2 3
2 3 2
2 4 1
2 5 4
3 1 1
3 2 1
3 3 3
3 4 3
3 5 3
end
gen double score=firm
gen double y=10*firm+t
gen double rev=-score
gen double size=1
bysort firm: egen double ymean=mean(y)
local ids worker(worker) firm(firm) time(t)
quietly datasignature
local signature `"`r(datasignature)'"'
local rng `"`c(rngstate)'"'

* Identical bin maps and gross flow mass across the three flow views.
foreach view in firmgraph ladder heatmap {
    fegraph score, `ids' type(`view') bins(2) gross nodraw ///
        mapfile(build/consistency/map-`view'.dta) ///
        edgefile(build/consistency/edges-`view'.dta) replace ///
        animation("build/consistency/`view'.html", mode(time) replace)
    assert r(N_bins)==2 & r(flow_total)==9 & r(flow_within)==4
    preserve
    use build/consistency/map-`view'.dta, clear
    cf _all using build/consistency/map-firmgraph.dta
    restore
    fegraph score, `ids' type(`view') bins(2) net nodraw
    assert r(flow_total)==9 & r(flow_hidden_net)==8
}

* Firms merge, workers do not; each worker-bin connection occurs once.
fegraph score, `ids' type(bipartite) bins(2) nodesize(matches) nodraw ///
    mapfile(build/consistency/map-bipartite.dta) ///
    nodefile(build/consistency/bipartite-nodes.dta) ///
    edgefile(build/consistency/bipartite-edges.dta) replace ///
    animation("build/consistency/bipartite.html", mode(time) replace)
assert r(N_bins)==2 & r(N_nodes)==5 & r(N_matches)==10
assert r(flow_total)==6 & r(N_shown_edges)==6
preserve
use build/consistency/map-bipartite.dta, clear
cf _all using build/consistency/map-firmgraph.dta
use build/consistency/bipartite-nodes.dta, clear
assert size==3 if kind==0
assert size==.3 if kind==1
use build/consistency/bipartite-edges.dta, clear
assert gross==1
restore
fegraph score, `ids' type(bipartite) bins(1) nodesize(equal) nodraw
assert r(N_nodes)==4 & r(flow_total)==3

* Distinct workers between bin pairs, not sums of original firm-pair counts.
fegraph score, `ids' edge(shared) bins(2) nodraw ///
    edgefile(build/consistency/shared-edges.dta) replace ///
    animation("build/consistency/shared.html", mode(time) replace)
assert r(flow_total)==7 & r(flow_within)==4 & r(flow_shown)==3
preserve
use build/consistency/shared-edges.dta, clear
assert gross==3 if origin!=destination
assert gross==2 if origin==destination
restore
fegraph score, `ids' type(heatmap) edge(shared) bins(2) ///
    name(shared_heat, replace) ///
    animation("build/consistency/shared-heatmap.html", mode(time) replace)
assert r(flow_total)==7 & r(flow_shown)==7
graph export build/consistency/shared-heatmap.svg, replace
* Reversed bin numbering and hidden firm endpoints retain symmetric counts.
fegraph score, `ids' edge(shared) bins(2) descending nodraw ///
    animation("build/consistency/shared-descending.html", mode(time) replace)
assert r(flow_shown)==3
fegraph score, `ids' type(bipartite) bins(2) ego(1) steps(1) nodraw ///
    animation("build/consistency/bipartite-ego.html", mode(time) replace)
assert r(flow_boundary)>0

* Employment-weighted grouping is independent of the chosen node size.
foreach view in firmgraph bipartite ladder heatmap {
    foreach sz in employment matches equal flow size {
        fegraph score, `ids' type(`view') bins(2) binweight(employment) ///
            nodesize(`sz') mapfile(build/consistency/weighted-`view'-`sz'.dta) replace nodraw
        preserve
        use build/consistency/weighted-`view'-`sz'.dta, clear
        cf _all using build/consistency/weighted-firmgraph-employment.dta
        restore
    }
}

* Explicit means agree with a separately computed supplied firm attribute.
foreach view in firmgraph bipartite ladder heatmap {
    fegraph, `ids' type(`view') outcome(y) bins(2) nodraw ///
        nodefile(build/consistency/outcome-`view'.dta) replace
    assert "`r(outcome)'"=="y" & "`r(score)'"==""
    fegraph ymean, `ids' type(`view') bins(2) nodraw ///
        nodefile(build/consistency/supplied-`view'.dta) replace
    preserve
    use build/consistency/outcome-`view'.dta, clear
    cf _all using build/consistency/supplied-`view'.dta
    restore
}
fegraph score, `ids' type(ladder) outcome(y) nodecolor(rev) nodraw ///
    nodefile(build/consistency/override.dta) replace
preserve
keep firm ymean
bysort firm: keep if _n==1
gen str10 id=string(firm)
tempfile means
save `means'
use build/consistency/override.dta, clear
merge 1:1 id using `means', assert(match) nogen
assert ordering==firm & level==ymean & color==-firm
restore
* Sorting by score really orders the bipartite firm row, with both directions.
fegraph rev, `ids' type(bipartite) nodefile(build/consistency/sorted.dta) replace nodraw
preserve
use build/consistency/sorted.dta, clear
keep if kind==0
sort x
assert real(id)==5-_n
restore
fegraph rev, `ids' type(bipartite) descending nodefile(build/consistency/sorted.dta) replace nodraw
preserve
use build/consistency/sorted.dta, clear
keep if kind==0
sort x
assert real(id)==_n
restore

* Reject undefined combinations and removed graph names.
foreach opt in "net gross" "type(firm)" "type(bipartite) net" "type(bipartite) gross" "type(bipartite) edge(shared)" "edge(shared) net" "type(heatmap) nodecolor(score)" {
    capture noisily fegraph score, `ids' `opt' nodraw
    assert _rc==198
}
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
assert `"`c(rngstate)'"'==`"`rng'"'

* Outcome means respect qualifiers and explicit nonemployment under both sampling modes.
gen byte outside=worker==3 & t==2
replace y=9999 if outside
bysort firm: egen double expected_mean=mean(cond(t<=4 & !outside,y,.))
foreach sampling in selected original {
    fegraph score if t<=4, `ids' type(ladder) bins(2) outcome(y) ///
        nonemployment(outside) sample(`sampling') ///
        nodefile(build/consistency/selected-mean.dta) replace nodraw
    fegraph score if t<=4, `ids' type(ladder) bins(2) ///
        level(expected_mean) nodecolor(expected_mean) nonemployment(outside) sample(`sampling') ///
        nodefile(build/consistency/explicit-mean.dta) replace nodraw
    preserve
    use build/consistency/selected-mean.dta, clear
    cf _all using build/consistency/explicit-mean.dta
    restore
}
* Generic outcomes can be zero/negative; eventstudy grouping uses the same means.
clear
set obs 24
gen worker=ceil(_n/6)
gen t=mod(_n-1,6)-3
gen firm=cond(t<0,worker,mod(worker,4)+1)
gen double y=firm+t-4
bysort firm: egen double ymean=mean(y)
local ids worker(worker) firm(firm) time(t)
fegraph, `ids' type(eventstudy) outcome(y) bins(2) window(-2 1) nodraw ///
    profilefile(build/consistency/profile-mean.dta) replace ///
    animation("build/consistency/eventstudy.html", replace)
assert r(N_bins)==2 & r(N_events)==4
fegraph ymean, `ids' type(eventstudy) outcome(y) bins(2) window(-2 1) nodraw ///
    profilefile(build/consistency/profile-supplied.dta) replace
preserve
use build/consistency/profile-mean.dta, clear
cf _all using build/consistency/profile-supplied.dta
restore
fegraph ymean, `ids' type(eventstudy) outcome(y) bins(0) window(-2 1) nodraw
assert r(N_bins)==4 & r(N_events)==4 & r(bins_requested)==0
foreach view in firmgraph bipartite ladder heatmap {
    fegraph, `ids' type(`view') outcome(y) bins(2) mapfile(build/consistency/event-map-`view'.dta) replace nodraw
    assert r(N_bins)==2
}
foreach opt in "wage(y) wagescale(log)" "wagescale(log)" "gross" "net" {
    capture noisily fegraph ymean, `ids' type(eventstudy) outcome(y) bins(2) `opt' nodraw
    assert _rc==198
}
display "FEGRAPH_CONSISTENCY_OK"
