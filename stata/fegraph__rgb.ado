*! fegraph 0.8.0 13oct2026
program define fegraph__rgb, rclass
    version 16.0
    syntax anything(name=colors)
    local result
    foreach color of local colors {
        local words : word count `color'
        if `words'==1 {
            if inlist("`color'","bg","background") local color "255 255 255"
            else if inlist("`color'","fg","foreground") local color "0 0 0"
            else {
                quietly findfile color-`color'.style
                tempname fh
                file open `fh' using `"`r(fn)'"', read text
                file read `fh' line
                local rgb
                while r(eof)==0 {
                    if regexm(`"`line'"',`"^set rgb "([0-9 ]+)""') local rgb = regexs(1)
                    file read `fh' line
                }
                file close `fh'
                if "`rgb'"=="" {
                    di as error "animation(): cannot resolve color `color'; supply its RGB triplet"
                    exit 198
                }
                local color `rgb'
            }
        }
        local result `"`result' "`color'""'
    }
    return local colors `"`result'"'
end
