version 16.0
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/palettes
clear
set obs 7
generate workerid = _n
expand 2
bysort workerid: generate year = _n
generate firmid = cond(year==1,workerid,mod(workerid,7)+1)
generate score = firmid-4
generate worker_score = workerid-4
generate wage = 3+score/10
quietly regress wage score
local b=_b[score]
quietly datasignature
local signature `"`r(datasignature)'"'
local rng `"`c(rngstate)'"'
local args "worker(workerid) firm(firmid) time(year) layout(circle) nodesize(equal)"
local clean `"graphopts(scheme(s2color) title("") subtitle("") note(""))"'
// Defaults are unchanged; palette changes cannot affect the exported graph.
fegraph score, `args' edgecolor(effect) ///
    nodefile(build/palettes/default-nodes.dta) edgefile(build/palettes/default-edges.dta) replace
assert "`r(palette)'"=="viridis" & "`r(edgepalette)'"=="brownteal"
fegraph score, `args' palette(blues) edgecolor(effect) edgepalette(redblue, reverse) ///
    nodefile(build/palettes/custom-nodes.dta) edgefile(build/palettes/custom-edges.dta) replace
assert "`r(palette)'"=="blues" & "`r(edgepalette)'"=="redblue, reverse"
assert r(flow_total)==7 & r(N_shown_nodes)==7
assert abs(_b[score]-`b')<1e-12
assert `"`c(rngstate)'"'==`"`rng'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
preserve
use build/palettes/default-nodes.dta, clear
cf _all using build/palettes/custom-nodes.dta
restore
preserve
use build/palettes/default-edges.dta, clear
cf _all using build/palettes/custom-edges.dta
restore
// Every named palette renders; SVG checks verify actual markers and legend keys.
foreach palette in viridis blues greens grays redblue brownteal {
    fegraph score, `args' edge(shared) palette(`palette') `clean'
    assert "`r(palette)'"=="`palette'"
    local colors `"`r(palette_colors)'"'
    local n : word count `colors'
    assert `n'==7
    graph export build/palettes/`palette'.svg, replace
}
fegraph score, `args' edge(shared) palette(blues, reverse) `clean'
graph export build/palettes/blues-reverse.svg, replace
fegraph score, `args' edge(shared) palette(navy blue cyan gs14 yellow orange "190 30 45") `clean'
assert "`r(palette)'"=="custom"
graph export build/palettes/custom.svg, replace
// Reverse custom RGB/name mixtures through the installed parser too.
fegraph score, `args' palette(navy blue cyan gs14 yellow orange "190 30 45", reverse)
assert "`r(palette)'"=="custom, reverse"
local colors `"`r(palette_colors)'"'
local first : word 1 of `colors'
assert "`first'"=="190 30 45"
fegraph score, `args' palette("BLUES", reverse)
assert "`r(palette)'"=="blues, reverse"
fegraph score, `args' palette(bg fg background foreground navy blue red)
assert "`r(palette)'"=="custom"
// Categorical and worker palettes use the same color ordering.
fegraph score, `args' edge(shared) categorical palette(greens) `clean'
graph export build/palettes/categorical.svg, replace
fegraph score, `args' type(bipartite) palette(grays) workercolor(worker_score) `clean'
graph export build/palettes/bipartite.svg, replace
// Edge gradients cover both signs, preserving arrowheads and their direction.
foreach choice in effect wage {
    fegraph score, `args' edgecolor(`choice') wage(wage) wagescale(log) edgepalette(redblue) `clean'
    graph export build/palettes/edges-`choice'.svg, replace
}
fegraph score, `args' edgecolor(effect) edgepalette(redblue, reverse) `clean'
graph export build/palettes/edges-reverse.svg, replace
fegraph score, `args' edgecolor(effect) edgepalette(navy blue cyan gs14 yellow orange "190 30 45")
fegraph score, `args' type(ladder) edgecolor(effect) palette(blues) edgepalette(redblue)
// palette() controls both gross and net heatmap cells, with contextual defaults.
fegraph score, `args' type(heatmap) net
assert "`r(palette)'"=="brownteal"
fegraph score, `args' type(heatmap) palette(greens) `clean'
graph export build/palettes/heatmap.svg, replace
fegraph score, `args' type(heatmap) net palette(redblue, reverse) `clean'
assert "`r(palette)'"=="redblue, reverse"
graph export build/palettes/heatmap-net.svg, replace
// Validate every entry, including classes unused in a particular dataset.
foreach bad in "rainbow" "red blue" "navy blue cyan gs14 yellow orange notacolor" "navy blue cyan gs14 yellow orange red*2" {
    capture noisily fegraph score, `args' palette(`bad')
    assert _rc==198
    assert abs(_b[score]-`b')<1e-12
}
foreach bad in `""256 0 0""' `""1.5 0 0""' `""-1 0 0""' `""hsv 0 1 1""' `""0 0 .""' {
    capture noisily fegraph score, `args' palette(navy blue cyan gs14 yellow orange `bad')
    assert _rc==198
}
capture noisily fegraph score, `args' palette(blues, typo)
assert _rc==198
capture noisily fegraph score, `args' edgepalette(unknown)
assert _rc==198
capture noisily fegraph score, `args' type(heatmap) edgepalette(redblue)
assert _rc==198
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
assert `"`c(rngstate)'"'==`"`rng'"'
do examples/palettes.do
display "FEGRAPH_PALETTES_OK"
