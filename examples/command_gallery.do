version 16.0
set more off
adopath ++ stata
preserve
capture noisily {
    capture mkdir build
    capture mkdir build/command-gallery
    quietly do examples/synthetic_panel.do
    generate double firm=firmid
    replace firm=. if unemployed
    fegraph psi, firm(firm) worker(workerid) time(time) net edgecolor(effect) ///
        name(fegraph_firms, replace) graphopts(title("Firm mobility"))
    graph export build/command-gallery/firm.png, width(2000) replace
    graph export build/command-gallery/firm.pdf, replace
    fegraph psi if inlist(workerid,1,3,5,7,8,9,12,13), firm(firm) worker(workerid) time(time) ///
        type(bipartite) nodecolor(psi) name(fegraph_matches, replace)
    graph export build/command-gallery/bipartite.png, width(2000) replace
    graph export build/command-gallery/bipartite.pdf, replace
    fegraph psi, firm(firm) worker(workerid) time(time) type(ladder) nodecolor(psi) ///
        net nonemployment(unemployed) outsidelabel(Unemployment) edgecolor(effect) ///
        name(fegraph_ladder, replace)
    graph export build/command-gallery/ladder.png, width(2000) replace
    graph export build/command-gallery/ladder.pdf, replace
    fegraph psi, firm(firm) worker(workerid) time(time) type(heatmap) bins(3) ///
        nonemployment(unemployed) outsidelabel(Unemployment) statistic(share) ///
        name(fegraph_heatmap, replace)
    graph export build/command-gallery/heatmap.png, width(2000) replace
    graph export build/command-gallery/heatmap.pdf, replace
}
local rc=_rc
restore
if `rc' exit `rc'
display "FEGRAPH_GALLERY_OK"
