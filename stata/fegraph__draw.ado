*! fegraph 0.3.0 09oct2026
program define fegraph__draw
    version 16.0
    syntax , TYPE(string) EDGE(string) EDGECOLOR(string) EDGESIZE(string) STATISTIC(string) CMIN(real) CMAX(real) WMIN(real) WMAX(real) ///
        [NODESCALE(real 1) CATEGORIES(string) NET NOLABELS NODRAW NAME(string) GRAPHOPTS(string asis)]
    local sequential `""68 1 84" "68 57 131" "49 104 142" "33 145 140" "53 183 121" "144 215 67" "221 218 48""'
    local diverging `""166 54 3" "217 95 14" "253 174 107" "180 180 180" "128 205 193" "53 151 143" "1 102 94""'
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
                if "`net'"!="" local color : word `c' of `diverging'
                else local color : word `c' of `sequential'
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
            if "`edgecolor'"!="none" local color "170 170 170"
            if `c'>0 local color : word `c' of `diverging'
            forvalues s=1/4 {
                quietly count if ecolor==`c' & esize==`s'
                if !r(N) continue
                local width = .15 + .13*`s'
                if "`type'"=="bipartite" local width = .06 + .04*`s'
                local ++p
                local plots `"`plots' (line ey ex if ecolor==`c' & esize==`s', cmissing(n) lcolor("`color'%80") lwidth(`width'))"'
                quietly count if ecolor==`c' & esize==`s' & !missing(ax)
                if r(N) local ++p
                if r(N) local plots `"`plots' (pcarrow ay ax by bx if ecolor==`c' & esize==`s', lcolor("`color'") mcolor("`color'") msize(1.4) lwidth(`width'))"'
            }
        }
        forvalues k=0/2 {
            forvalues c=0/7 {
                local color "160 160 160"
                if `c'>0 local color : word `c' of `sequential'
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
                    local plots `"`plots' (scatter ny nx if nkind==`k' & ncolor==`c' & nsize==`s', msymbol(`symbol') msize(`size') mfcolor("`color'") mlcolor(white) mlwidth(thin) `labelopt')"'
                    if `addkey' local plots `"`plots' (scatter ny nx if 0, msymbol(O) msize(2) mfcolor("`color'") mlcolor(white))"'
                }
            }
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
