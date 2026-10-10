*! fegraph 0.6.0 09oct2026
*! Optional reproducible teaching reports; graph runtime has no dependencies.
program define fegraph_report, rclass
    version 19.0
    syntax , OUTDIR(string) [DGP(string) REPLACE VIEW]
    if "`dgp'"=="" local dgp all
    if !inlist("`dgp'","all","akm","ladder","bm") error 198
    foreach command in fesim fereg ferank latexlog texpdf {
        capture which `command'
        if _rc {
            di as error "fegraph_report requires `command'; see help fegraph, Reports."
            exit 499
        }
    }
    capture mkdir `"`outdir'"'
    if "`replace'"=="" {
        confirm new file `"`outdir'/report.tex"'
        confirm new file `"`outdir'/report.pdf"'
        foreach model in akm ladder bm {
            foreach figure in firmgraph bipartite ladder manybins heatmap rank {
                confirm new file `"`outdir'/`model'-`figure'.pdf"'
            }
        }
    }
    tempname previous
    _estimates hold `previous', restore nullok
    local caller_dir `"`c(pwd)'"'
    quietly cd `"`outdir'"'
    preserve
    capture noisily fegraph_report_build, outdir(".") dgp(`dgp') `view'
    local rc = _rc
    restore
    quietly cd `"`caller_dir'"'
    _estimates unhold `previous'
    if `rc' exit `rc'
    return local pdf `"`outdir'/report.pdf"'
    return local tex `"`outdir'/report.tex"'
end

program define fegraph_report_build
    version 19.0
    syntax , OUTDIR(string) DGP(string) [VIEW]
    local report `"`outdir'/report.tex"'
    local models `dgp'
    if "`dgp'"=="all" local models akm ladder bm
    latexlog `report': open, replace ///
        geometry(lmargin=2cm,rmargin=2cm,tmargin=2cm,bmargin=2cm)
    latexlog `report': title "fegraph: labor-market mobility"
    latexlog `report': writeln "\noindent Simulation, estimation, ranking and visualization in Stata."
    latexlog `report': section "How to read this report"
    latexlog `report': writeln "Each model uses 6,000 workers, 80 firms and 12 annual snapshots. The models are illustrative, not empirical calibrations. The workflow is \texttt{fesim} $\rightarrow$ \texttt{fereg} $\rightarrow$ \texttt{ferank} $\rightarrow$ \texttt{fegraph}; \texttt{latexlog} writes this document and \texttt{texpdf} compiles it."
    latexlog `report': writeln "\par\medskip Firm wage effects come from a two-way worker--firm regression. Effects are centered over distinct firms; only comparisons within the connected sample are meaningful. Bradley--Terry scores use observed firm-to-firm moves. Neither estimator uses the simulation's latent truth."
    latexlog `report': writeln "\par\medskip For each model: a firm network, a small worker--firm match graph, a ten-bin wage ladder, a fifty-bin wage ladder, a flow heatmap, and a ladder ordered by the estimated mobility score. Quantiles weight firms equally and keep ties together. Heights are bin means."
    latexlog `report': writeln "\par\medskip Arrows follow adjacent observed states, not every continuous-time event. Unemployment is an explicit schematic node, excluded from score quantiles. It appears in the network, ten-bin wage ladder and heatmap; the match graph contains jobs only. The fifty-bin and mobility-score ladders isolate firm-to-firm moves."
    latexlog `report': writeln "\par\medskip Large ladders use smaller nodes, no labels and a limited set of arrows. Coverage captions disclose omitted flow mass. A fifty-bin ladder is a detailed summary; the heatmap is better for inspecting a dense set of connections. Curves have no economic interpretation."
    foreach model of local models {
        local title "AKM: exogenous mobility"
        local modelopts "dgp(akm) preset(simple) parameters(p_ee .25 firm_size_sd .3)"
        local description "Additive worker and firm wage effects with exogenous employer changes. Firm-flow rankings need not recover wage premiums: mobility is not driven by wages in this baseline."
        local masterseed 10401
        if "`model'"=="ladder" {
            local title "Job ladder: upward-biased mobility"
            local modelopts "dgp(akm) preset(simple) network(ladder) parameters(p_ee .25 firm_size_sd .3)"
            local description "AKM wages with a reduced-form ladder destination rule: default downward, lateral and upward shares are 0.10, 0.20 and 0.70, renormalized when a direction is unavailable. This is not an equilibrium search model."
            local masterseed 10402
        }
        if "`model'"=="bm" {
            local title "Burdett--Mortensen: wage posting"
            local modelopts "dgp(bm) preset(simple)"
            local description "Homogeneous workers and common productivity with wage posting. Employed workers accept strictly higher offers. Defaults are b=0.4, p=1, lambda-u=1, lambda-e=0.5, delta=0.2 and r=0.05. Downward annual endpoint moves can follow an unobserved unemployment spell; they do not imply downward accepted on-the-job offers. The AKM fit is a descriptive decomposition here."
            local masterseed 10403
        }
        fesim, `modelopts' workers(6000) firms(80) periods(12) ///
            seed(`masterseed') truth(basic) noreport clear
        generate byte unemployed = !employed
        fereg lnwage if employed, absorb(worker_fe=workerid firm_fe=firmid)
        // Extend saved effects to all records of each identified firm.
        bysort firmid: egen double psi = mean(firm_fe)
        egen byte tag = tag(firmid) if employed
        quietly summarize psi if tag, meanonly
        replace psi = psi-r(mean) if employed
        ferank firmid, worker(workerid) time(time) method(bradleyterry) ///
            score(mobility) componentid(rank_component)
        // Refuse misleading cross-component comparisons in this controlled demo.
        quietly count if employed & missing(psi, mobility)
        if r(N) {
            di as error "Report fixture has unidentified firms; inspect connectedness before plotting."
            exit 459
        }
        quietly summarize rank_component if employed, meanonly
        assert r(min)==r(max)
        // Independent weak-component check for the wage-effect normalization.
        quietly fegraph psi, worker(workerid) firm(firmid) time(time) ///
            type(firmgraph) top(1) nodraw
        assert r(N_components)==1
        quietly summarize unemployed, meanonly
        local urate : display %4.1f 100*r(mean)
        quietly count if tag
        local nf = r(N)
        local panel "worker(workerid) firm(firmid) time(time)"
        local outside "nonemployment(unemployed) outsidelabel(Unemployment)"
        local common "name(fegraph_report, replace)"
        local style "xsize(9) ysize(6) title(, size(medium))"
        local large "xsize(9) ysize(6) title(, size(medium)) ytitle(Estimated firm wage effect) xlabel(0(20)100)"
        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title'"
        latexlog `report': writeln "`description'"
        latexlog `report': writeln "\par\medskip Seed: `masterseed'. Observed firms: `nf'. Unemployment share: `urate' percent. Annual observations; 72,000 worker-period records. All firms belong to one identified comparison component in this fixture."
        fegraph psi, `panel' `outside' type(firmgraph) layout(circle) net top(60) ///
            nodescale(.55) nolabels `common' ///
            graphopts(`style' title("Firm network") subtitle("Largest 60 net flows; color = wage effect"))
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-firmgraph.pdf) width(1)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small Nodes are firms; the diamond is unemployment. Node size reflects mean employment. Widths encode net flow counts. Positions follow a circle layout and have no economic units. All firms remain visible even when none of their arrows passes the threshold. Color scales are specific to each panel.\par}"

        // Select complete histories of eight movers; never sample isolated rows.
        bysort workerid: egen byte mover = max(jobtojob)
        egen long selected_worker = group(workerid) if mover
        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title': worker--firm matches"
        fegraph psi if selected_worker<=8, `panel' type(bipartite) ///
            `outside' nodescale(.65) `common' ///
            graphopts(`style' title("Jobs of eight movers") subtitle("Complete histories; unemployment is not a job"))
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-bipartite.pdf) width(1)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small Small nodes are workers; large nodes are firms. A line denotes a distinct worker--firm match during the observation window. This deliberately small, selected illustration is not a representative network sample.\par}"

        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title': wage ladder"
        fegraph psi, `panel' `outside' type(ladder) bins(10) net top(35) ///
            nodescale(.7) `common' graphopts(`large' title("Ten wage-effect quantiles") subtitle("Net flows; unemployment in a separate band"))
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-ladder.pdf) width(1)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small The horizontal axis is the mean firm percentile in each score quantile; the vertical axis is the mean estimated firm wage effect. Unemployment has no wage effect or rank. Firm-to-firm curves are routed above and below the ladder to reduce overlap.\par}"

        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title': many bins"
        fegraph psi if employed, `panel' type(ladder) bins(50) net top(30) ///
            nodescale(.35) nolabels `common' graphopts(`large' title("Fifty wage-effect quantiles") subtitle("Largest 30 net firm-to-firm flows"))
        assert r(N_bins)==50
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-manybins.pdf) width(1)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small Fifty bins are feasible with 80 firms. Small nodes and a limited arrow count keep the diagram legible. Only adjacent employed observations are used; with maxgap(1), removing unemployment rows cannot create a move across an unemployment spell. Within-bin moves have no self-arrow.\par}"

        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title': complete flow matrix"
        fegraph psi, `panel' `outside' type(heatmap) bins(10) statistic(share) ///
            `common' graphopts(`style' title("Gross departure shares") subtitle("Ten wage-effect quantiles and unemployment"))
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-heatmap.pdf) width(.84)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small Rows are origins and columns are destinations. A cell divides gross moves by all departures from that origin. The diagonal records moves between different firms in the same bin, not same-firm stayers. No flow threshold is applied.\par}"

        latexlog `report': writeln "\clearpage"
        latexlog `report': section "`title': mobility ranking"
        fegraph mobility if employed, `panel' type(ladder) bins(10) ///
            level(psi) nodecolor(psi) effectgroup(rank_component) net top(25) ///
            nodescale(.7) `common' graphopts(`large' title("Firm-flow ranking and wage effects") subtitle("Ten Bradley-Terry score quantiles") xtitle("Mobility-score percentile: low to high"))
        latexlog `report': writeln "\par\begin{center}"
        latexlog `report': addfig, filename(`model'-rank.pdf) width(1)
        latexlog `report': writeln "\end{center}"
        latexlog `report': writeln "\noindent{\small The score before the comma now comes from ferank; level(psi) keeps estimated wage effects on the vertical axis. Ranking and wages need not agree. Scores summarize annual observed firm-to-firm flows and have no automatic causal or utility interpretation.\par}"
    }
    latexlog `report': close
    texpdf using `"`report'"', saving(`"`outdir'/report.pdf"') replace `view'
    di as result `"Report saved to `outdir'/report.pdf"'
end
