version 16
set more off
adopath ++ stata
capture mkdir build
capture mkdir build/eventstudy-gallery
local root `"`c(pwd)'"'
adopath ++ `"`root'/stata"'
cd build/eventstudy-gallery
foreach example in eventstudy eventstudy_coworker eventstudy_cohorts {
    fegraph_run `example' using fegraph.sthlp
}
cd `"`root'"'
display "FEGRAPH_EVENTSTUDY_GALLERY_OK"
