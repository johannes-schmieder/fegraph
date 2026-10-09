version 16.0
set more off
adopath ++ stata
clear
set obs 3
generate original = _n
generate y = original^2
quietly regress y original
local b = _b[original]
quietly datasignature
local signature `"`r(datasignature)'"'
foreach example in firmgraph bipartite ladder heatmap manybins {
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
