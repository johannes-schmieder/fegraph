*! fegraph 0.1.0 09oct2026
program define fegraph__load
    version 16.0
    capture mata: assert(fegraph__version()==100)
    if _rc {
        quietly findfile fegraph.mata
        quietly do `"`r(fn)'"'
    }
end
