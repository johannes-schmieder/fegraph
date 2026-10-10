version 16.0
set more off
capture mkdir build
capture mkdir build/package-ado
local root `"`c(pwd)'"'
net set ado `"`root'/build/package-ado"'
net install fegraph, from(`"`root'"') replace
capture adopath - stata
adopath ++ `"`root'/build/package-ado"'
which fegraph
findfile fegraph.mata
findfile fegraph.sthlp
fegraph, version
assert `"`r(version)'"'=="0.5.0"
fegraph, selftest
assert r(passed)==1
foreach view in firmgraph bipartite ladder heatmap {
    fegraph_example, type(`view') nodraw
}
findfile fegraph_report.ado
findfile fegraph_run.ado
fegraph_run ladder using fegraph.sthlp
fegraph_run classic using fegraph.sthlp
findfile fegraph__palette.ado
fegraph_run palettes using fegraph.sthlp
display "FEGRAPH_PACKAGE_OK"
