version 16
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/eventstudy
clear
set obs 128
gen long worker=ceil(_n/4)
bysort worker: gen double year=_n
gen origin=ceil(worker/8)
gen destination=1+mod(ceil(worker/2)-1,4)
gen long firm=cond(year<3,origin,destination+4)
gen double score=cond(firm<=4,firm,firm-4)
gen double wage=3+score/5+worker/100+.01*year
gen byte unemployed=0
gen int group=score
gen original_order=_n
regress wage score
local b=_b[score]
local rng `"`c(rngstate)'"'
quietly datasignature
local signature `"`r(datasignature)'"'
local opts "worker(worker) firm(firm) time(year) type(eventstudy) wage(wage) wagescale(log)"
fegraph score, `opts' ci nodraw profilefile(build/eventstudy/base.dta) eventfile(build/eventstudy/events.dta) replace animation(build/eventstudy/base.html, replace)
assert r(N_events)==32 & r(N_workers)==32 & r(N_bins)==4 & r(N_paths)==16 & r(N_frames)==4
assert _b[score]==`b'
assert `"`c(rngstate)'"'==`"`rng'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
preserve
use build/eventstudy/base.dta, clear
assert _N==64 & n_events==2 & n_workers==2
assert abs(mean-(3+cond(event_time<0,origin_bin,destination_bin)/5+(8*(origin_bin-1)+2*destination_bin-.5)/100+.01*(event_time+3)))<1e-10
assert abs(se-.005)<1e-10
export delimited using build/eventstudy/base.csv, replace
restore
fegraph score, `opts' normalize(-1) frombins(1 4) overlay ci nodraw profilefile(build/eventstudy/normalized.dta) replace animation(build/eventstudy/normalized.html, title("Test </script> & title") replace)
assert r(N_shown_events)==16 & r(N_events)==32 & r(N_paths)==8
preserve
use build/eventstudy/normalized.dta, clear
assert abs(mean)<1e-12 if event_time==-1
assert abs(se)<1e-12
assert shown==inlist(origin_bin,1,4)
restore
// An eligible pooled cell may be too small in every arrival cohort.
preserve
replace year=year+10 if mod(worker,2)==0
capture noisily fegraph score, `opts' mincell(2) nodraw animation(build/eventstudy/no-cohorts.html, mode(time) replace)
assert _rc==2000
capture confirm file build/eventstudy/no-cohorts.html
assert _rc==601
restore
// Static Stata render, confidence intervals and user annotation suppression.
fegraph score, `opts' frombins(1 4) overlay ci name(eventstudy_test, replace)
graph export build/eventstudy/overlay.png, width(1800) replace
fegraph score, `opts' name(eventstudy_test, replace)
graph export build/eventstudy/panels.png, width(1800) replace
fegraph score, `opts' name(eventstudy_test, replace) graphopts(title("") subtitle("") note(""))
graph export build/eventstudy/annotations.svg, replace
// Group labels vary within a firm and are anchored at endpoints.
preserve
replace group=4 if worker==1 & year==2
fegraph, `opts' group(group) nodraw eventfile(build/eventstudy/custom-events.dta) replace
assert r(N_events)==32
use build/eventstudy/custom-events.dta, clear
assert origin_bin==4 if worker_id==1
restore
// Fixed pooled bins and separate calendar arrival cohorts.
preserve
replace year=year+10 if worker>16
fegraph score, `opts' nodraw profilefile(build/eventstudy/cohorts.dta) replace animation(build/eventstudy/cohorts.html, mode(time) replace)
assert r(N_frames)==2 & r(N_events)==32
restore
// Hierarchical exclusions; unemployment is a break, not a wage of zero.
preserve
replace year=5 if worker==1 & year==4
replace wage=. if worker==2 & year==1
replace group=. if worker==3 & year==2
replace unemployed=1 if worker==4 & year==2
fegraph, `opts' group(group) nonemployment(unemployed) nodraw
assert r(N_candidates)==31 & r(N_events)==28
assert r(N_excluded_window)==1 & r(N_excluded_outcome)==1 & r(N_excluded_group)==1
restore
// Quantiles agree with native xtile and retain ties, including sparse labels.
preserve
fegraph score, `opts' bins(10) nodraw eventfile(build/eventstudy/deciles.dta) replace
use build/eventstudy/deciles.dta, clear
keep firm_origin origin_bin
duplicates drop
sort firm_origin
assert origin_bin==1 if firm_origin==1
assert origin_bin==3 if firm_origin==2
assert origin_bin==6 if firm_origin==3
assert origin_bin==8 if firm_origin==4
restore
fegraph score, `opts' bins(1) nodraw saving(build/eventstudy/single-bin.gph) replace
assert r(N_bins)==1 & r(N_paths)==1 & r(N_events)==32
fegraph score, `opts' binweight(employment) descending nodraw
assert r(N_bins)==4 & r(N_events)==32
// Native weighted-quantile reference on unequal employment, plus equal-firm invariance.
preserve
expand 3 if origin==1
bysort worker year: gen replica=_n-1
replace worker=worker+32*replica
isid worker year
tempfile weighted_reference weighted_panel
save `weighted_panel'
bysort firm: gen long weight=_N
egen byte tag=tag(firm)
keep if tag
xtile reference=score [aw=weight], nq(4)
keep firm reference
save `weighted_reference'
use `weighted_panel', clear
fegraph score, `opts' binweight(employment) nodraw eventfile(build/eventstudy/weighted-events.dta) replace
assert r(N_events)==48
use build/eventstudy/weighted-events.dta, clear
keep if event_time==-1
rename firm_origin firm
merge m:1 firm using `weighted_reference', keep(master match) nogen
assert origin_bin==reference
restore
// All validation failures preserve caller state.
foreach bad in "window(0 1)" "window(-2 -1)" "delta(0)" "bins(-1)" "normalize(5)" "frombins(9)" "mincell(0)" "net" "group(group)" {
    capture noisily fegraph score, `opts' `bad' nodraw
    assert _rc==198
}
capture noisily fegraph score, `opts' animation(build/eventstudy/base.html) replace nodraw
assert _rc==602
assert _b[score]==`b'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
assert `"`c(rngstate)'"'==`"`rng'"'
// Repeated movers: events are equally weighted, workers are SE clusters.
clear
input str24 worker double year firm score wage
"900719925474099312345" 1 1 1 0
"900719925474099312345" 2 1 1 0
"900719925474099312345" 3 2 2 1
"900719925474099312345" 4 2 2 1
"900719925474099312345" 5 1 1 2
"900719925474099312345" 6 1 1 2
"900719925474099312345" 7 2 2 4
"900719925474099312345" 8 2 2 4
"second" 1 1 1 0
"second" 2 1 1 0
"second" 3 2 2 6
"second" 4 2 2 6
end
fegraph score, `opts' bins(2) ci normalize(-1) nodraw profilefile(build/eventstudy/repeated.dta) eventfile(build/eventstudy/repeated-events.dta) replace animation(build/eventstudy/repeated.html, replace)
assert r(N_events)==4 & r(N_workers)==2
preserve
use build/eventstudy/repeated.dta, clear
assert n_events==3 & n_workers==2 if origin_bin==1
assert abs(mean-3)<1e-12 if origin_bin==1 & event_time==0
assert abs(se-2)<1e-12 if origin_bin==1 & event_time==0
assert missing(se) if origin_bin==2
export delimited using build/eventstudy/repeated.csv, replace
restore
// Fractional regular time units are explicit, with unchanged event means.
replace year=year*.25
fegraph score, `opts' bins(2) delta(.25) normalize(-1) nodraw
assert r(N_events)==4
// Duplicate keys and changing firm scores are errors.
expand 2 in 1
capture noisily fegraph score, `opts' bins(2) delta(.25) nodraw
assert _rc==459
clear
set obs 5
gen worker=1
gen double year=cond(_n==1,1,cond(_n==2,1.5,_n-1))
gen firm=cond(year<3,1,2)
gen score=firm
gen wage=firm+year/10
fegraph score if year!=1.5, `opts' bins(2) nodraw
assert r(N_events)==1
capture noisily fegraph score if year!=1.5, `opts' bins(2) sample(original) nodraw
assert _rc==2000
replace score=99 in 1
capture noisily fegraph score, `opts' bins(2) nodraw
assert _rc==459
display "FEGRAPH_EVENTSTUDY_OK"
