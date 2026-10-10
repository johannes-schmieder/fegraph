*! fegraph 0.7.0 10oct2026
program define fegraph_example, rclass
    version 16.0
    syntax [, TYPE(string) NODRAW]
    if "`type'"=="" local type firmgraph
    preserve
    capture noisily fegraph_example_run, type(`type') `nodraw'
    local rc=_rc
    if !`rc' return add
    restore
    if `rc' exit `rc'
end
program define fegraph_example_run, rclass
    version 16.0
    syntax , TYPE(string) [NODRAW]
    clear
    quietly set obs 120
    quietly generate worker=ceil(_n/6)
    quietly generate time=mod(_n-1,6)+1
    quietly generate firm=mod(floor((worker-1)/3)+floor((time-1)/2),6)+1
    quietly generate effect=(firm-3.5)/10
    if "`type'"=="bipartite" quietly keep if worker<=6
    fegraph effect, firm(firm) worker(worker) time(time) type(`type') nodecolor(effect) ///
        name(fegraph_example, replace) `nodraw'
    return add
end
