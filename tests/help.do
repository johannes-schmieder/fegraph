version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/help-render
findfile fegraph.sthlp
local helpfile `"`r(fn)'"'
foreach width in 79 120 {
    translate `"`helpfile'"' "build/help-render/help-`width'.txt", ///
        translator(smcl2txt) linesize(`width') replace
}
clear
set obs 3
generate original = _n
generate y = original^2
quietly regress y original
local b = _b[original]
quietly datasignature
local signature `"`r(datasignature)'"'
foreach example in common_options firmgraph bipartite ladder heatmap manybins classic classic_color palettes animation animation_time eventstudy eventstudy_coworker eventstudy_cohorts {
    fegraph_run `example' using fegraph.sthlp
    assert _b[original]==`b'
    quietly datasignature
    assert `"`r(datasignature)'"'==`"`signature'"'
}
capture noisily fegraph_run absent_example using fegraph.sthlp
assert _rc==111
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
display "FEGRAPH_HELP_OK"
