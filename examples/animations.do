version 16
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/animation-gallery
preserve
clear
set obs 720
generate workerid=ceil(_n/12)
generate year=mod(_n-1,12)+2000
generate firmid=mod(floor((workerid-1)/5)+floor((year-2000)/2),12)+1
generate byte unemployed=mod(workerid,7)==0 & inlist(year,2003,2004,2008)
replace firmid=. if unemployed
generate double psi=(firmid-6.5)/12
foreach view in firmgraph ladder heatmap bipartite {
    local opts
    if "`view'"=="firmgraph" local opts "style(classic) layout(circle)"
    if inlist("`view'","ladder","heatmap") local opts "bins(6)"
    local sample
    if "`view'"=="bipartite" local sample "if workerid<=8"
    fegraph psi `sample', worker(workerid) firm(firmid) time(year) type(`view') ///
        nonemployment(unemployed) outsidelabel(Unemployment) `opts' ///
        animation("build/animation-gallery/`view'.html", mode(time) theme(dark) replace) ///
        name(fegraph_`view', replace) nodraw
}
restore
display "FEGRAPH_ANIMATION_GALLERY_OK"
