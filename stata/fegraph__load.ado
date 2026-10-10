*! fegraph 0.4.0 09oct2026
program define fegraph__load
    version 16.0
    capture mata: assert(fegraph__version()==400)
    if _rc {
        quietly findfile fegraph.mata
        quietly do `"`r(fn)'"'
    }
end
