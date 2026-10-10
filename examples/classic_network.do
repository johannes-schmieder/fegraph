preserve
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/classic
quietly do examples/network_panel.do
fegraph, worker(workerid) firm(firmid) time(year) type(firmgraph) ///
    edge(shared) style(classic) layout(force) nodesize(matches) label(firmname) ///
    labeltop(12) iterations(600) seed(7) nodescale(.35) ///
    nodefile(build/classic/nodes.dta) edgefile(build/classic/edges.dta) replace ///
    name(classic_network, replace) ///
    graphopts(title("Firm network") subtitle("Shared workers; labels identify the 12 largest firms") xsize(9) ysize(8))
graph export build/classic/network.png, width(2000) replace
fegraph psi, worker(workerid) firm(firmid) time(year) type(firmgraph) ///
    edge(shared) style(classic) nodesize(matches) label(firmname) ///
    labeltop(12) iterations(600) seed(7) nodescale(.35) ///
    name(classic_color, replace) ///
    graphopts(title("Firm network by wage effect") subtitle("Same workers, connections and layout") xsize(9) ysize(8))
graph export build/classic/network-color.png, width(2000) replace
restore
display "FEGRAPH_CLASSIC_GALLERY_OK"
