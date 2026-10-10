*! fegraph 0.7.0 10oct2026
program define fegraph__load
    version 16.0
    capture mata: assert(fegraph__version()==600 & fegraph__htmlversion()==600)
    if _rc {
        quietly findfile fegraph.mata
        quietly do `"`r(fn)'"'
        quietly findfile fegraph__html.mata
        quietly do `"`r(fn)'"'
    }
end
