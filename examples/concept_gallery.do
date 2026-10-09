version 16.0
* Run from the repository root. Graphics proof only: fegraph is not implemented.
* All observations, firm effects and coordinates are synthetic illustrations.

capture program drop fegraph_gallery_links
program define fegraph_gallery_links
    syntax using/
    tempfile origins destinations
    preserve
        use `"`using'"', clear
        keep firmid nx ny psi
        rename (firmid nx ny psi) (origin x1 y1 psi1)
        save `origins'
        rename (origin x1 y1 psi1) (destination x2 y2 psi2)
        save `destinations'
    restore
    merge m:1 origin using `origins', keep(master match) assert(match using) nogen
    merge m:1 destination using `destinations', keep(master match) assert(match using) nogen
end

capture program drop fegraph_gallery_run
program define fegraph_gallery_run
    version 16.0
    capture mkdir build
    capture mkdir build/gallery
    tempfile panel nodes gross net layout links worker_nodes
    quietly do examples/synthetic_panel.do
    save `panel'

    * Mean employment over all five periods, including zero-employment dates.
    contract firmid
    generate double employment = _freq/5
    generate double psi = -.30 + .12*(firmid-1) if firmid > 0
    generate str16 label = "F" + string(firmid)
    replace label = "Unemployment" if firmid == 0
    save `nodes'

    use `panel', clear
    bysort workerid (time): generate byte origin = firmid[_n-1] if _n>1
    generate byte destination = firmid
    keep if !missing(origin) & origin != destination
    contract origin destination
    rename _freq moves
    save `gross'

    * Net firm flows. Outside-state flows are added separately to the ladder.
    keep if origin > 0 & destination > 0
    generate byte a = min(origin,destination)
    generate byte b = max(origin,destination)
    generate signed = cond(origin==a,moves,-moves)
    collapse (sum) net=signed gross=moves, by(a b)
    generate byte origin = cond(net>0,a,b)
    generate byte destination = cond(net>0,b,a)
    generate moves = abs(net)
    keep if moves > 0
    save `net'

    local colors `""68 1 84" "65 68 135" "42 120 142" "34 168 132" "122 209 81" "205 207 45""'

    * A. Firm graph: fixed circular coordinates, not an estimated embedding.
    use `nodes', clear
    keep if firmid > 0
    generate double nx = cos(2*_pi*(firmid-1)/6)
    generate double ny = sin(2*_pi*(firmid-1)/6)
    generate byte labelpos = cond(firmid==4,9,cond(inlist(firmid,5,6),6,12))
    save `layout'
    use `net', clear
    fegraph_gallery_links using `layout'
    * Fixed inset suffices for these small demonstration nodes.
    generate double dx = x2-x1
    generate double dy = y2-y1
    generate double d = sqrt(dx^2+dy^2)
    replace x1 = x1+.10*dx/d
    replace y1 = y1+.10*dy/d
    replace x2 = x2-.12*dx/d
    replace y2 = y2-.12*dy/d
    generate double lx = (x1+x2)/2
    generate double ly = (y1+y2)/2
    generate str6 countlabel = string(moves)
    local plots
    forvalues i=1/`=_N' {
        local width = .18+.10*moves[`i']
        local ec = cond(psi2[`i']>psi1[`i'],"18 121 128","191 86 55")
        local plots `"`plots' (pcarrow y1 x1 y2 x2 in `i', lcolor("`ec'%80") mcolor("`ec'") lwidth(`width') msize(2.4))"'
    }
    append using `layout'
    forvalues j=1/6 {
        quietly summarize employment if firmid==`j', meanonly
        local size = 3.5*sqrt(r(mean))
        local color : word `j' of `colors'
        local plots `"`plots' (scatter ny nx if firmid==`j', msize(`size') mfcolor("`color'") mlcolor(white) mlabel(label) mlabvposition(labelpos) mlabcolor(gs3) mlabsize(small))"'
    }
    twoway `plots' (scatter ly lx, msymbol(none) mlabel(countlabel) mlabcolor(gs5) mlabsize(vsmall)), ///
        title("A. Firm mobility network", size(medium)) ///
        subtitle("Net moves | fixed circular layout", size(small)) ///
        note("Numbers / widths: net move counts; node area: mean employment." ///
             "Node color: supplied effect, purple (low) to yellow (high)." ///
             "Arrow color: effect gain (teal) or loss (orange).", size(vsmall)) ///
        legend(off) xscale(off range(-1.5 1.5)) yscale(off range(-1.3 1.3)) ///
        xlabel(none) ylabel(none) xtitle("") ytitle("") aspect(1) ///
        graphregion(color(white)) plotregion(margin(medium)) ///
        xsize(7) ysize(6) name(fegraph_firm_concept, replace)
    graph export build/gallery/firm-network.png, width(1800) replace
    graph export build/gallery/firm-network.pdf, replace
    graph save build/gallery/firm-network.gph, replace

    * B. A declared selection of complete worker histories, binary match edges.
    use `panel', clear
    keep if inlist(workerid,1,3,5,7,8,9,12,13) & firmid>0
    keep workerid firmid
    duplicates drop
    save `links'
    keep workerid
    duplicates drop
    sort workerid
    generate double wx = 1+5*(_n-1)/(_N-1)
    generate double wy = 0
    generate str8 workerlabel = "w"+string(workerid)
    save `worker_nodes'
    use `links', clear
    merge m:1 workerid using `worker_nodes', assert(match) nogen
    generate double nx = firmid
    generate double ny = 1
    local plots "(pcspike wy wx ny nx, lcolor(gs12) lwidth(thin))"
    append using `worker_nodes'
    local plots `"`plots' (scatter wy wx if missing(firmid), mcolor(gs7) msize(2.4) mlabel(workerlabel) mlabposition(6) mlabsize(small) mlabcolor(gs4))"'
    save `links', replace
    use `nodes', clear
    keep if firmid>0
    generate double nx=firmid
    generate double ny=1
    append using `links'
    forvalues j=1/6 {
        local color : word `j' of `colors'
        local plots `"`plots' (scatter ny nx if firmid==`j' & !missing(employment), msize(7) mfcolor("`color'") mlcolor(white) mlabel(label) mlabposition(12) mlabsize(small) mlabcolor(gs3))"'
    }
    twoway `plots', ///
        title("B. Worker-firm matches", size(medium)) ///
        subtitle("Six firms | eight explicitly selected worker histories", size(small)) ///
        note("One edge per observed worker-firm match; repeated jobs collapsed." ///
             "Firm nodes are large; worker nodes are small. No flow direction." ///
             "Unemployment observations excluded from match edges.", size(vsmall)) ///
        legend(off) xscale(off range(.5 6.5)) yscale(off range(-.3 1.3)) ///
        xlabel(none) ylabel(none) xtitle("") ytitle("") ///
        graphregion(color(white)) plotregion(margin(medium)) ///
        xsize(9) ysize(5) name(fegraph_bipartite_concept, replace)
    graph export build/gallery/worker-firm.png, width(2100) replace
    graph export build/gallery/worker-firm.pdf, replace
    graph save build/gallery/worker-firm.gph, replace

    * C. Quantile curve, with a separate schematic band for unemployment.
    use `nodes', clear
    generate double nx = 100*(firmid-1)/5 if firmid>0
    generate double ny = psi
    replace nx = 50 if firmid==0
    replace ny = -.68 if firmid==0
    save `layout', replace
    use `gross', clear
    keep if origin==0 | destination==0
    append using `net'
    fegraph_gallery_links using `layout'
    * Scale-aware endpoint inset, not a general collision or clipping algorithm.
    generate double dx = (x2-x1)/100
    generate double dy = y2-y1
    generate double d = sqrt(dx^2+dy^2)
    replace x1 = x1+2*dx/d
    replace y1 = y1+.02*dy/d
    replace x2 = x2-3*dx/d
    replace y2 = y2-.03*dy/d
    * Illustrative Bezier paths keep longer moves off the quantile curve.
    generate int edgeid = _n
    local nedges = _N
    generate double cx = (x1+x2)/2
    generate double cy = (y1+y2)/2 + ///
        cond(origin>0 & destination>0,.12+.0015*abs(x2-x1),0)
    expand 31
    bysort edgeid: generate double q = (_n-1)/30
    generate double bx = (1-q)^2*x1+2*(1-q)*q*cx+q^2*x2
    generate double by = (1-q)^2*y1+2*(1-q)*q*cy+q^2*y2
    bysort edgeid (q): generate double ax = bx[_n-1]
    bysort edgeid (q): generate double ay = by[_n-1]
    local plots
    forvalues i=1/`nedges' {
        quietly summarize moves if edgeid==`i', meanonly
        local width = .18+.10*r(mean)
        quietly summarize origin if edgeid==`i', meanonly
        local oo = r(mean)
        quietly summarize destination if edgeid==`i', meanonly
        local dd = r(mean)
        local ec = cond(`oo'==0 | `dd'==0,"135 140 145", ///
            cond(`dd'>`oo',"18 121 128","191 86 55"))
        local plots `"`plots' (line by bx if edgeid==`i', cmissing(n) lcolor("`ec'%75") lwidth(`width')) (pcarrow ay ax by bx if edgeid==`i' & q==1, lcolor("`ec'") mcolor("`ec'") lwidth(`width') msize(2.2))"'
    }
    append using `layout'
    forvalues j=1/6 {
        local color : word `j' of `colors'
        quietly summarize employment if firmid==`j', meanonly
        local size = 3.5*sqrt(r(mean))
        local plots `"`plots' (scatter ny nx if firmid==`j', msize(`size') mfcolor("`color'") mlcolor(white) mlabel(label) mlabposition(12) mlabsize(small) mlabcolor(gs3))"'
    }
    twoway `plots' ///
        (scatter ny nx if firmid==0, msize(7) msymbol(D) mcolor(gs8) mlabel(label) mlabposition(6) mlabsize(small) mlabcolor(gs4)), ///
        title("C. A job ladder", size(medium)) ///
        subtitle("Net job-to-job moves | gross unemployment flows", size(small)) ///
        note("x: firm-weighted rank; y: supplied firm effect; widths: move counts." ///
             "Unemployment sits in a schematic band: no effect or rank is assigned." ///
             "Curves distinguish longer moves; coordinates and curvature are illustrative.", size(vsmall)) ///
        yline(-.48, lcolor(gs12) lpattern(dash)) ///
        text(-.53 5 "Outside state", placement(e) size(vsmall) color(gs8)) ///
        ylabel(-.3(.12).3, labsize(small) angle(horizontal) nogrid) ///
        xlabel(0(20)100, labsize(small)) ///
        xscale(range(-8 108)) yscale(range(-.85 .42)) ///
        xtitle("Firm percentile: low to high", size(small)) ///
        ytitle("Supplied firm effect", size(small)) legend(off) ///
        graphregion(color(white)) plotregion(margin(medium)) ///
        xsize(9) ysize(6) name(fegraph_ladder_concept, replace)
    graph export build/gallery/job-ladder.png, width(2100) replace
    graph export build/gallery/job-ladder.pdf, replace
    graph save build/gallery/job-ladder.gph, replace
    display as result "FEGRAPH_GALLERY_OK"
end

preserve
capture noisily fegraph_gallery_run
local rc = _rc
restore
capture program drop fegraph_gallery_run
capture program drop fegraph_gallery_links
if `rc' exit `rc'
