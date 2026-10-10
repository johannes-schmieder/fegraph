version 16.0
set more off
adopath ++ stata
preserve
capture noisily {
    capture mkdir build
    capture mkdir build/palettes
    quietly do examples/network_panel.do
    foreach palette in viridis blues redblue grays {
        fegraph psi, worker(workerid) firm(firmid) edge(shared) ///
            style(classic) nodesize(matches) palette(`palette') ///
            label(firmname) labeltop(4) iterations(600) seed(7) ///
            name(palette_`palette', replace) ///
            graphopts(title("`palette'") subtitle("") note("") legend(off) xsize(5) ysize(5))
    }
    graph combine palette_viridis palette_blues palette_redblue palette_grays, ///
        cols(2) graphregion(color(white)) xsize(10) ysize(8) ///
        title("Choose the firm-color palette") ///
        note("Same 72 firms, 80 links, supplied scores and coordinates in every panel.", size(small)) ///
        name(fegraph_palettes, replace)
    graph export build/palettes/comparison.png, width(2200) replace
}
local rc=_rc
restore
if `rc' exit `rc'
display "FEGRAPH_PALETTE_GALLERY_OK"
