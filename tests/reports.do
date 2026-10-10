version 19.0
set more off
args fesim_path ferank_path fereg_path texpdf_path
adopath ++ stata
adopath ++ "`fesim_path'"
adopath ++ "`ferank_path'/stata"
adopath ++ "`fereg_path'/stata"
adopath ++ "`fereg_path'/dist"
adopath ++ "`texpdf_path'/stata"
capture mkdir build
capture mkdir "build/report examples"
local root `"`c(pwd)'"'
local rng `"`c(rngstate)'"'
clear
set obs 10
generate original = _n
generate y = original^2
quietly regress y original
local b = _b[original]
quietly datasignature
local signature `"`r(datasignature)'"'
// Execute the exact report blocks extracted from the installed-style help.
// Dedicated outputs live in this ignored folder, including a path with spaces.
quietly cd "build/report examples"
adopath ++ `"`root'/stata"'
foreach example in report_akm report_ladder report_bm report_all pipeline {
    fegraph_run `example' using fegraph.sthlp
    quietly datasignature
    assert `"`r(datasignature)'"'==`"`signature'"'
    assert `"`c(rngstate)'"'==`"`rng'"'
    assert _b[original]==`b'
}
foreach model in akm ladder bm all {
    confirm file "fegraph_examples/`model'/report.pdf"
    if "`model'"!="all" {
        foreach grouping in akm coworker rank {
            foreach ext in pdf html dta {
                confirm file "fegraph_examples/`model'/`model'-event-`grouping'.`ext'"
                confirm file "fegraph_examples/all/`model'-event-`grouping'.`ext'"
            }
        }
    }
}
confirm file "fegraph_examples/pipeline.pdf"
quietly cd `"`root'"'
local location `"`c(pwd)'"'
capture noisily fegraph_report, outdir("build/report examples/fegraph_examples/akm")
assert _rc==602
assert `"`c(pwd)'"'==`"`location'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
// An existing profile table alone must also require explicit replacement.
capture mkdir build/reporttable-guard
save "build/reporttable-guard/akm-event-akm.dta", replace
capture noisily fegraph_report, dgp(akm) outdir("build/reporttable-guard")
assert _rc==602
capture confirm file "build/reporttable-guard/report.tex"
assert _rc==601
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
display "FEGRAPH_REPORTS_OK"
