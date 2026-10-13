version 16.0
mata:
real scalar fegraph__htmlversion() return(800)
// JSON text must not terminate the inline script, even for malicious labels.
string scalar fegraph__json(string scalar s) {
    s=subinstr(s,char(92),char(92)+char(92))
    s=subinstr(s,char(34),char(92)+char(34))
    real scalar i
    for(i=0;i<32;i++) s=subinstr(s,char(i),char(92)+"u00"+substr("0123456789abcdef",floor(i/16)+1,1)+substr("0123456789abcdef",mod(i,16)+1,1))
    s=subinstr(s,"<",char(92)+"u003c")
    s=subinstr(s,">",char(92)+"u003e")
    s=subinstr(s,"&",char(92)+"u0026")
    return(char(34)+s+char(34))
}
string scalar fegraph__num(real scalar x) {
    string scalar s
    if(x>=.) return("null")
    s=strtrim(strofreal(x,"%24.17g"))
    if(substr(s,1,1)==".") s="0"+s
    if(substr(s,1,2)=="-.") s="-0"+substr(s,2,.)
    return(s)
}
string scalar fegraph__array(real matrix x) {
    real scalar i,j
    string scalar s,r
    s="["
    for(i=1;i<=rows(x);i++) {
        if(i>1) s=s+","
        r="["
        for(j=1;j<=cols(x);j++) {
            if(j>1) r=r+","
            r=r+fegraph__num(x[i,j])
        }
        s=s+r+"]"
    }
    return(s+"]")
}
string scalar fegraph__vector(real vector x) {
    real scalar i
    string scalar s
    s="["
    for(i=1;i<=length(x);i++) {
        if(i>1) s=s+","
        s=s+fegraph__num(x[i])
    }
    return(s+"]")
}
string scalar fegraph__stringsjson(string vector x) {
    real scalar i
    string scalar s
    s="["
    for(i=1;i<=length(x);i++) {
        if(i>1) s=s+","
        s=s+fegraph__json(x[i])
    }
    return(s+"]")
}
// Calculate period values on the fixed pooled graph, before display filtering.
void fegraph__period(struct fegraph__graph scalar g, real scalar period, real matrix N, real matrix E) {
    real scalar i,a,b,k,den,change
    real matrix rows,raw,snap
    real colvector ix,departures
    transmorphic scalar lookup
    N=g.N; E=g.E
    E[,(3..9)]=J(rows(E),7,0); E[,11]=J(rows(E),1,0)
    if(g.edge=="shared" & g.type!="bipartite") ix=fegraph__which(g.A[,6]:<=period)
    else ix=fegraph__which(g.A[,6]:==period)
    raw=fegraph__sum(g.A[ix,(1..5)])
    lookup=asarray_create("real",2)
    for(i=1;i<=rows(E);i++) asarray(lookup,E[i,(1,2)],i)
    for(i=1;i<=rows(raw);i++) E[asarray(lookup,raw[i,(1,2)]),(3..5)]=raw[i,(3..5)]
    N[,10]=J(rows(N),1,0)
    for(i=1;i<=rows(g.X);i++) if(g.X[i,2]==period) N[g.X[i,1],10]=N[g.X[i,1],10]+g.X[i,3]
    if(anyof(("employment","matches"),st_local("nodesize")) | g.type=="bipartite") {
        ix=fegraph__which(N[,1]:==1)
        if(rows(ix)) N[ix,2]=J(rows(ix),1,0)
        if(anyof(("employment","matches"),st_local("nodesize"))) N[,2]=J(rows(N),1,0)
        for(i=1;i<=rows(g.S);i++) if(g.S[i,2]==period) {
            a=g.S[i,1]
            if(anyof(("employment","matches"),st_local("nodesize")) | N[a,1]==1) N[a,2]=N[a,2]+g.S[i,3]
        }
    }
    if(st_local("nodesize")=="flow") {
        N[,2]=J(rows(N),1,0)
        for(i=1;i<=rows(E);i++) {
            a=E[i,1]; b=E[i,2]
            N[a,2]=N[a,2]+E[i,3]; N[b,2]=N[b,2]+E[i,3]
        }
    }
    departures=J(rows(N),1,0)
    for(i=1;i<=rows(E);i++) departures[E[i,1]]=departures[E[i,1]]+E[i,3]
    for(i=1;i<=rows(E);i++) {
        a=E[i,1]; b=E[i,2]
        if(asarray_contains(lookup,(b,a))) E[i,6]=E[asarray(lookup,(b,a)),3]
        E[i,7]=E[i,3]-E[i,6]
        E[i,8]=fegraph__choose(g.net,E[i,7],E[i,3])
        if(g.statistic!="count") {
            den=fegraph__choose(g.statistic=="share",departures[a],N[a,10])
            E[i,8]=fegraph__choose(den>0,E[i,3]/den,0)
        }
        E[i,9]=.
        if(g.edgecolor=="effect") E[i,9]=g.E[i,9]
        if(g.edgecolor=="wage" & E[i,5]>0) E[i,9]=E[i,4]/E[i,5]
        E[i,11]=abs(E[i,8])
        if(g.edgesize=="effect") E[i,11]=g.E[i,11]
        if(g.edgesize=="wage") {
            E[i,11]=.
            if(E[i,5]>0) E[i,11]=abs(E[i,4]/E[i,5])
        }
    }
}
void fegraph__html(struct fegraph__graph scalar g, string scalar filename) {
    real scalar i,j,k,n,m,nt,h,tplhandle,sz,wd,ec,hm,lo,hi,total,shown,boundary,within
    real matrix N,E,ns,ev,coverage,path,out
    real colvector ni,ei,map,nc,ix
    real rowvector clim,wlim,limits
    string scalar line,title,subtitle,note,s
    string colvector labels,displaylabels
    string rowvector palette
    ni=fegraph__which(g.N[,9]); ei=fegraph__which(g.E[,10]); n=rows(ni); m=rows(ei)
    if(g.type=="heatmap") ni=ni[order(g.N[ni,6],1)]
    nt=1
    if(st_local("anim_mode")=="time") nt=rows(g.periods)
    if(nt*(n+m)>2000000) fegraph__fail("animation exceeds 2 million node/edge frames; use fewer periods, bins() or top()")
    map=J(rows(g.N),1,0); map[ni]=(1::n)
    ns=J(nt,n,0); ev=J(nt*m,7,.); coverage=J(nt,4,0)
    for(k=1;k<=nt;k++) {
        N=g.N; E=g.E
        if(st_local("anim_mode")=="time") fegraph__period(g,g.periods[k],N,E)
        ns[k,.]=N[ni,2]'
        if(m) ev[|(k-1)*m+1,1 \ k*m,7|]=E[ei,(3,6,7,8,9,11,5)]
        total=sum(E[,3]); shown=0; boundary=0; within=0
        for(i=1;i<=rows(E);i++) {
            if(E[i,10]) {
                shown=shown+E[i,3]
                if(g.net & g.type!="heatmap") shown=shown+E[i,6]
            }
            if(N[E[i,1],9]!=N[E[i,2],9]) boundary=boundary+E[i,3]
            if(E[i,1]==E[i,2] & N[E[i,1],9]) within=within+E[i,3]
        }
        coverage[k,.]=(total,shown,boundary,within)
    }
    sz=max((1e-12,max(vec(ns))))
    if(fegraph__opt("sizemax")>0) sz=fegraph__opt("sizemax")
    wd=1e-12; ec=0; hm=0
    if(m) {
        ix=fegraph__which(ev[,6]:<.); if(rows(ix)) wd=max((wd,max(ev[ix,6])))
        ix=fegraph__which(ev[,5]:<.); if(rows(ix)) ec=max(abs(ev[ix,5]))
        hm=max(abs(ev[,4]))
    }
    if(fegraph__opt("widthmax")>0) wd=fegraph__opt("widthmax")
    palette=tokens(st_local("edgelimits")); if(cols(palette)) ec=strtoreal(palette[2])
    clim=(.,.); wlim=(.,.); nc=J(n,1,0)
    if(g.type!="heatmap") {
        ix=fegraph__which(g.N[ni,1]:==0)
        if(rows(ix)) nc[ix]=fegraph__colorbins(g.N[ni[ix],3],0,clim,fegraph__flag("categorical"))
        ix=fegraph__which(g.N[ni,1]:==1)
        if(rows(ix)) nc[ix]=fegraph__colorbins(g.N[ni[ix],3],0,wlim,0)
    }
    else {
        clim=(0,hm)
        if(g.net) clim=(-hm,hm)
        palette=tokens(st_local(fegraph__choose(g.net,"edgelimits","colorlimits")))
        if(cols(palette)) clim=strtoreal(palette)
        if(st_local("anim_mode")=="aggregate") clim=(fegraph__opt("colormin"),fegraph__opt("colormax"))
    }
    displaylabels=fegraph__plotlabels(g,ni,fegraph__opt("labeltop"))
    if(fegraph__flag("nolabels")) displaylabels=J(n,1,"")
    title="Firm network"
    if(g.type=="ladder") title="Job ladder"
    if(g.type=="bipartite") title="Worker–firm matches"
    if(g.type=="heatmap") title="Worker flows"
    if(g.type=="heatmap" & !g.directed) title="Shared-worker connections"
    if(st_local("anim_title")!="") title=st_local("anim_title")
    if(fegraph__flag("anim_notitle")) title=""
    subtitle=fegraph__choose(g.net,"Net flows","Gross flows")
    if(!g.directed) subtitle=fegraph__choose(g.type=="bipartite","Worker–firm matches","Shared-worker connections")
    if(st_local("anim_subtitle")!="") subtitle=st_local("anim_subtitle")
    if(fegraph__flag("anim_nosubtitle")) subtitle=""
    note=""
    if(g.type!="heatmap") note="Moving dots illustrate relative intensity; each dot is not one worker. "
    if(st_local("anim_mode")=="time") {
        note=note+"Fixed pooled layout, bins and selected edges. Sizes and flows refer to the displayed period; supplied attributes stay fixed. "
        if(g.edge=="shared" & g.type!="bipartite") note=note+"Shared-worker connections accumulate through the displayed period. "
    }
    else note=note+"Aggregate graph; playback does not represent calendar time. "
    if(g.net) note=note+"Net values are differences between opposing gross flows. "
    if(any(g.N[ni,1]:==2)) note=note+"Outside state has no measured score or level. "
    if(st_local("anim_note")!="") note=st_local("anim_note")
    if(fegraph__flag("anim_nonotes")) note=""
    // Use native Stata geometry for the aggregate-selected paths, including lanes.
    out=J(0,2,.)
    if(g.type!="heatmap") out=st_data(.,("ex","ey"))
    h=fopen(filename,"w"); tplhandle=fopen(st_local("anim_template"),"r")
    while((line=fget(tplhandle))!=J(0,0,"")) {
        if(line!="<!-- FEGRAPH_DATA -->") { fput(h,line); continue; }
        fput(h,"<script type="+char(34)+"application/json"+char(34)+" id="+char(34)+"fegraph-data"+char(34)+">")
        fput(h,"{"+char(34)+"version"+char(34)+":"+fegraph__json("0.8.0")+",")
        for(i=1;i<=7;i++) {
            palette=("type","edge","statistic","edgecolor","edgesize","style","nodesize")
            fput(h,fegraph__json(palette[i])+":"+fegraph__json(st_local(palette[i]))+",")
        }
        for(i=1;i<=3;i++) {
            palette=("mode","theme","speed")
            fput(h,fegraph__json(palette[i])+":"+fegraph__json(st_local("anim_"+palette[i]))+",")
        }
        fput(h,(""+char(34)+"title"+char(34)+":")+fegraph__json(title)+(","+char(34)+"subtitle"+char(34)+":")+fegraph__json(subtitle)+(","+char(34)+"note"+char(34)+":")+fegraph__json(note)+",")
        fput(h,(""+char(34)+"net"+char(34)+":")+fegraph__num(g.net)+(","+char(34)+"directed"+char(34)+":")+fegraph__num(g.directed)+(","+char(34)+"nodescale"+char(34)+":")+fegraph__num(fegraph__opt("nodescale"))+",")
        fput(h,(""+char(34)+"legend"+char(34)+":")+fegraph__num(!fegraph__flag("anim_nolegend"))+(","+char(34)+"command"+char(34)+":")+fegraph__num(!fegraph__flag("anim_nocommand"))+",")
        fput(h,(""+char(34)+"palette"+char(34)+":")+fegraph__stringsjson(tokens(st_local("anim_palette")))+(","+char(34)+"edgepalette"+char(34)+":")+fegraph__stringsjson(tokens(st_local("anim_edgepalette")))+",")
        fput(h,(""+char(34)+"scales"+char(34)+":")+fegraph__vector((sz,wd,ec,clim,wlim))+(","+char(34)+"categories"+char(34)+":")+fegraph__stringsjson(tokens(st_local("categories")))+",")
        fput(h,(""+char(34)+"nodes"+char(34)+":["))
        for(i=1;i<=n;i++) {
            s=""; if(i>1) s=","
            fput(h,s+("{"+char(34)+"id"+char(34)+":")+fegraph__json(g.ids[ni[i]])+(","+char(34)+"label"+char(34)+":")+fegraph__json(g.labels[ni[i]])+(","+char(34)+"displaylabel"+char(34)+":")+fegraph__json(displaylabels[i])+(","+char(34)+"v"+char(34)+":")+fegraph__vector((g.N[ni[i],(1,2,3,4,5,6,7)],nc[i]))+"}")
        }
        fput(h,("],"+char(34)+"edges"+char(34)+":["))
        for(i=1;i<=m;i++) {
            s=""; if(i>1) s=","
            path=J(0,2,.)
            if(g.type!="heatmap") path=out[|n+(i-1)*26+1,1 \ n+(i-1)*26+25,2|]
            fput(h,s+("{"+char(34)+"from"+char(34)+":")+fegraph__num(map[g.E[ei[i],1]]-1)+(","+char(34)+"to"+char(34)+":")+fegraph__num(map[g.E[ei[i],2]]-1)+(","+char(34)+"path"+char(34)+":")+fegraph__array(path)+"}")
        }
        fput(h,("],"+char(34)+"frames"+char(34)+":["))
        for(k=1;k<=nt;k++) {
            s=""; if(k>1) s=","
            line="Aggregate"; if(st_local("anim_mode")=="time") line=strtrim(g.periodlabels[k])
            fput(h,s+("{"+char(34)+"label"+char(34)+":")+fegraph__json(line)+(","+char(34)+"sizes"+char(34)+":")+fegraph__vector(ns[k,.])+(","+char(34)+"coverage"+char(34)+":")+fegraph__vector(coverage[k,.])+(","+char(34)+"values"+char(34)+":["))
            for(i=1;i<=m;i++) {
                s=""; if(i>1) s=","
                fput(h,s+fegraph__vector(ev[(k-1)*m+i,.]))
            }
            fput(h,"]}")
        }
        fput(h,"]}</script>")
    }
    fclose(tplhandle); fclose(h)
    st_local("anim_frames",strofreal(nt))
}
end
