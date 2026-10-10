*! fegraph 0.7.0 10oct2026
program define fegraph__palette, rclass
    version 16.0
    syntax anything(name=spec id="palette name or seven colors"), [REVerse]
    local n : word count `spec'
    local key
    if `n'==1 {
        local key : word 1 of `spec'
        local key = lower(strtrim(`"`key'"'))
    }
    local colors
    if `"`key'"'=="viridis" local colors `""68 1 84" "68 57 131" "49 104 142" "33 145 140" "53 183 121" "144 215 67" "221 218 48""'
    if `"`key'"'=="blues" local colors `""239 243 255" "198 219 239" "158 202 225" "107 174 214" "66 146 198" "33 113 181" "8 69 148""'
    if `"`key'"'=="greens" local colors `""237 248 233" "199 233 192" "161 217 155" "116 196 118" "65 171 93" "35 139 69" "0 90 50""'
    if `"`key'"'=="grays" local colors `""235 235 235" "210 210 210" "180 180 180" "150 150 150" "115 115 115" "80 80 80" "40 40 40""'
    if `"`key'"'=="redblue" local colors `""178 24 43" "214 96 77" "244 165 130" "247 247 247" "146 197 222" "67 147 195" "33 102 172""'
    if `"`key'"'=="brownteal" local colors `""166 54 3" "217 95 14" "253 174 107" "180 180 180" "128 205 193" "53 151 143" "1 102 94""'
    local name `key'
    if `"`colors'"'=="" {
        local name custom
        if `n'!=7 {
            di as error "palette must be viridis, blues, greens, grays, redblue, brownteal, or exactly seven colors"
            exit 198
        }
        foreach color of local spec {
            local color = lower(strtrim(`"`color'"'))
            local words : word count `color'
            if `words'==3 {
                foreach value of local color {
                    capture confirm integer number `value'
                    if _rc {
                        di as error "RGB palette colors require three integers from 0 to 255"
                        exit 198
                    }
                    if `value'<0 | `value'>255 {
                        di as error "RGB palette colors require three integers from 0 to 255"
                        exit 198
                    }
                }
            }
            else if inlist(`"`color'"',"background","foreground","bg","fg") {
                // These special Stata colors do not have color-*.style files.
            }
            else if `words'==1 & regexm(`"`color'"',"^[a-z][a-z0-9_]*$") {
                capture findfile color-`color'.style
                if _rc {
                    di as error "unknown Stata palette color: `color'"
                    exit 198
                }
            }
            else {
                di as error "custom palettes accept named Stata colors or quoted RGB triplets only"
                exit 198
            }
            local colors `"`colors' "`color'""'
        }
        local colors = strtrim(`"`colors'"')
    }
    if "`reverse'"!="" {
        local reversed
        forvalues i=7(-1)1 {
            local color : word `i' of `colors'
            local reversed `"`reversed' "`color'""'
        }
        local colors = strtrim(`"`reversed'"')
        local name "`name', reverse"
    }
    return local name `"`name'"'
    return local colors `"`colors'"'
end
