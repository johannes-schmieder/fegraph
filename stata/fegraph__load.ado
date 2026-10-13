*! fegraph 0.8.0 13oct2026
program define fegraph__load
    version 16.0
    capture mata: assert(fegraph__version()==800 & fegraph__htmlversion()==800)
    if _rc {
        quietly findfile fegraph.mata
        quietly do `"`r(fn)'"'
        quietly findfile fegraph__html.mata
        quietly do `"`r(fn)'"'
    }
end
