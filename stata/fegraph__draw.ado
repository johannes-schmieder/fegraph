*! fegraph 0.6.1 10oct2026
program define fegraph__draw
    version 16.0
    syntax , TYPE(string) EDGE(string) EDGECOLOR(string) EDGESIZE(string) STATISTIC(string) CMIN(real) CMAX(real) WMIN(real) WMAX(real) ///
        [STYLE(string) PALETTE(string asis) EDGEPALETTE(string asis) NODESCALE(real 1) CATEGORIES(string) NET NOLABELS NODRAW NAME(string) GRAPHOPTS(string asis)]
    // Mata writes rendering metadata into the caller's locals; retrieve via c_local in wrapper.
    local plots
    local p 0
    local keys
    local seen
    local wseen
    if "`type'"=="heatmap" {
        forvalues c=0/7 {
            quietly count if hcolor==`c'
            if !r(N) continue
            local color "245 245 245"
            if `c'>0 {
                local color : word `c' of `palette'
            }
            local ++p
            local text "0 / hidden"
            if `c'>0 {
                local lo = `cmin'+(`c'-1)*(`cmax'-`cmin')/7
                local hi = `cmin'+`c'*(`cmax'-`cmin')/7
                local text : display %6.3g `lo' " to " %6.3g `hi'
            }
            local keys `"`keys' `p' "`text'""'
            local plots `"`plots' (rbar hlo hhi hx if hcolor==`c', barwidth(.96) fcolor("`color'") lcolor(white) lwidth(vthin))"'
        }
        local axes "xtitle(Destination) ytitle(Origin) aspect(1)"
        local title "Worker flows"
    }
    else {
        forvalues c=0/7 {
            local color "70 135 140"
            if "`style'"=="classic" local color "125 125 125"
            if "`edgecolor'"!="none" local color "170 170 170"
            if `c'>0 local color : word `c' of `edgepalette'
            forvalues s=1/4 {
                quietly count if ecolor==`c' & esize==`s'
                if !r(N) continue
                local width = .15 + .13*`s'
                if "`type'"=="bipartite" local width = .06 + .04*`s'
                local opacity 80
                local arrowsize 1.4
                if "`style'"=="classic" {
                    local width = .035 + .045*`s'
                    local opacity 65
                    local arrowsize 1.1
                }
                local ++p
                local plots `"`plots' (line ey ex if ecolor==`c' & esize==`s', cmissing(n) lcolor("`color'%`opacity'") lwidth(`width'))"'
                quietly count if ecolor==`c' & esize==`s' & !missing(ax)
                if r(N) local ++p
                if r(N) local plots `"`plots' (pcarrow ay ax by bx if ecolor==`c' & esize==`s', lcolor("`color'") mcolor("`color'") msize(`arrowsize') lwidth(`width'))"'
            }
        }
        forvalues k=0/2 {
            forvalues c=0/7 {
                local color "160 160 160"
                if "`style'"=="classic" local color "110 110 110"
                if `c'>0 local color : word `c' of `palette'
                local symbol O
                if `k'==2 local symbol D
                forvalues s=1/4 {
                    quietly count if nkind==`k' & ncolor==`c' & nsize==`s'
                    if !r(N) continue
                    local size = 2*`s'*`nodescale'
                    if `k'==1 local size = 1.8*`nodescale'
                    local labelopt
                    if "`nolabels'"=="" local labelopt "mlabel(nlabel) mlabsize(vsmall) mlabcolor(gs4) mlabposition(12)"
                    if `k'==1 & "`nolabels'"=="" local labelopt "mlabel(nlabel) mlabsize(vsmall) mlabcolor(gs4) mlabposition(6)"
                    local ++p
                    local addkey 0
                    if `k'==0 & `c'>0 & !strpos(" `seen' "," `c' ") & `cmin'<. {
                        local lo = `cmin'+(`c'-1)*(`cmax'-`cmin')/7
                        local hi = `cmin'+`c'*(`cmax'-`cmin')/7
                        local text : display %6.3g `lo' " to " %6.3g `hi'
                        if `"`categories'"'!="" local text : word `c' of `categories'
                        local ++p
                        local addkey 1
                        local keys `"`keys' `p' "`text'""'
                        local seen "`seen' `c'"
                    }
                    if `k'==1 & `c'>0 & !strpos(" `wseen' "," `c' ") & `wmin'<. {
                        local lo = `wmin'+(`c'-1)*(`wmax'-`wmin')/7
                        local hi = `wmin'+`c'*(`wmax'-`wmin')/7
                        local text : display "Worker " %6.3g `lo' " to " %6.3g `hi'
                        local ++p
                        local addkey 1
                        local keys `"`keys' `p' "`text'""'
                        local wseen "`wseen' `c'"
                    }
                    if `k'==2 & "`nolabels'"=="" local labelopt "mlabel(nlabel) mlabsize(vsmall) mlabcolor(gs4) mlabposition(6)"
                    if "`style'"=="classic" local labelopt
                    local plots `"`plots' (scatter ny nx if nkind==`k' & ncolor==`c' & nsize==`s', msymbol(`symbol') msize(`size') mfcolor("`color'") mlcolor(white) mlwidth(thin) `labelopt')"'
                    if `addkey' local plots `"`plots' (scatter ny nx if 0, msymbol(O) msize(2) mfcolor("`color'") mlcolor(white))"'
                }
            }
        }
        if "`style'"=="classic" & "`nolabels'"=="" {
            local ++p
            local plots `"`plots' (scatter ny nx if !missing(nkind), msymbol(i) mlabel(nlabel) mlabsize(tiny) mlabcolor(gs4) mlabvposition(nlabelpos) mlabgap(1))"'
        }
        local axes "xscale(off) yscale(off) xlabel(none) ylabel(none) xtitle( ) ytitle( ) aspect(1)"
        local title "Firm network"
        if "`type'"=="bipartite" {
            local title "Worker-firm matches"
            local axes "xscale(off) yscale(off) xlabel(none) ylabel(none) xtitle( ) ytitle( ) aspect(.55)"
        }
        if "`type'"=="ladder" {
            local axes `"xtitle("Firm percentile: low to high") ytitle("Supplied level") ylabel(, angle(horizontal))"'
            local title "Job ladder"
        }
    }
    if `"`plots'"'=="" {
        di as error "no drawable nodes or cells"
        exit 2000
    }
    local nameopt
    if `"`name'"'!="" local nameopt "name(`name')"
    local legendopt legend(off)
    if `"`keys'"'!="" local legendopt `"legend(order(`keys') position(6) ring(1) cols(3) size(vsmall) symxsize(3) symysize(2) forcesize region(lstyle(none)))"'
    local subtitle = cond("`net'"!="","Net flows","Gross flows")
    if "`edge'"=="shared" local subtitle "Shared-worker connections"
    if "`type'"=="bipartite" local subtitle "Distinct worker-firm matches"
    twoway `plots', title("`title'") subtitle("`subtitle'", size(small)) `legendopt'  `axes' ///
        graphregion(color(white)) plotregion(margin(large)) ///
        `nameopt' `nodraw' `graphopts'
end
