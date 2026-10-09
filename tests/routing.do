version 16.0
set more off
mata: mata set matalnum on
adopath ++ stata
capture mkdir build
capture mkdir build/tests
fegraph__load

* Routing uses both sides, preserves reciprocal direction, and is independent
* of edge-table row order. Outside-state flows do not consume firm lanes.
mata:
g=fegraph__new()
g.N=J(7,11,0)
g.N[,9]=J(7,1,1)
g.N[,(6,7)]=((0::5)*20,(0::5)/5) \ (50,-.5)
g.N[7,1]=2
g.E=(1,2 \ 2,3 \ 3,4 \ 4,5 \ 5,6 \ 2,4 \ 3,5 \ 4,6 \ 2,1 \ 7,1 \ 4,7)
e=(1::rows(g.E))
lanes=fegraph__ladderlanes(g,e)
assert(any(lanes:>0) & any(lanes:<0))
assert(lanes[1]*lanes[9]<0)
assert(lanes[10]==0 & lanes[11]==0)
assert(max(abs(lanes))>1)
for(i=1;i<=9;i++) for(j=i+1;j<=9;j++) {
    if(min(g.E[i,.])<=max(g.E[j,.]) & max(g.E[i,.])>=min(g.E[j,.])) assert(lanes[i]!=lanes[j])
}
rev=(rows(e)::1)
assert(fegraph__ladderlanes(g,e[rev])==lanes[rev])
assert(rows(fegraph__ladderlanes(g,J(0,1,.)))==0)
assert(abs(fegraph__ladderlanes(g,1))==1)

// Unclipped curves meet the original nodes; side has no economic meaning.
a=(0,0); b=(1,.4)
up=fegraph__ladderpath(a,b,1,0,0)
down=fegraph__ladderpath(a,b,-1,0,0)
assert(up[1,.]==a & up[25,.]==b)
assert(down[1,.]==a & down[25,.]==b)
assert(up[13,2]-.4*up[13,1]>0)
assert(down[13,2]-.4*down[13,1]<0)
back=fegraph__ladderpath(b,a,1,0,0)
assert(max(abs(up-back[25::1,.]))<1e-12)
outer=fegraph__ladderpath(a,b,2,0,0)
assert(outer[13,2]-.4*outer[13,1]>up[13,2]-.4*up[13,1])

// Curved clipping puts the visible head outside the marker and aims toward it.
for(side=-1;side<=1;side=side+2) {
    curve=fegraph__ladderpath(a,b,side,.03,.04)
    assert(abs(sqrt(sum(((curve[1,.]-a):*(1,.4)):^2))-.03)<1e-8)
    assert(abs(sqrt(sum(((curve[25,.]-b):*(1,.4)):^2))-.04)<1e-8)
    assert(sum((curve[25,.]-curve[24,.]):*(b-curve[25,.]))>0)
    assert(!any(curve:>=.))
}
// Equal percentiles with different levels route around the vertical chord.
curve=fegraph__ladderpath((.5,0),(.5,1),1,.03,.04)
assert(!any(curve:>=.) & curve[13,1]<.5)
curve=fegraph__ladderpath((0,0),(.001,0),-1,.03,.04)
assert(!any(curve:>=.) & curve[1,1]<curve[25,1])
end

* Exercise the command with tied ranks, a nonmonotone level, and reciprocal
* gross arrows. Node levels and counts retain their supplied meaning.
clear
input origin destination
1 2
2 1
1 3
3 1
2 3
3 2
2 4
4 2
3 4
4 3
end
generate double oo=floor(origin/2)
generate double od=floor(destination/2)
generate double lo=sin(origin)
generate double ld=sin(destination)
fegraph, origin(origin) destination(destination) type(ladder) order(oo od) level(lo ld) ///
    nodesize(equal) nodecolor(lo ld) edgecolor(effect) ///
    nodefile(build/tests/routing_nodes.dta) replace nodraw
assert r(flow_total)==10 & r(N_shown_edges)==10
preserve
use build/tests/routing_nodes.dta, clear
assert abs(y-sin(real(id)))<1e-12
quietly summarize x if id=="2", meanonly
assert x==r(mean) if id=="3"
restore

* Keep a gross-flow visual stress case alongside the ordinary net gallery.
quietly do examples/synthetic_panel.do
fegraph psi, firm(firmid) worker(workerid) time(time) type(ladder) ///
    nodecolor(psi) nonemployment(unemployed) outsidelabel(Unemployment) ///
    edgecolor(effect) name(routing_gross, replace)
assert r(flow_total)==41
graph export build/tests/routing_gross.png, width(2000) replace
display "FEGRAPH_ROUTING_OK"
