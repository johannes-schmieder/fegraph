*! fegraph 0.4.0 09oct2026
program define fegraph, rclass
    version 16.0
    // Options-only graph calls are valid; reserve only valid metadata calls.
    if substr(strtrim(`"`0'"'),1,1)=="," {
        capture syntax , [VERSION SELFTEST]
        if !_rc {
            if ("`version'"!="")+("`selftest'"!="")!=1 error 198
            if "`selftest'"!="" {
                quietly fegraph_example, nodraw
                assert r(flow_total)==40
                return scalar passed=1
                di as result "fegraph selftest passed"
            }
            else di as text "fegraph 0.4.0"
            return local version "0.4.0"
            exit
        }
    }
    tempname work model
    local caller "`c(frame)'"
    capture noisily fegraph__run `0' _work(`work') _model(`model')
    local rc = _rc
    if !`rc' return add
    quietly frame change `caller'
    capture frame drop `work'
    capture mata: mata drop `model'
    if `rc' exit `rc'
end

program define fegraph__run, rclass
    version 16.0
    syntax [varlist(default=none max=2)] [if] [in], _WORK(name) _MODEL(name) ///
        [WORKER(varname) FIRM(varname) ORIGIN(varname) DESTination(varname) ///
        TIME(varname numeric) FLOW(varname numeric) ///
        TYPE(string) STYLE(string) LABELTOP(integer -1) EDGE(string) NET MAXGAP(real 1) SAMPLE(string) ///
        CATEGORICAL NODEColor(varlist numeric) NODESize(string) ORDER(varlist numeric) ///
        LEVEL(varlist numeric) LABEL(varlist) WORKERCOLOR(varname numeric) ///
        EFFECTGROUP(varlist) POOLed NONEMPloyment(varname numeric) ///
        OUTSIDE(string) OUTSIDELABEL(string) WAGE(varname numeric) WAGESCALE(string) ///
        EDGECOLOR(string) EDGESIZE(string) STATistic(string) EXPOSURE(varname numeric) ///
        COMPONENT(string) EGO(string) STEPS(integer 1) MINFLOW(real 0) TOP(integer 0) ///
        BINS(integer 0) BINWEIGHT(string) DESCending LAYOUT(string) ///
        SEED(integer 1) ITERations(integer 200) MAXNodes(integer 200) MAXEdges(integer 1000) ///
        COORDinates(string) NODEFile(string) EDGEFile(string) MAPFile(string) ///
        SAVing(string) COLORLIMITS(numlist min=2 max=2) EDGELIMITS(numlist min=2 max=2) ///
        SIZEMAX(real 0) WIDTHMAX(real 0) NODESCALE(string) REPLACE NAME(string) NOLABELS NODRAW GRAPHOPTS(string asis)]
    foreach opt in type style edge sample edgecolor edgesize statistic component binweight layout wagescale {
        local `opt' = lower(strtrim(`"``opt''"'))
    }
    if "`type'"=="" local type firmgraph
    if "`type'"=="firm" local type firmgraph // compatibility alias
    if "`style'"=="" local style default
    if "`style'"=="classic" & `labeltop'==-1 local labeltop 15
    if !inlist("`style'","default","classic") | `labeltop'<-1 {
        di as error "style() must be default or classic; labeltop() must be nonnegative"
        exit 198
    }
    if "`type'"!="firmgraph" & ("`style'"=="classic" | `labeltop'>=0) {
        di as error "style(classic) and labeltop() apply to type(firmgraph)"
        exit 198
    }
    if "`edge'"=="" local edge moves
    if "`sample'"=="" local sample selected
    if "`edgecolor'"=="" local edgecolor none
    if "`edgesize'"=="" local edgesize flow
    if "`statistic'"=="" local statistic count
    if "`component'"=="" local component all
    if "`binweight'"=="" local binweight firm
    if "`outsidelabel'"=="" local outsidelabel Nonemployment
    if "`layout'"=="" local layout = cond("`type'"=="bipartite","bipartite","force")
    if !inlist("`type'","firmgraph","bipartite","ladder","heatmap") | ///
        !inlist("`edge'","moves","shared") | !inlist("`sample'","selected","original") | ///
        !inlist("`statistic'","count","share","probability") | ///
        !inlist("`edgecolor'","none","effect","wage") | ///
        !inlist("`edgesize'","flow","effect","wage") | ///
        !inlist("`binweight'","firm","employment") | ///
        !inlist("`layout'","force","circle","bipartite") {
        di as error "invalid graph, edge, sample, statistic, style, binweight or layout choice; see help fegraph"
        exit 198
    }
    if `maxgap'<=0 | missing(`maxgap') | `minflow'<0 | missing(`minflow') | ///
        `bins'<0 | `bins'>2000 | `top'<0 | `steps'<1 | `iterations'<1 | `iterations'>2000 | ///
        `maxnodes'<1 | `maxnodes'>2000 | `maxedges'<1 | `maxedges'>20000 {
        di as error "invalid numerical control; bins()/maxnodes() <= 2000 and maxedges() <= 20000"
        exit 198
    }
    if "`nodescale'"=="" local nodescale = cond("`style'"=="classic",.35,1)
    capture confirm number `nodescale'
    if _rc {
        di as error "nodescale() requires a number"
        exit 198
    }
    if `nodescale'<=0 | `nodescale'>5 | missing(`nodescale') {
        di as error "nodescale() must be positive and at most 5"
        exit 198
    }
    if `sizemax'<0 | missing(`sizemax') | `widthmax'<0 | missing(`widthmax') error 198
    foreach opt in colorlimits edgelimits {
        if "``opt''"!="" {
            local low : word 1 of ``opt''
            local high : word 2 of ``opt''
            if `low'>=`high' | missing(`low',`high') {
                di as error "`opt'() requires two finite increasing limits"
                exit 198
            }
        }
    }
    if "`categorical'"!="" & "`colorlimits'"!="" {
        di as error "categorical colors cannot use colorlimits()"
        exit 198
    }
    if "`categorical'"!="" & `bins'>0 {
        di as error "categorical colors require unbinned firms; bin averages have no category interpretation"
        exit 198
    }
    if "`edgelimits'"!="" {
        local low : word 1 of `edgelimits'
        local high : word 2 of `edgelimits'
        if abs(`low'+`high')>1e-12 | `high'<=0 {
            di as error "edgelimits() must be symmetric around zero"
            exit 198
        }
    }
    // Normalize the public score/ID interface for the data engine.
    local firmscore `varlist'
    local nscore : word count `firmscore'
    if "`firm'`worker'"!="" & "`origin'`destination'"!="" {
        di as error "choose worker()/firm() panel input or origin()/destination() flow input"
        exit 198
    }
    if "`firm'"!="" {
        if "`worker'"=="" {
            di as error "panel input requires worker() and firm()"
            exit 198
        }
        local panel 1
        local varlist `firm'
        local nvar 1
    }
    else if "`origin'`destination'"!="" {
        if "`origin'"=="" | "`destination'"=="" {
            di as error "prepared flows require both origin() and destination()"
            exit 198
        }
        local panel 0
        local varlist `origin' `destination'
        local nvar 2
    }
    else {
        di as error "fegraph 0.2: put IDs in worker()/firm(), or origin()/destination(); positional variables now supply firm scores"
        exit 198
    }
    if `nscore'>0 & `nscore'!=`nvar' {
        di as error "supply one positional firm score for panels, or two endpoint scores for prepared flows"
        exit 198
    }
    if `nscore'>0 {
        confirm numeric variable `firmscore'
        if "`order'"!="" & "`order'"!="`firmscore'" {
            di as error "positional scores and order() conflict; specify one ordering"
            exit 198
        }
        local order `firmscore'
    }
    local firmscore `order'
    if "`firmscore'"!="" {
        if "`nodecolor'"=="" & "`type'"!="heatmap" local nodecolor `firmscore'
        if "`level'"=="" local level `firmscore'
    }
    local actualbins 0
    if `panel' & "`time'"=="" & "`type'"!="bipartite" & "`edge'"!="shared" {
        di as error "directed panel flows require time()"
        exit 198
    }
    if (`panel' & "`flow'`exposure'`outside'"!="") | ///
       (!`panel' & "`worker'`time'`nonemployment'`workercolor'`wage'"!="") {
        di as error "panel and prepared-flow options cannot be mixed"
        exit 198
    }
    if !`panel' & ("`type'"=="bipartite" | "`edge'"=="shared") {
        di as error "bipartite and shared-worker views require worker-firm records"
        exit 198
    }
    if ("`type'"=="bipartite" | "`edge'"=="shared") & ///
       ("`net'"!="" | "`statistic'"!="count" | "`edgecolor'"!="none" | "`edgesize'"!="flow") {
        di as error "match graphs use undirected counts, without wage/effect edge statistics"
        exit 198
    }
    if "`net'"!="" & ("`statistic'"!="count" | "`edgecolor'"=="wage" | "`edgesize'"=="wage") {
        di as error "net flows require statistic(count); mover wage statistics apply to gross flows"
        exit 198
    }
    if inlist("wage","`edgecolor'","`edgesize'") & "`wage'"=="" {
        di as error "wage edge styling requires wage() and wagescale(log|level)"
        exit 198
    }
    if "`wage'"!="" & !inlist("`wagescale'","log","level") {
        di as error "wage() requires explicit wagescale(log|level)"
        exit 198
    }
    if "`statistic'"=="probability" & !`panel' & "`exposure'"=="" {
        di as error "prepared-flow probabilities require exposure(): full origin exposure"
        exit 198
    }
    if `bins'>0 & !inlist("`type'","ladder","heatmap") {
        di as error "bins() is available for ladder and heatmap"
        exit 198
    }
    if "`type'"=="ladder" & "`order'"=="" {
        di as error "ladder requires a firm score before the comma or in order()"
        exit 198
    }
    if `bins'>0 & "`order'"=="" {
        di as error "bins() requires a firm score before the comma or in order()"
        exit 198
    }
    if "`type'"=="ladder" & "`level'"=="" local level `order'
    if "`categorical'"!="" & inlist("effect","`edgecolor'","`edgesize'") & "`level'"=="" {
        di as error "effect edge styling with categorical node colors requires level()"
        exit 198
    }
    if "`workercolor'"!="" & "`type'"!="bipartite" {
        di as error "workercolor() applies only to bipartite graphs"
        exit 198
    }
    if "`layout'"=="bipartite" & "`type'"!="bipartite" {
        di as error "layout(bipartite) requires type(bipartite)"
        exit 198
    }
    foreach opt in nodecolor order level label effectgroup {
        local n : word count ``opt''
        if `n'>0 & `n'!=`nvar' {
            di as error "`opt'() takes one variable in panel mode, or two: origin then destination"
            exit 198
        }
    }
    if "`nodesize'"=="" local nodesize = cond(`panel',"employment","flow")
    if !inlist("`nodesize'","employment","flow","equal","matches") {
        confirm numeric variable `nodesize'
        local n : word count `nodesize'
        if `n'!=`nvar' {
            di as error "nodesize() requires one panel or two endpoint variables"
            exit 198
        }
        local sizevars `nodesize'
    }
    if !`panel' & inlist("`nodesize'","employment","matches") {
        di as error "prepared flows require supplied size variables, nodesize(flow), or nodesize(equal)"
        exit 198
    }
    if `panel' & "`nodesize'"=="employment" & "`time'"=="" local nodesize matches
    if inlist("effect","`edgecolor'","`edgesize'") & "`level'`nodecolor'"=="" {
        di as error "effect edge styling requires level() or nodecolor()"
        exit 198
    }
    if "`type'"=="heatmap" & ("`edgecolor'"!="none" | "`edgesize'"!="flow") {
        di as error "heatmap color represents statistic(); edge styling is for network views"
        exit 198
    }
    if "`component'"!="all" & "`component'"!="largest" {
        confirm integer number `component'
        if `component'<1 error 198
    }
    foreach a in nodefile edgefile mapfile {
        if `"``a''"'!="" & substr(lower(`"``a''"'),-4,.)!=".dta" {
            di as error "`a'() requires a .dta filename"
            exit 198
        }
    }
    if `"`saving'"'!="" & substr(lower(`"`saving'"'),-4,.)!=".gph" {
        di as error "saving() requires a .gph filename; use graph export for PNG, SVG or PDF"
        exit 198
    }
    foreach a in nodefile edgefile mapfile saving {
        if `"``a''"'!="" & "`replace'"=="" confirm new file `"``a''"'
        foreach b in nodefile edgefile mapfile saving {
            if "`a'"!="`b'" & `"``a''"'!="" & `"``a''"'==`"``b''"' {
                di as error "output filenames must be distinct"
                exit 198
            }
        }
    }
    marksample touse, novarlist
    quietly count if `touse'
    if !r(N) error 2000
    local copyvars `varlist' `worker' `time' `flow' `nodecolor' `sizevars' `order' `level' ///
        `label' `effectgroup' `nonemployment' `wage' `exposure' `workercolor' `touse'
    local copyvars : list uniq copyvars
    if "`sample'"=="original" & `panel' frame put `copyvars', into(`_work')
    else frame put `copyvars' if `touse', into(`_work')
    frame change `_work'
    fegraph__load
    mata: `_model' = fegraph__new()
    mata: fegraph__build(`_model')
    if `"`coordinates'"'!="" {
        use `"`coordinates'"', clear
        confirm variable id kind x y
        mata: fegraph__coordinates(`_model')
    }
    tempname summary
    mata: st_matrix("`summary'", `_model'.stats)
    matrix colnames `summary' = N_input N_workers N_firms N_matches N_eligible N_gaps N_unknown ///
        N_components N_nodes N_edges N_shown_nodes N_shown_edges flow_total flow_shown ///
        flow_boundary flow_within flow_hidden_net N_missing_color
    quietly clear
    mata: fegraph__plot(`_model')
    local autoopts `"note("`scale_note'" "`edge_note'" "`coverage_note'", size(vsmall))"'
    if "`type'"=="heatmap" local autoopts `"`autoopts' xlabel(`heatlabels', angle(45) labsize(vsmall)) ylabel(`heatlabels', labsize(vsmall) angle(horizontal)) xscale(range(.5 `heatmax')) yscale(range(.5 `heatmax'))"'
    if "`outside_line'"!="" local autoopts `"`autoopts' yline(`outside_line', lpattern(dash) lcolor(gs12))"'
    if "`ladderlabels'"!="" local autoopts `"`autoopts' ylabel(`ladderlabels', angle(horizontal) format(%5.2g))"'
    fegraph__draw, type(`type') style(`style') edge(`edge') `net' `nolabels' `nodraw' ///
        edgecolor(`edgecolor') edgesize(`edgesize') statistic(`statistic') ///
        nodescale(`nodescale') cmin(`colormin') cmax(`colormax') wmin(`workermin') wmax(`workermax') categories(`categories') name(`name') graphopts(`autoopts' `graphopts')
    if `"`saving'"'!="" graph save `"`saving'"', `replace'
    if `"`nodefile'"'!="" {
        quietly clear
        mata: fegraph__nodes(`_model')
        quietly save `"`nodefile'"', `replace'
    }
    if `"`edgefile'"'!="" {
        quietly clear
        mata: fegraph__edges(`_model')
        quietly save `"`edgefile'"', `replace'
    }
    if `"`mapfile'"'!="" {
        quietly clear
        mata: fegraph__mapping(`_model')
        quietly save `"`mapfile'"', `replace'
    }
    forvalues k=1/18 {
        local fields N_input N_workers N_firms N_matches N_eligible N_gaps N_unknown ///
            N_components N_nodes N_edges N_shown_nodes N_shown_edges flow_total flow_shown ///
            flow_boundary flow_within flow_hidden_net N_missing_color
        local field : word `k' of `fields'
        return scalar `field' = el(`summary',1,`k')
    }
    return scalar N_bins = `actualbins'
    return scalar bins_requested = `bins'
    return local score "`firmscore'"
    if `bins'>0 di as text "Quantile bins: " as result `actualbins' as text " nonempty / " as result `bins' as text " requested"
    return local style "`style'"
    return local type "`type'"
    return local input = cond(`panel',"panel","edge")
    return local version "0.4.0"
    return local sample "`sample'"
    di as text "fegraph: " as result el(`summary',1,11) as text " nodes; " ///
        as result el(`summary',1,12) as text " edges shown. Gross flow coverage: " ///
        as result el(`summary',1,14) as text " / " as result el(`summary',1,13)
    return matrix summary = `summary'
end
