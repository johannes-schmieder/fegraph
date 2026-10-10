version 16
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/animation
clear
input worker year firm unemployed
1 1 1 0
1 2 2 0
1 3 3 0
2 1 1 0
2 2 1 0
2 3 . 1
3 1 2 0
3 2 3 0
3 3 1 0
4 1 . 1
4 2 2 0
4 3 2 0
end
gen double score=(firm-2)/10
gen double wage=3+score+worker/20
gen str100 label="Firm "+string(firm)
replace label="Firm " + char(34) + "<&>" + char(92) + char(10) + " café </script><script>bad()</script>" if firm==1
gen order=_n
regress wage score
local b=_b[score]
quietly datasignature
local signature `"`r(datasignature)'"'
local rng `"`c(rngstate)'"'
local opts "worker(worker) firm(firm) time(year) nonemployment(unemployed)"
fegraph score, `opts' type(ladder) label(label) nodraw ///
    nodefile(build/animation/base-nodes.dta) edgefile(build/animation/base-edges.dta) replace
fegraph score, `opts' type(ladder) label(label) nodraw ///
    animation("build/animation/aggregate.html", replace) ///
    nodefile(build/animation/anim-nodes.dta) edgefile(build/animation/anim-edges.dta) replace
assert r(N_frames)==1 & r(flow_total)==6
assert "`r(animation_mode)'"=="aggregate"
assert "`r(animation)'"=="build/animation/aggregate.html"
foreach what in nodes edges {
    preserve
    use build/animation/base-`what'.dta, clear
    cf _all using build/animation/anim-`what'.dta
    restore
}
foreach view in firmgraph ladder bipartite heatmap {
    fegraph score, `opts' type(`view') label(label) nodraw ///
        animation("build/animation/`view'.html", mode(time) theme(dark) speed(.5) replace)
    assert r(N_frames)==3
}
fegraph score, `opts' type(ladder) bins(2) nodraw ///
    animation("build/animation/bins.html", mode(time) replace)
assert r(N_bins)==2
fegraph score, `opts' edge(shared) style(classic) nodraw ///
    animation("build/animation/shared.html", mode(time) replace)
fegraph score, `opts' type(firmgraph) statistic(share) nodraw ///
    animation("build/animation/share.html", mode(time) replace)
fegraph score, `opts' type(firmgraph) statistic(probability) nodraw ///
    animation("build/animation/probability.html", mode(time) replace)
fegraph score, `opts' edgecolor(wage) edgesize(wage) wage(wage) wagescale(log) nodraw ///
    animation("build/animation/wages.html", mode(time) replace)
fegraph score, `opts' palette(navy blue cyan gs14 yellow orange "190 30 45") nodraw ///
    animation("build/animation/path with space, comma.html", notitle nosubtitle nonotes nolegend nocommand replace)
assert abs(_b[score]-`b')<1e-12
assert `"`c(rngstate)'"'==`"`rng'"'
quietly datasignature
assert `"`r(datasignature)'"'==`"`signature'"'
fegraph score, `opts' nodraw ///
    animation(build/animation/unquoted.html, title("Custom title") note("Custom note") replace)
// Only nested replace authorizes overwriting HTML.
capture noisily fegraph score, `opts' animation("build/animation/aggregate.html") replace nodraw
assert _rc==602
foreach bad in "" "test.pdf" "test.html, mode(other)" "test.html, speed(0)" "test.html, theme(blue)" "test.html, bogus" {
    capture noisily fegraph score, `opts' animation(`bad') nodraw
    // Empty animation() is treated as absent by Stata syntax; other invalid calls fail.
    if `"`bad'"'!="" assert _rc==198
}
capture noisily fegraph score, worker(worker) firm(firm) edge(shared) animation(test.html, mode(time)) nodraw
assert _rc==198
// Fixed pooled net pair can reverse direction in a period.
clear
input origin destination year moves
1 2 1 10
2 1 1 2
1 2 2 1
2 1 2 5
end
gen double a=origin/10
gen double b=destination/10
foreach view in ladder heatmap {
    fegraph a b, origin(origin) destination(destination) flow(moves) time(year) ///
        type(`view') net nodescale(.7) nodraw edgefile(build/animation/net-edges.dta) replace ///
        animation("build/animation/net-`view'.html", mode(time) replace)
    assert r(flow_total)==18 & r(N_frames)==2
}
// Frame probabilities retain full denominators across hidden destinations.
clear
input worker year firm
1 1 1
1 2 2
2 1 1
2 2 3
3 1 1
3 2 1
end
fegraph, worker(worker) firm(firm) time(year) statistic(probability) top(1) nodraw ///
    animation("build/animation/hidden.html", mode(time) replace)
// Original adjacency does not bridge an excluded record, selected adjacency may.
clear
input worker year firm selected
1 1 1 1
1 2 2 0
1 3 3 1
2 1 1 1
2 2 2 1
2 3 3 1
end
foreach sample in selected original {
    fegraph if selected, worker(worker) firm(firm) time(year) maxgap(2) sample(`sample') nodraw ///
        animation("build/animation/sample-`sample'.html", mode(time) replace)
}
// Empty directed graph and exact large string IDs.
clear
input str25 firm worker year
"900719925474099312345" 1 1
"900719925474099312345" 1 2
end
fegraph, worker(worker) firm(firm) time(year) nodraw ///
    animation("build/animation/empty.html", mode(time) replace)
assert r(N_frames)==2 & r(N_edges)==0
// Both a single period and a completely inactive worker graph remain valid.
keep if year==1
fegraph, worker(worker) firm(firm) time(year) type(bipartite) nodraw ///
    animation("build/animation/single.html", mode(time) replace)
assert r(N_frames)==1
// Installation-independent nested parser and HTML assets are available.
findfile fegraph__viewer.html
findfile fegraph__html.mata
display "FEGRAPH_ANIMATION_OK"
