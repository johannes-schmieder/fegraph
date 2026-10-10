version 16.0
// A fully observed illustrative hub-and-satellite network, not empirical data.
clear
set obs 80
generate origin = ceil(_n/5)
generate destination = 12+_n
replace origin = _n-60 if _n>60
replace destination = mod(origin,12)+1 if _n>60
replace origin = _n-72 if _n>72
replace destination = origin+4 if _n>72
generate connections = 1+mod(_n,4)
replace connections = 4+mod(_n,7) if _n>60
expand connections
generate workerid = _n
expand 2
bysort workerid: generate year = _n
generate firmid = cond(year==1,origin,destination)
generate psi = (cond(firmid<=12,firmid,ceil((firmid-12)/5))-6.5)/12
generate str16 firmname = "Firm " + string(firmid)
keep workerid year firmid psi firmname
