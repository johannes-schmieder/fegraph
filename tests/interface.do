version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/tests
quietly do examples/synthetic_panel.do
quietly datasignature
local signature `"`r(datasignature)'"'
local rng `"`c(rngstate)'"'
local caller `c(frame)'

* Optional positional score supplies defaults without excluding unemployment.
fegraph psi, worker(workerid) firm(firmid) time(time) type(ladder) ///
    nonemployment(unemployed) nodefile(build/tests/new_syntax.dta) replace nodraw
assert r(flow_total)==41 & r(N_nodes)==7 & r(N_bins)==0
assert `"`r(score)'"'=="psi"
fegraph, worker(workerid) firm(firmid) time(time) type(ladder) order(psi) ///
    nonemployment(unemployed) nodefile(build/tests/explicit_order.dta) replace nodraw
preserve
use build/tests/new_syntax.dta, clear
cf _all using build/tests/explicit_order.dta
assert color==level & level==ordering if kind==0
assert missing(color,level,ordering) if kind==2
restore

* No-score graphs, metadata calls, qualifiers and independent level/color.
fegraph, worker(workerid) firm(firmid) type(bipartite) nonemployment(unemployed) nodraw
fegraph if time>1, worker(workerid) firm(firmid) time(time) nonemployment(unemployed) nodraw
fegraph, version
assert `"`r(version)'"'=="0.4.0"
generate double rank_pct=100*(firmid-1)/5 if !unemployed
fegraph rank_pct, worker(workerid) firm(firmid) time(time) type(ladder) ///
    level(psi) nodecolor(psi) nonemployment(unemployed) ///
    nodefile(build/tests/separate_level.dta) replace nodraw
preserve
use build/tests/separate_level.dta, clear
assert abs(level-(-.3+.12*(real(id)-1)))<1e-12 if kind==0
assert ordering!=level if kind==0
restore

* Explicit IDs prevent silently interpreting legacy IDs as scores.
capture noisily fegraph firmid, worker(workerid) time(time) nodraw
assert _rc==198
capture noisily fegraph psi, firm(firmid) nodraw
assert _rc==198
capture noisily fegraph psi rank_pct, worker(workerid) firm(firmid) time(time) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) time(time) order(rank_pct) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) origin(firmid) destination(firmid) nodraw
assert _rc==198
capture noisily fegraph, origin(firmid) nodraw
assert _rc==198
capture noisily fegraph, worker(workerid) firm(firmid) time(time) type(ladder) bins(3) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) time(time) type(ladder) bins(2.5) nodraw
assert _rc==198
capture noisily fegraph psi, worker(workerid) firm(firmid) time(time) type(ladder) bins(2001) nodraw
assert _rc==198
drop rank_pct
assert `"`c(rngstate)'"'==`"`rng'"'
assert "`c(frame)'"=="`caller'"
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'

clear
input str1 from str1 to double so double sd double moves
A B 0 1 4
B A 1 0 1
B C 1 2 3
U A . 0 2
end
fegraph so sd, origin(from) destination(to) flow(moves) type(ladder) ///
    outside(U) bins(2) mapfile(build/tests/edge_score_map.dta) replace nodraw
assert r(flow_total)==10 & r(N_bins)==2
fegraph, origin(from) destination(to) flow(moves) outside(U) nodraw
capture noisily fegraph from to, flow(moves) nodraw
assert _rc==198
capture noisily fegraph so, origin(from) destination(to) flow(moves) nodraw
assert _rc==198
capture noisily fegraph from, worker(from) firm(to) type(bipartite) nodraw
assert _rc!=0
display "FEGRAPH_INTERFACE_OK"
