version 16.0
set more off
mata: mata set matalnum on
adopath ++ stata
capture mkdir build
capture mkdir build/tests

* Large numeric keys, exact ID retention and more than 65,536 distinct string workers.
clear
set obs 140000
generate long worker=ceil(_n/2)
generate int time=mod(_n-1,2)+1
generate double firm=9007199254740000+time
generate str12 sid="w"+string(worker,"%9.0f")
fegraph, firm(firm) worker(sid) time(time) nodefile(build/tests/large_ids.dta) replace nodraw
assert r(N_workers)==70000
assert r(flow_total)==70000
assert r(N_firms)==2
preserve
use build/tests/large_ids.dta, clear
assert id=="9007199254740001" | id=="9007199254740002"
restore

* Aggregate 1 million records and 1,000 firms to 10 bins, preserving all moves.
clear
set obs 1000000
generate long worker=ceil(_n/10)
generate byte time=mod(_n-1,10)+1
generate int firm=mod(worker+time-2,1000)+1
generate double psi=firm/1000
timer clear 1
timer on 1
fegraph, firm(firm) worker(worker) time(time) type(heatmap) order(psi) bins(10) ///
    edgefile(build/tests/million_edges.dta) replace nodraw
timer off 1
assert r(flow_total)==900000
assert r(N_firms)==1000
assert r(N_shown_nodes)==10
timer list 1
preserve
use build/tests/million_edges.dta, clear
quietly summarize gross, meanonly
assert r(sum)==900000
restore

* Component selection is weak connectivity, without the outside-state hub.
clear
input str1 origin str1 destination moves oe de group_o group_d size_o size_d
A B 5 0 1 1 1 10 20
B A 2 1 0 1 1 20 10
C D 3 2 3 2 2 40 30
D C 1 3 2 2 2 30 40
U A 2 . 0 . 1 5 10
U C 2 . 2 . 2 5 40
end
capture noisily fegraph, origin(origin) destination(destination) flow(moves) type(ladder) order(oe de) ///
    outside(U) effectgroup(group_o group_d) nodraw
assert _rc==198
fegraph, origin(origin) destination(destination) flow(moves) type(ladder) order(oe de) ///
    outside(U) effectgroup(group_o group_d) component(largest) ///
    nodesize(size_o size_d) bins(2) binweight(employment) nodraw
assert r(N_components)==2
assert r(N_shown_nodes)==2 & r(N_bins)==1
assert r(flow_boundary)==2
fegraph, origin(origin) destination(destination) flow(moves) type(ladder) order(oe de) outside(U) ///
    effectgroup(group_o group_d) pooled nodecolor(oe de) colorlimits(-1 4) ///
    sizemax(100) widthmax(20) edgecolor(effect) edgelimits(-4 4) nodraw

* Prepared exposure counts include stayers, unlike mover shares.
generate double exposure=10
fegraph, origin(origin) destination(destination) flow(moves) statistic(probability) exposure(exposure) ///
    edgefile(build/tests/exposure.dta) replace nodraw
preserve
use build/tests/exposure.dta, clear
assert value==.5 if origin_id=="A"
restore
replace exposure=1
capture noisily fegraph, origin(origin) destination(destination) flow(moves) statistic(probability) exposure(exposure) nodraw
assert _rc==198

* Net heatmap filters whole unordered pairs; reverse cells stay consistent.
fegraph, origin(origin) destination(destination) flow(moves) type(heatmap) net top(1) ///
    edgefile(build/tests/net_heat.dta) replace nodraw
assert r(N_shown_edges)==2
assert r(flow_shown)==7

* Seeded force layout is identical across runs, and depends on seed.
fegraph, origin(origin) destination(destination) flow(moves) seed(10) nodefile(build/tests/seed10.dta) replace nodraw
fegraph, origin(origin) destination(destination) flow(moves) seed(10) nodefile(build/tests/seed10b.dta) replace nodraw
preserve
use build/tests/seed10.dta, clear
cf _all using build/tests/seed10b.dta
restore
fegraph, origin(origin) destination(destination) flow(moves) seed(11) nodefile(build/tests/seed11.dta) replace nodraw
preserve
use build/tests/seed10.dta, clear
capture cf x y using build/tests/seed11.dta
assert _rc==9
restore

* Categorical attributes: distinct codes remain distinct; unsafe bin average rejected.
fegraph, origin(origin) destination(destination) flow(moves) categorical nodecolor(group_o group_d) nodraw
capture noisily fegraph, origin(origin) destination(destination) flow(moves) categorical nodecolor(group_o group_d) ///
    type(ladder) order(oe de) bins(2) nodraw
assert _rc==198

* Time-free incidence uses distinct matches, not record multiplicity, for size.
clear
input worker firm
1 1
1 1
1 1
2 1
2 2
end
fegraph, firm(firm) worker(worker) type(bipartite) nodefile(build/tests/match_sizes.dta) replace nodraw
preserve
use build/tests/match_sizes.dta, clear
assert size==2 if kind==0 & id=="1"
assert size==1 if kind==0 & id=="2"
restore

display "FEGRAPH_ADVANCED_OK"
