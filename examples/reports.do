version 19.0
set more off
// Run from the repository root with optional companions already on the adopath.
adopath ++ stata
capture mkdir build
capture mkdir build/reports
fegraph_report, dgp(all) outdir("build/reports/all") replace
