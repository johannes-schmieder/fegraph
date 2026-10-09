version 16.0
set more off
mata: mata set matalnum on
adopath ++ stata
capture mkdir build
capture mkdir build/tests

* Fractional flows, duplicate pairs, zero rows, isolates, and net reversals.
clear
input str3 origin str3 destination double count double origin_effect double destination_effect
A B 2.5 0 1
A B 1.5 0 1
B A 1 1 0
B C 2 1 2
C B 2 2 1
D D 99 3 3
D A 0 3 0
end
generate long original_order=_n
quietly regress count origin_effect
tempname saved_b
matrix `saved_b'=e(b)
local rng `"`c(rngstate)'"'
quietly datasignature
local signature `"`r(datasignature)'"'
fegraph origin destination, flow(count) nodecolor(origin_effect destination_effect) net ///
    layout(circle) nodefile(build/tests/contract_nodes.dta) edgefile(build/tests/contract_edges.dta) ///
    saving(build/tests/contracts.gph) replace nodraw
assert r(flow_total)==9
assert r(N_firms)==4
assert r(N_components)==2
assert r(N_shown_edges)==1
assert r(flow_shown)==5
assert r(flow_hidden_net)==6
assert reldif(e(b)[1,1],`saved_b'[1,1])==0
assert `"`c(rngstate)'"'==`"`rng'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
assert original_order==_n
preserve
use build/tests/contract_edges.dta, clear
assert gross==4 & reverse==1 & net==3 if origin_id=="A"
assert displayed==0 if origin_id=="B" | origin_id=="C"
restore

* Reuse saved coordinates, preserving caller data and RNG.
fegraph origin destination, flow(count) coordinates(build/tests/contract_nodes.dta) ///
    nodefile(build/tests/reused_nodes.dta) replace nodraw
preserve
use build/tests/contract_nodes.dta, clear
keep id kind x y
rename (x y) (oldx oldy)
tempfile xy
save `xy'
use build/tests/reused_nodes.dta, clear
merge 1:1 id kind using `xy', assert(match) nogen
assert x==oldx & y==oldy
restore

* Full-origin denominators survive display thresholding / ego selection.
fegraph origin destination, flow(count) statistic(share) minflow(3) ///
    edgefile(build/tests/shares.dta) replace nodraw
preserve
use build/tests/shares.dta, clear
assert abs(value-1/3)<1e-12 if origin_id=="B" & destination_id=="A"
assert displayed==0 if origin_id=="B"
restore
fegraph origin destination, flow(count) ego(A) steps(1) ///
    edgefile(build/tests/ego.dta) replace nodraw
assert r(flow_boundary)==4
assert r(flow_total)==9
assert r(N_shown_nodes)==2

* Failures must not change data, observation order, estimates or leave frames.
quietly datasignature
local signature `"`r(datasignature)'"'
capture noisily fegraph origin destination, flow(count) maxnodes(1)
assert _rc==198
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
assert `"`c(rngstate)'"'==`"`rng'"'
capture noisily fegraph origin destination, flow(count) nodefile(build/tests/contract_nodes.dta)
assert _rc==602
replace count=-1 in 1
capture noisily fegraph origin destination, flow(count)
assert _rc==198
replace count=2.5 in 1
replace destination_effect=9 in 2
capture noisily fegraph origin destination, flow(count) nodecolor(origin_effect destination_effect)
assert _rc==198
replace destination_effect=1 in 2

* Panel: an unobserved employer is a break, explicit outside state creates two legs.
clear
input str1 worker double time double firm double outside double lnw
a 1 1 0 1
 a 2 . 1 .
 a 3 2 0 1.3
 b 1 1 0 1
 b 2 2 0 1.2
 b 3 1 0 1.1
 c 1 1 0 1
 c 2 1 0 1.1
 d 1 2 0 2
 d 3 3 0 2.2
end
fegraph firm, worker(worker) time(time) wage(lnw) wagescale(log) edgecolor(wage) ///
    statistic(probability) edgefile(build/tests/panel.dta) replace nodraw
assert r(flow_total)==2
assert r(N_eligible)==3
assert r(N_gaps)==1
assert r(N_unknown)==2
preserve
use build/tests/panel.dta, clear
assert abs(mean_wage_change-.2)<1e-12 & value==.5 if origin_id=="1"
assert abs(mean_wage_change+.1)<1e-12 & value==1 if origin_id=="2"
restore
fegraph firm, worker(worker) time(time) nonemployment(outside) nodraw
assert r(flow_total)==4
assert r(N_firms)==3
assert r(N_nodes)==4

* if/in semantics match ferank by default, and original adjacency is available.
fegraph firm if time!=2, worker(worker) time(time) maxgap(2) nodraw
assert r(flow_total)==2
fegraph firm if time!=2, worker(worker) time(time) maxgap(2) sample(original) nodraw
assert r(flow_total)==1

* Match projection adds A-C for an A-B-C worker, with each worker counted once.
clear
input str1 worker double time double firm double psi
x 1 1 0
x 2 2 1
x 3 3 2
x 4 1 0
y 1 1 0
y 2 1 0
end
fegraph firm, worker(worker) time(time) edge(shared) edgefile(build/tests/shared.dta) replace nodraw
assert r(flow_total)==3
assert r(N_edges)==3
fegraph firm, worker(worker) type(bipartite) nodecolor(psi) ///
    nodefile(build/tests/matches.dta) replace nodraw
assert r(N_matches)==4
assert r(N_nodes)==5

* Repeated firm rows cannot bias bin heights or ties; flows conserved.
fegraph firm, worker(worker) time(time) type(ladder) order(psi) level(psi) bins(2) ///
    nodefile(build/tests/bins.dta) edgefile(build/tests/bin_edges.dta) ///
    mapfile(build/tests/binmap.dta) replace nodraw
assert r(flow_total)==3
assert r(flow_within)==1
preserve
use build/tests/bins.dta, clear
assert abs(level-1.5)<1e-12 if id=="bin:2"
restore
replace psi=0 if firm==2
fegraph firm, worker(worker) time(time) type(ladder) order(psi) bins(10) ///
    mapfile(build/tests/ties.dta) replace nodraw
assert r(N_shown_nodes)==2
preserve
use build/tests/ties.dta, clear
quietly summarize node if original_id=="1", meanonly
local b=r(mean)
assert node==`b' if original_id=="2"
restore

* Empty edges and a single firm should still plot; duplicate worker-time rejects.
keep if worker=="y"
fegraph firm, worker(worker) time(time) nodraw
assert r(flow_total)==0
assert r(N_nodes)==1
fegraph firm, worker(worker) time(time) type(heatmap) nodraw
assert r(flow_total)==0
expand 2 in 1
capture noisily fegraph firm, worker(worker) time(time)
assert _rc==198

* Numeric worker/firm ID collisions remain separate nodes.
clear
input worker time firm wc
1 1 1 5
1 2 2 5
2 1 2 8
end
fegraph firm, worker(worker) time(time) type(bipartite) workercolor(wc) ///
    nodefile(build/tests/collisions.dta) replace nodraw
assert r(N_nodes)==4
preserve
use build/tests/collisions.dta, clear
count if id=="1"
assert r(N)==2
assert color==5 if id=="1" & kind==1
restore

* Color and width statistics are independent.
clear
input worker time firm wage effect
1 1 1 10 0
1 2 2 20 .1
2 1 1 10 0
2 2 2 15 .1
end
fegraph firm, worker(worker) time(time) wage(wage) wagescale(level) ///
    level(effect) edgecolor(wage) edgesize(effect) edgefile(build/tests/dual_style.dta) replace nodraw
preserve
use build/tests/dual_style.dta, clear
assert abs(color-75)<1e-12
assert abs(width_value-.1)<1e-7
restore

display "FEGRAPH_CONTRACTS_OK"
