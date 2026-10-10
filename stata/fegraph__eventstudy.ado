*! fegraph 0.7.0 10oct2026
program define fegraph__eventstudy, rclass
    version 16.0
    syntax [varlist(default=none max=1 numeric)] [if] [in], _WORK(name) _MODEL(name) ///
        WORKER(varname) FIRM(varname) TIME(varname numeric) WAGE(varname numeric) ///
        [TYPE(string) ORDER(varname numeric) GROUP(varname numeric) BINS(string) BINWEIGHT(string) ///
        WINDOW(numlist integer min=2 max=2) DELTA(real 1) SAMPLE(string) ///
        NONEMPloyment(varname numeric) EFFECTGROUP(varname) POOLED DESCending ///
        NORMALize(string) FROMBins(numlist integer >0) TOBins(numlist integer >0) ///
        OVERLAY MINCELL(integer 1) CI CILEVEL(real 95) WAGESCALE(string) ///
        PALETTE(string asis) ANIMation(string asis) PROFILEFile(string) EVENTFile(string) ///
        SAVing(string) REPLACE NAME(string) NODRAW GRAPHOPTS(string asis)]
    if "`wagescale'"!="log" & "`wagescale'"!="level" {
        di as error "eventstudy requires wagescale(log|level); wage() is plotted as supplied"
        exit 198
    }
    if "`sample'"=="" local sample selected
    if !inlist("`sample'","selected","original") error 198
    if "`window'"=="" local window -2 1
    local pre : word 1 of `window'
    local post : word 2 of `window'
    local span = `post'-`pre'+1
    if `pre'>=0 | `post'<0 | `span'>101 | `delta'<=0 | missing(`delta') | ///
        `mincell'<1 | `cilevel'<=0 | `cilevel'>=100 error 198
    if "`normalize'"!="" {
        confirm integer number `normalize'
        if `normalize'<`pre' | `normalize'>`post' error 198
        local normalize = real("`normalize'")
    }
    if "`order'"!="" {
        if "`varlist'"!="" & "`varlist'"!="`order'" error 198
        local varlist `order'
    }
    if "`group'"!="" {
        if "`varlist'`bins'`binweight'`descending'"!="" {
            di as error "group() supplies endpoint groups; omit the score, bins(), binweight() and descending"
            exit 198
        }
        local bins_requested 0
        local grouping "Supplied endpoint groups"
    }
    else {
        if "`varlist'"=="" {
            di as error "eventstudy requires a positional firm score or group()"
            exit 198
        }
        if "`bins'"=="" local bins 4
        confirm integer number `bins'
        if `bins'<1 | `bins'>2000 error 198
        local bins_requested `bins'
        if "`binweight'"=="" local binweight firm
        if !inlist("`binweight'","firm","employment") error 198
        local grouping "Firm-score quantiles (`binweight' weighted)"
    }
    if `"`palette'"'=="" local palette viridis
    fegraph__palette `palette'
    local palette_name `"`r(name)'"'
    local palette_colors `"`r(colors)'"'
    if `"`animation'"'!="" {
        fegraph__animation `animation'
        foreach opt in filename mode theme replace title subtitle note notitle nosubtitle nonotes nolegend nocommand {
            local anim_`opt' `"`r(`opt')'"'
        }
        local anim_speed = r(speed)
        fegraph__rgb `palette_colors'
        local anim_palette `"`r(colors)'"'
        quietly findfile fegraph__eventviewer.html
        local anim_template `"`r(fn)'"'
    }
    foreach a in profilefile eventfile saving {
        if `"``a''"'!="" {
            local extension = cond("`a'"=="saving",".gph",".dta")
            if substr(lower(`"``a''"'),-4,.)!="`extension'" error 198
            if "`replace'"=="" confirm new file `"``a''"'
            foreach b in profilefile eventfile saving {
                if "`a'"!="`b'" & `"``a''"'==`"``b''"' error 198
            }
        }
    }
    marksample touse, novarlist
    local copyvars `worker' `firm' `time' `wage' `varlist' `group' `nonemployment' `effectgroup' `touse'
    local copyvars : list uniq copyvars
    if "`sample'"=="original" frame put `copyvars', into(`_work')
    else frame put `copyvars' if `touse', into(`_work')
    frame change `_work'
    quietly count
    if !r(N) error 2000
    local N_input = r(N)
    quietly count if missing(`worker') | missing(`time')
    if r(N) {
        di as error "worker() and time() cannot be missing"
        exit 459
    }
    isid `worker' `time'
    tempvar wid fid employed q refscore tag fmin fmax fw
    quietly egen long `wid' = group(`worker')
    quietly egen long `fid' = group(`firm')
    quietly generate byte `employed' = !missing(`firm')
    if "`nonemployment'"!="" {
        assert inlist(`nonemployment',0,1)
        quietly replace `employed'=0 if `nonemployment'==1
    }
    if "`effectgroup'"!="" & "`pooled'"=="" {
        tempvar eg
        quietly egen byte `eg'=tag(`effectgroup') if `touse' & `employed' & !missing(`effectgroup')
        quietly count if `eg'
        if r(N)>1 {
            di as error "multiple effectgroup() values; restrict to comparable effects or explicitly specify pooled"
            exit 459
        }
    }
    if "`group'"!="" {
        assert (`group'==floor(`group') & inrange(`group',1,2000)) | missing(`group') if `touse' & `employed'
        quietly generate int `q'=`group' if `touse' & `employed'
    }
    else {
        quietly generate double `refscore'=`varlist' if `touse' & `employed'
        quietly bysort `fid': egen double `fmin'=min(`refscore')
        quietly bysort `fid': egen double `fmax'=max(`refscore')
        quietly count if `fmin'!=`fmax' & `touse' & `employed'
        if r(N) {
            di as error "firm scores must be constant within firm; use group() for time-varying or coworker groups"
            exit 459
        }
        if "`descending'"!="" quietly replace `fmin'=-`fmin'
        quietly egen byte `tag'=tag(`fid') if `touse' & `employed' & !missing(`fmin')
        quietly count if `tag'
        if !r(N) error 2000
        quietly bysort `fid': egen double `fw'=total(`touse' & `employed')
        tempvar qtag
        if "`binweight'"=="firm" quietly replace `fw'=1
        sort `fmin' `fid'
        quietly generate int `qtag'=.
        // Shared quantile engine also handles more requested bins than firms.
        // It uses native Stata percentile cutpoints and never splits tied scores.
        fegraph__load
        mata: st_store(., st_local("qtag"), st_local("tag"), ///
            fegraph__quantiles(st_data(.,st_local("fmin"),st_local("tag")), ///
            st_data(.,st_local("fw"),st_local("tag")),strtoreal(st_local("bins"))))
        quietly bysort `fid': egen int `q'=max(`qtag')
        quietly replace `q'=. if !`touse' | !`employed'
    }
    quietly levelsof `q', local(allbins)
    local N_bins : word count `allbins'
    if !`N_bins' error 2000
    foreach opt in frombins tobins {
        foreach b of local `opt' {
            if !`: list b in allbins' {
                di as error "`opt'() includes a bin absent from the grouping population: `b'"
                exit 198
            }
        }
    }
    sort `wid' `time'
    tempvar candidate good validw og dg oldid newid workerid arrival eid
    quietly by `wid': generate byte `candidate'=_n>1 & `fid'!=`fid'[_n-1] & ///
        `employed' & `employed'[_n-1] & `touse' & `touse'[_n-1]
    quietly count if `candidate'
    local N_candidates=r(N)
    quietly generate byte `good'=`candidate'
    quietly generate byte `validw'=1
    quietly generate int `og'=`q'[_n-1]
    quietly generate int `dg'=`q'
    quietly clonevar `oldid'=`firm'
    quietly replace `oldid'=`firm'[_n-1]
    quietly clonevar `newid'=`firm'
    quietly clonevar `workerid'=`worker'
    quietly generate double `arrival'=`time'
    quietly generate long `eid'=sum(`candidate')
    local ys
    local j=0
    forvalues k=`pre'/`post' {
        tempvar yy
        local ys `ys' `yy'
        local ++j
        local whichfirm = cond(`k'<0,"`fid'[_n-1]","`fid'")
        quietly replace `good'=0 if `wid'[_n+(`k')]!=`wid' | ///
            missing(`time'[_n+(`k')]) | abs((`time'[_n+(`k')]-`time')/`delta'-(`k'))>1e-7 | ///
            !`employed'[_n+(`k')] | `fid'[_n+(`k')]!=`whichfirm' | `touse'[_n+(`k')]!=1
        quietly generate double `yy'=`wage'[_n+(`k')]
        quietly replace `validw'=0 if missing(`yy')
        if "`wagescale'"=="level" quietly replace `validw'=0 if `yy'<=0
        if "`normalize'"=="`k'" local baseline `yy'
    }
    quietly count if `candidate' & !`good'
    local N_excluded_window=r(N)
    quietly count if `good' & !`validw'
    local N_excluded_wage=r(N)
    quietly count if `good' & `validw' & missing(`og',`dg')
    local N_excluded_group=r(N)
    quietly keep if `good' & `validw' & !missing(`og',`dg')
    local N_events=_N
    if !`N_events' {
        di as error "no balanced mover events: `N_candidates' candidates; `N_excluded_window' window, `N_excluded_wage' wage, `N_excluded_group' group exclusions"
        exit 2000
    }
    if _N*`span'*(1+("`anim_mode'"=="time"))>2000000 {
        di as error "event export exceeds 2 million event-period rows; restrict the sample or window()"
        exit 198
    }
    if "`normalize'"!="" {
        tempvar basecopy
        quietly generate double `basecopy'=`baseline'
        foreach y of local ys {
            quietly replace `y'=`y'-`basecopy'
        }
    }
    keep `eid' `wid' `workerid' `oldid' `newid' `arrival' `og' `dg' `ys'
    rename (`eid' `wid' `workerid' `oldid' `newid' `arrival' `og' `dg') ///
        (event_id worker_index worker_id firm_origin firm_destination arrival origin_bin destination_bin)
    local j=0
    foreach y of local ys {
        local ++j
        rename `y' outcome`j'
    }
    quietly reshape long outcome, i(event_id) j(event_time)
    quietly replace event_time=event_time+`pre'-1
    label variable event_time "Periods from move (0 = first new-job period)"
    quietly generate byte selected=1
    if "`frombins'"!="" {
        quietly replace selected=0
        foreach b of local frombins {
            quietly replace selected=1 if origin_bin==`b'
        }
    }
    if "`tobins'"!="" {
        tempvar destination_selected
        quietly generate byte `destination_selected'=0
        foreach b of local tobins {
            quietly replace `destination_selected'=1 if destination_bin==`b'
        }
        quietly replace selected=selected & `destination_selected'
        drop `destination_selected'
    }
    quietly bysort origin_bin destination_bin: generate long cell_events=_N/`span'
    quietly generate byte shown=selected & cell_events>=`mincell'
    quietly count if shown & event_time==`pre'
    local N_shown_events=r(N)
    if !`N_shown_events' {
        di as error "no profiles pass frombins(), tobins() and mincell()"
        exit 2000
    }
    tempvar wtag ptag
    quietly egen byte `wtag'=tag(worker_index)
    quietly count if `wtag'
    local N_workers=r(N)
    drop `wtag'
    quietly egen byte `ptag'=tag(origin_bin destination_bin) if shown
    quietly count if `ptag'
    local N_paths=r(N)
    drop `ptag'
    quietly levelsof origin_bin if shown, local(origins)
    quietly levelsof destination_bin if shown, local(destinations)
    local npanels : word count `origins'
    if `N_paths'>64 | `npanels'>16 {
        di as error "more than 64 paths or 16 origin panels; select frombins()/tobins() or use fewer bins()"
        exit 198
    }
    sort event_id event_time
    if `"`eventfile'"'!="" quietly save `"`eventfile'"', `replace'
    quietly generate double cohort=.
    if "`anim_mode'"=="time" {
        tempvar duplicate
        quietly expand 2, generate(`duplicate')
        quietly replace cohort=arrival if `duplicate'
        drop `duplicate'
    }
    // Pointwise cluster SE of an event-weighted mean. Repeated events of a worker
    // contribute one cluster score, including after within-event normalization.
    local by cohort origin_bin destination_bin event_time
    tempvar mu score cs ctag square
    quietly bysort `by': egen double `mu'=mean(outcome)
    quietly generate double `score'=outcome-`mu'
    quietly bysort `by' worker_index: egen double `cs'=total(`score')
    quietly egen byte `ctag'=tag(`by' worker_index), missing
    quietly generate double `square'=`cs'^2 if `ctag'
    quietly collapse (mean) mean=outcome (count) n_events=outcome ///
        (sum) n_workers=`ctag' ss=`square' (max) selected, by(`by')
    quietly generate double se=sqrt(n_workers/(n_workers-1)*ss/n_events^2) if n_workers>1
    quietly generate double lower=mean-invttail(n_workers-1,(100-`cilevel')/200)*se if n_workers>1
    quietly generate double upper=mean+invttail(n_workers-1,(100-`cilevel')/200)*se if n_workers>1
    quietly generate byte shown=selected & n_events>=`mincell'
    drop ss selected
    order cohort origin_bin destination_bin event_time mean se lower upper n_events n_workers shown
    sort cohort origin_bin destination_bin event_time
    local ytitle = cond("`wagescale'"=="log","Mean log wage","Mean wage")
    if "`normalize'"!="" local ytitle "Mean change from period `normalize'"
    local title "Mover wage profiles"
    local subtitle "`grouping'; balanced window `pre' to `post'"
    local count_note "`N_shown_events' of `N_events' balanced events shown; `N_workers' workers in full event sample."
    local method_note "Descriptive means."
    if "`ci'"!="" local method_note "`method_note' `cilevel'% pointwise intervals clustered by worker."
    local note "`count_note' `method_note'"
    if `"`profilefile'"'!="" quietly save `"`profilefile'"', `replace'
    if `"`animation'"'!="" {
        fegraph__load
        capture mata: mata drop fegraph__eventhtml()
        quietly findfile fegraph__eventhtml.mata
        quietly do `"`r(fn)'"'
        tempfile htmlstage
        mata: fegraph__eventhtml(st_local("htmlstage"))
        quietly copy `"`htmlstage'"' `"`anim_filename'"', `anim_replace'
    }
    quietly keep if missing(cohort) & shown
    tempname originlabels
    foreach o of local origins {
        label define `originlabels' `o' "Origin group `o'", add
    }
    label values origin_bin `originlabels'
    local plots
    local legend
    local counter=0
    local colorindex=0
    foreach d of local destinations {
        local ++colorindex
        local nd : word count `destinations'
        local c=cond(`nd'==1,4,1+round(6*(`colorindex'-1)/(`nd'-1)))
        local color : word `c' of `palette_colors'
        local lines solid dash dot dash_dot longdash shortdash
        local oi=0
        local draworigins 0
        if "`overlay'"!="" local draworigins `origins'
        foreach o of local draworigins {
            local ++oi
            local filter "destination_bin==`d'"
            local label "Destination `d'"
            local pattern solid
            if "`overlay'"!="" {
                local filter "`filter' & origin_bin==`o'"
                local label "`o' to `d'"
                local pi=1+mod(`oi'-1,6)
                local pattern : word `pi' of `lines'
            }
            quietly count if `filter'
            if !r(N) continue
            if "`ci'"!="" {
                local plots `"`plots' (rcap lower upper event_time if `filter', lcolor("`color'"%40))"'
                local ++counter
            }
            local plots `"`plots' (connected mean event_time if `filter', sort lcolor("`color'") mcolor("`color'") msymbol(O) msize(small) lpattern(`pattern'))"'
            local ++counter
            local legend `"`legend' `counter' "`label'""'
        }
    }
    local options `"title("`title'", size(medium)) subtitle("`subtitle'", size(small)) note("`count_note'" "`method_note'", size(vsmall))"'
    if "`overlay'"=="" {
        // Route ordinary annotation overrides to the overall by-graph.
        // Repeated title()/note() options retain native graph merge semantics.
        forvalues pass=1/100 {
            _get_gropts, graphopts(`graphopts') getallowed(TItle SUBTitle NOTE)
            local extra
            foreach a in title subtitle note {
                if `"`s(`a')'"'!="" local extra `"`extra' `a'(`s(`a')')"'
            }
            local graphopts `"`s(graphopts)'"'
            if `"`extra'"'=="" continue, break
            local options `"`options' `extra'"'
        }
        local columns=cond(`npanels'==1,1,2)
        local options `"by(origin_bin, cols(`columns') legend(position(6)) `options')"'
    }
    if "`name'"=="" local name "fegraph, replace"
    if "`name'"!="" local options `"`options' name(`name')"'
    twoway `plots', `options' xlabel(`pre'(1)`post') xline(-.5, lcolor(gs12) lpattern(dash)) ///
        xtitle("Periods from move (0 = first new-job period)") ytitle("`ytitle'") ///
        legend(order(`legend') cols(2) size(small)) `nodraw' `graphopts'
    if `"`saving'"'!="" graph save `"`saving'"', `replace'
    foreach field in N_input N_candidates N_excluded_window N_excluded_wage N_excluded_group N_events N_shown_events N_workers N_bins N_paths bins_requested {
        return scalar `field'=``field''
    }
    return scalar window_start=`pre'
    return scalar window_end=`post'
    return scalar delta=`delta'
    return local type eventstudy
    return local version "0.7.0"
    return local score "`varlist'"
    return local group "`group'"
    return local palette `"`palette_name'"'
    return local palette_colors `"`palette_colors'"'
    return local sample "`sample'"
    return local input "panel"
    if `"`animation'"'!="" {
        return local animation `"`anim_filename'"'
        return local animation_mode "`anim_mode'"
        return scalar N_frames=`anim_frames'
        di as text "HTML animation: " as result `"`anim_filename'"'
    }
    di as text "fegraph: " as result `N_shown_events' as text " / " as result `N_events' ///
        as text " balanced mover events shown in " as result `N_paths' as text " profiles."
end
