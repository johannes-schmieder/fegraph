version 16.0
* Synthetic panel fixture: 18 workers, six firms, five periods.
clear
input byte workerid byte(firm1 firm2 firm3 firm4 firm5)
 1 1 1 2 3 4
 2 1 2 2 4 5
 3 2 2 3 4 6
 4 2 3 3 5 6
 5 3 3 4 4 5
 6 3 4 4 6 6
 7 4 4 5 5 6
 8 6 5 5 4 4
 9 1 1 1 1 1
10 2 2 2 2 2
11 5 5 5 5 5
12 0 0 1 2 3
13 4 4 0 0 2
14 0 2 3 4 4
15 6 6 5 6 6
16 1 2 3 4 5
17 2 3 4 5 6
18 3 4 5 6 6
end
reshape long firm, i(workerid) j(time)
rename firm firmid
* Here, and only by construction, firm 0 is observed unemployment.
generate byte unemployed = firmid == 0
generate double psi = -.30 + .12*(firmid-1) if firmid > 0
isid workerid time
assert _N == 90
