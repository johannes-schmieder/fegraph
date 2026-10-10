*! fegraph 0.6.1 10oct2026
program define fegraph__animation, rclass
    version 16.0
    syntax anything(name=filename id="HTML filename"), [MODE(string) THEME(string) ///
        SPEED(real 1) REPLACE TITLE(string) SUBTitle(string) NOTE(string) ///
        NOTITLE NOSUBTITLE NONOTES NOLEGEND NOCOMMAND]
    local count : word count `filename'
    if `count'!=1 {
        di as error "animation() requires one HTML filename; quote paths containing spaces"
        exit 198
    }
    local filename : word 1 of `filename'
    if !inlist(substr(lower(`"`filename'"'),-5,.),".html") {
        di as error "animation() requires a .html filename"
        exit 198
    }
    local mode = lower(strtrim("`mode'"))
    local theme = lower(strtrim("`theme'"))
    if "`mode'"=="" local mode aggregate
    if "`theme'"=="" local theme auto
    if !inlist("`mode'","aggregate","time") | !inlist("`theme'","auto","light","dark") {
        di as error "animation(): mode(aggregate|time) and theme(auto|light|dark)"
        exit 198
    }
    if `speed'<=0 | `speed'>20 | missing(`speed') {
        di as error "animation(): speed() must be positive and at most 20"
        exit 198
    }
    if "`replace'"=="" confirm new file `"`filename'"'
    foreach opt in filename mode theme replace title subtitle note notitle nosubtitle nonotes nolegend nocommand {
        return local `opt' `"``opt''"'
    }
    return scalar speed = `speed'
end
