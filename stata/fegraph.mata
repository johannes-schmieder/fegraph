version 16.0
mata:
struct fegraph__graph {
    // N: kind,size,color,order,level,x,y,component,shown,exposure,group
    real matrix N
    // E: from,to,gross,wage_sum,wage_n,reverse,net,value,color,shown,width
    real matrix E
    string colvector ids, labels, original
    real colvector mapping
    real rowvector stats
    string scalar type, edge, statistic, edgecolor, edgesize
    real scalar directed, net
}
struct fegraph__graph scalar fegraph__new() {
    struct fegraph__graph scalar g
    return(g)
}
transmorphic scalar fegraph__choose(real scalar condition, transmorphic scalar a, transmorphic scalar b) {
    if(condition) return(a)
    return(b)
}
real colvector fegraph__which(real matrix x) {
    return(vec(selectindex(vec(x))))
}
transmorphic matrix fegraph__pick(transmorphic matrix x, real matrix mask) {
    return(x[fegraph__which(mask),.])
}
real scalar fegraph__version() return(100)
void fegraph__fail(string scalar msg) {
    errprintf("fegraph: %s\n",msg)
    _error(198)
}
real scalar fegraph__opt(string scalar name) return(strtoreal(st_local(name)))
real scalar fegraph__flag(string scalar name) return(st_local(name)!="")
real colvector fegraph__v(string scalar v) {
    if (v=="") return(J(st_nobs(),1,.))
    return(st_data(.,v))
}
string colvector fegraph__key(string scalar v) {
    real colvector x
    string colvector s
    if (substr(st_vartype(v),1,3)=="str") return(st_sdata(.,v))
    x=st_data(.,v)
    s=strtrim(strofreal(x,"%24.17g"))
    if (any(x:>=.)) s[fegraph__which(x:>=.)]=J(sum(x:>=.),1,"")
    return(s)
}
real colvector fegraph__code(string colvector s, string colvector levels) {
    transmorphic scalar dict
    real colvector out
    real scalar i
    levels=uniqrows(sort(fegraph__pick(s,s:!=""),1))
    dict=asarray_create("string",1)
    for(i=1;i<=rows(levels);i++) asarray(dict,levels[i],i)
    out=J(rows(s),1,0)
    for(i=1;i<=rows(s);i++) if(s[i]!="") out[i]=asarray(dict,s[i])
    return(out)
}
real matrix fegraph__sum(real matrix e) {
    real matrix p
    if (!rows(e)) return(J(0,5,.))
    e=sort(e,(1,2))
    if(rows(e)>1) p=panelsetup(runningsum(1 \ ((e[2..rows(e),1]:!=e[1..rows(e)-1,1]):|(e[2..rows(e),2]:!=e[1..rows(e)-1,2]))),1)
    if(rows(e)==1) p=(1,1)
    return(e[p[,1],(1,2)],panelsum(e[,(3..5)],p))
}
real colvector fegraph__attribute(real colvector id, real colvector val, real scalar n, string scalar what) {
    real colvector out
    real scalar i,k
    out=J(n,1,.)
    for(i=1;i<=rows(id);i++) {
        k=id[i]
        if(k==0 | val[i]>=.) continue
        if(out[k]<. & out[k]!=val[i]) fegraph__fail(what+" must be constant within each firm/worker")
        out[k]=val[i]
    }
    return(out)
}
string colvector fegraph__label(real colvector id, string colvector val, real scalar n) {
    string colvector out
    real scalar i,k
    out=J(n,1,"")
    for(i=1;i<=rows(id);i++) {
        k=id[i]
        if(k==0 | val[i]=="") continue
        if(out[k]!="" & out[k]!=val[i]) fegraph__fail("label() must be constant within firm")
        out[k]=val[i]
    }
    return(out)
}
real colvector fegraph__components(real matrix n, real matrix e) {
    real colvector parent,out
    real scalar i,a,b,k
    parent=(1::rows(n))
    for(i=1;i<=rows(e);i++) {
        a=e[i,1]; b=e[i,2]
        if(n[a,1]==2 | n[b,1]==2) continue
        while(parent[a]!=a) { parent[a]=parent[parent[a]]; a=parent[a]; }
        while(parent[b]!=b) { parent[b]=parent[parent[b]]; b=parent[b]; }
        if(a!=b) parent[max((a,b))]=min((a,b))
    }
    out=J(rows(n),1,0); k=0
    for(i=1;i<=rows(n);i++) {
        if(n[i,1]==2) continue
        a=i
        while(parent[a]!=a) a=parent[a]
        if(out[a]==0) { k++; out[a]=k; }
        out[i]=out[a]
    }
    return(out)
}
void fegraph__select(struct fegraph__graph scalar g) {
    real scalar i,k,best,score,mx,s
    real colvector seen,next,ix
    string scalar c
    g.N[,8]=fegraph__components(g.N,g.E)
    g.stats[8]=max(g.N[,8])
    g.N[,9]=J(rows(g.N),1,1)
    c=st_local("component")
    if(c!="all") {
        if(c=="largest") {
            best=1; mx=-1
            for(k=1;k<=g.stats[8];k++) {
                score=sum((g.N[,8]:==k):&(g.N[,1]:==0))
                if(score>mx) { mx=score; best=k; }
            }
        }
        else best=strtoreal(c)
        if(best>g.stats[8]) fegraph__fail("requested weak component does not exist")
        g.N[,9]=(g.N[,8]:==best):|(g.N[,1]:==2)
    }
    if(st_local("ego")!="") {
        ix=fegraph__which((g.ids:==st_local("ego")) :& (g.N[,1]:==0) :& g.N[,9])
        if(rows(ix)!=1) fegraph__fail("ego() must identify one selected firm using its original ID")
        seen=J(rows(g.N),1,0); seen[ix]=1
        for(s=1;s<=fegraph__opt("steps");s++) {
            next=seen
            for(i=1;i<=rows(g.E);i++) {
                k=g.E[i,1]; best=g.E[i,2]
                if(g.N[k,1]==2 | g.N[best,1]==2) continue
                if(seen[k] & g.N[best,9]) next[best]=1
                if(seen[best] & g.N[k,9]) next[k]=1
            }
            seen=next
        }
        g.N[,9]=seen :| (g.N[,1]:==2)
    }
}
void fegraph__bins(struct fegraph__graph scalar g) {
    real colvector ix,p,weights,ranks,map,sel,counts
    real scalar i,j,k,n,b,total,cum,lo,hi,bin,nb,w
    real matrix nn,ee
    string colvector ids,labels
    ix=fegraph__which((g.N[,1]:==0):&g.N[,9]); n=rows(ix)
    if(!n) fegraph__fail("no firms selected")
    if(any(g.N[ix,4]:>=.)) fegraph__fail("order() is missing for selected firms")
    p=order(g.N[ix,4],1)
    if(fegraph__flag("descending")) p=p[rows(p)::1]
    ix=ix[p]; weights=J(n,1,1)
    if(st_local("binweight")=="employment") {
        weights=g.N[ix,2]
        if(any(weights:>=.) | any(weights:<0) | sum(weights)==0) fegraph__fail("bin weights must have a positive finite total")
    }
    total=sum(weights); cum=0; ranks=J(n,1,0); map=(1::rows(g.N))
    b=fegraph__opt("bins"); bin=0; nb=0
    lo=1
    while(lo<=n) {
        hi=lo
        while(hi<n) { if(g.N[ix[hi+1],4]!=g.N[ix[lo],4]) break; hi++; }
        w=sum(weights[lo..hi])
        // End-point percentile convention gives 0..100 for unique equal-weight firms.
        if(st_local("binweight")=="firm") ranks[lo..hi]=J(hi-lo+1,1,fegraph__choose(n==1,50,100*((lo+hi)/2-1)/max((1,n-1))))
        else ranks[lo..hi]=J(hi-lo+1,1,100*(cum+w/2)/total)
        if(b>0) {
            j=min((b,1+floor(b*(cum+w/2)/total)))
            if(j!=bin) { nb++; bin=j; }
            map[ix[lo..hi]]=J(hi-lo+1,1,nb)
        }
        cum=cum+w; lo=hi+1
    }
    g.N[ix,6]=ranks
    if(b==0) return
    // Selected firms become bins; unselected firms remain hidden nodes, preserving boundary denominators.
    sel=fegraph__which(!((g.N[,1]:==0):&g.N[,9]))
    for(i=1;i<=rows(sel);i++) map[sel[i]]=nb+i
    nn=J(nb+rows(sel),11,.); ids=J(rows(nn),1,""); labels=ids
    for(k=1;k<=nb;k++) {
        p=fegraph__which(map[ix]:==k)
        counts=ix[p]; w=sum(weights[p])
        if(w<=0) fegraph__fail("a requested bin has zero weight")
        nn[k,1]=0; nn[k,2]=sum(g.N[counts,2]); nn[k,8]=0; nn[k,9]=1
        nn[k,10]=sum(g.N[counts,10]); nn[k,11]=g.N[counts[1],11]
        for(j=3;j<=7;j++) {
            sel=fegraph__which(g.N[counts,j]:<.)
            if(rows(sel)) nn[k,j]=sum(g.N[counts[sel],j]:*weights[p[sel]])/sum(weights[p[sel]])
        }
        ids[k]="bin:"+strofreal(k); labels[k]="Bin "+strofreal(k)
    }
    sel=fegraph__which(!((g.N[,1]:==0):&g.N[,9]))
    for(i=1;i<=rows(sel);i++) {
        nn[nb+i,]=g.N[sel[i],]; ids[nb+i]=g.ids[sel[i]]; labels[nb+i]=g.labels[sel[i]]
    }
    ee=g.E[,(1..5)]
    if(rows(ee)) { ee[,1]=map[ee[,1]]; ee[,2]=map[ee[,2]]; }
    g.E=fegraph__sum(ee)
    g.N=nn; g.ids=ids; g.labels=labels; g.mapping=map[g.mapping]
}
void fegraph__layout(struct fegraph__graph scalar g) {
    real colvector ix,fi,wi,disp,delta,dx,dy,dist,ids
    real matrix pos,force,e
    real scalar i,j,k,n,iter,temp,seed,a,b,sx,sy,r,hi,lo
    ix=fegraph__which(g.N[,9]); n=rows(ix)
    if(n==0) fegraph__fail("no nodes selected")
    if(n>fegraph__opt("maxnodes")) fegraph__fail("too many displayed nodes; use bins(), component(), ego(), or select complete histories")
    if(g.type=="heatmap" & n>100) fegraph__fail("heatmaps support at most 100 displayed nodes; use bins()")
    if(g.type=="ladder") {
        fi=fegraph__which((g.N[,1]:==0):&g.N[,9])
        if(any(g.N[fi,5]:>=.)) fegraph__fail("level() is missing for selected firms")
        g.N[fi,7]=g.N[fi,5]
        wi=fegraph__which((g.N[,1]:==2):&g.N[,9])
        lo=min(g.N[fi,7]); hi=max(g.N[fi,7]); r=max((hi-lo,.1))
        if(rows(wi)) { g.N[wi,6]=J(rows(wi),1,50); g.N[wi,7]=J(rows(wi),1,lo-.45*r); }
        return
    }
    if(g.type=="heatmap") {
        if(st_local("order")!="") {
            fi=fegraph__which((g.N[,1]:==0):&g.N[,9])
            ids=order(g.N[fi,4],1)
            if(fegraph__flag("descending")) ids=ids[rows(ids)::1]
            ix=fegraph__which((g.N[,1]:==2):&g.N[,9]) \ fi[ids]
        }
        g.N[ix,6]=(1::n); g.N[ix,7]=(1::n)
        return
    }
    if(st_local("layout")=="bipartite") {
        fi=fegraph__which((g.N[,1]:==0):&g.N[,9]); wi=fegraph__which((g.N[,1]:==1):&g.N[,9])
        if(rows(fi)) { g.N[fi,6]=(0::(rows(fi)-1))/max((1,rows(fi)-1)); g.N[fi,7]=J(rows(fi),1,1); }
        if(rows(wi)) { g.N[wi,6]=(0::(rows(wi)-1))/max((1,rows(wi)-1)); g.N[wi,7]=J(rows(wi),1,0); }
        return
    }
    seed=fegraph__opt("seed")
    pos=(cos(2*pi()*(0::(n-1))/n), sin(2*pi()*(0::(n-1))/n))
    if(st_local("layout")=="force" & n>1) {
        // Deterministic perturbations do not touch Stata's or Mata's RNG.
        pos=pos+.06*(sin((1::n)*12.9898:+seed),cos((1::n)*78.233:+seed))
        disp=J(rows(g.N),1,0); disp[ix]=(1::n)
        e=fegraph__pick(g.E,g.E[,10]:==1)
        k=sqrt(4/n)
        for(iter=1;iter<=fegraph__opt("iterations");iter++) {
            force=J(n,2,0)
            for(i=1;i<=n;i++) {
                dx=pos[i,1]:-pos[,1]; dy=pos[i,2]:-pos[,2]
                dist=dx:^2+dy:^2:+1e-8
                force[i,]=(sum(k*k*dx:/dist),sum(k*k*dy:/dist))
            }
            for(j=1;j<=rows(e);j++) {
                a=disp[e[j,1]]; b=disp[e[j,2]]
                if(a==b | a==0 | b==0) continue
                dx=pos[a,1]-pos[b,1]; dy=pos[a,2]-pos[b,2]
                r=sqrt(dx^2+dy^2)/k*sqrt(1+ln(1+e[j,3]))
                force[a,]=force[a,]-(dx*r,dy*r); force[b,]=force[b,]+(dx*r,dy*r)
            }
            temp=.12*(1-iter/(fegraph__opt("iterations")+1))
            for(i=1;i<=n;i++) {
                r=sqrt(sum(force[i,]:^2))
                if(r>0) pos[i,]=pos[i,]+force[i,]/r*min((r,temp))
            }
            pos=pos:-mean(pos)
        }
    }
    sx=max((max(pos[,1])-min(pos[,1]),1e-5)); sy=max((max(pos[,2])-min(pos[,2]),1e-5))
    g.N[ix,(6,7)]=(pos:-mean(pos))/max((sx,sy))
}
void fegraph__build(struct fegraph__graph scalar g) {
    real scalar panel,n,nf,nw,i,j,k,a,b,outid,c,dt,m,eligible,gaps,unknown,count,ng,lo,hi
    real scalar net,den,groups,maxv,valid,weight,effectchange,wagechange
    real matrix pairs,raw,p,vals,ee,info
    real colvector wid,f,to,w,t,selected,outside,exposure,firmrows,rowsel,idx,x,y,z,ww,attr,mask,inc,rev
    string rowvector vv,opts
    string colvector keys,levels,wlevels,s,sk,groupkeys,dummy
    string scalar option,v,sz
    transmorphic scalar dict
    panel=fegraph__opt("panel"); n=st_nobs(); vv=tokens(st_local("varlist"))
    selected=st_data(.,st_local("touse")); g.stats=J(1,18,0); g.stats[1]=sum(selected)
    g.type=st_local("type"); g.edge=st_local("edge"); g.net=fegraph__flag("net")
    g.statistic=st_local("statistic"); g.edgecolor=st_local("edgecolor"); g.edgesize=st_local("edgesize")
    g.directed=!(g.type=="bipartite" | g.edge=="shared")
    keys=fegraph__key(vv[1]); outid=0
    if(panel) {
        outside=J(n,1,0)
        if(st_local("nonemployment")!="") {
            outside=fegraph__v(st_local("nonemployment"))
            if(any(fegraph__pick((outside:!=0):&(outside:!=1),selected))) fegraph__fail("nonemployment() must be a nonmissing 0/1 indicator")
            keys[fegraph__which(outside:==1)]=J(sum(outside:==1),1,"")
        }
        // Dictionary contains only selected firms; outside sample breaks cannot create new displayed firms.
        sk=keys
        if(any(!selected)) sk[fegraph__which(!selected)]=J(sum(!selected),1,"")
        f=fegraph__code(sk,levels); nf=rows(levels)
        if(any((outside:==1):&selected) & g.directed) { outid=nf+1; f[fegraph__which((outside:==1):&selected)]=J(sum((outside:==1):&selected),1,outid); }
        w=fegraph__code(fegraph__key(st_local("worker")),wlevels); nw=rows(wlevels)
        if(any(w:==0)) fegraph__fail("worker IDs must be nonmissing")
        g.stats[2]=rows(uniqrows(fegraph__pick(w,selected)))
        t=fegraph__v(st_local("time"))
        if(st_local("time")!="") {
            if(any(t:>=.)) fegraph__fail("time() must be nonmissing")
            p=sort((w,t,(1::n)),(1,2))
            if(n>1) if(any((p[2..n,1]:==p[1..n-1,1]):&(p[2..n,2]:==p[1..n-1,2]))) fegraph__fail("duplicate worker-time keys; choose a main job explicitly")
        }
        else p=sort((w,J(n,1,0),(1::n)),(1,2))
        g.ids=levels
        if(outid) g.ids=g.ids \ "[outside]"
        g.N=J(rows(g.ids),11,.)
        g.N[,1]=J(rows(g.ids),1,0)
        if(outid) g.N[outid,1]=2
        if(!rows(g.N)) fegraph__fail("no known firms or explicit outside states")
        pairs=uniqrows(sort(fegraph__pick((w,f),(f:>0):&(f:<=nf):&selected),(1,2)))
        g.stats[4]=rows(pairs)
        exposure=J(rows(g.N),1,0); inc=J(rows(g.N),1,0)
        for(i=1;i<=n;i++) if(f[i]>0 & selected[i]) inc[f[i]]=inc[f[i]]+1
        if(st_local("time")!="") inc=inc/rows(uniqrows(sort(fegraph__pick(t,selected),1)))
        if(st_local("nodesize")=="matches") {
            inc=J(rows(g.N),1,0)
            for(i=1;i<=rows(pairs);i++) inc[pairs[i,2]]=inc[pairs[i,2]]+1
        }
        g.N[,2]=inc
        raw=J(max((n,1)),5,0); count=0; eligible=0; gaps=0; unknown=0
        ww=fegraph__v(st_local("wage"))
        if(st_local("wagescale")=="level") if(any(fegraph__pick((ww:<=0):&(ww:<.),selected))) fegraph__fail("level wages must be positive where observed")
        if(g.directed) {
            for(i=2;i<=n;i++) {
                if(p[i,1]!=p[i-1,1]) continue
                a=p[i-1,3]; b=p[i,3]
                if(!selected[a] | !selected[b]) continue
                dt=t[b]-t[a]
                if(dt>fegraph__opt("maxgap")) { gaps++; continue; }
                if(f[a]==0 | f[b]==0) { unknown++; continue; }
                eligible++; exposure[f[a]]=exposure[f[a]]+1
                if(f[a]==f[b]) continue
                count++; raw[count,(1..3)]=(f[a],f[b],1)
                if(ww[a]<. & ww[b]<. & f[a]!=outid & f[b]!=outid) {
                    weight=ww[b]-ww[a]
                    if(st_local("wagescale")=="level") weight=100*(ww[b]/ww[a]-1)
                    raw[count,(4,5)]=(weight,1)
                }
            }
            raw=raw[|1,1 \ max((count,1)),5|]
            if(!count) raw=J(0,5,.)
        }
        else if(g.type=="bipartite") {
            idx=uniqrows(pairs[,1]); wid=idx; nw=rows(idx); attr=J(rows(wlevels),1,0)
            if(nw) attr[idx]=(nf+1::nf+nw)
            raw=(pairs[,2],attr[pairs[,1]],J(rows(pairs),1,1),J(rows(pairs),2,0))
        }
        else {
            info=panelsetup(pairs,1); count=0
            for(i=1;i<=rows(info);i++) { m=info[i,2]-info[i,1]+1; count=count+m*(m-1)/2; }
            if(count>5000000) fegraph__fail("shared-worker projection exceeds 5 million contributions; shorten the window or use bipartite")
            raw=J(count,5,0); count=0
            for(i=1;i<=rows(info);i++) for(a=info[i,1];a<=info[i,2];a++) for(b=a+1;b<=info[i,2];b++) {
                count++; raw[count,(1..3)]=(pairs[a,2],pairs[b,2],1)
            }
        }
        g.stats[(5,6,7)]=(eligible,gaps,unknown)
        g.N[,10]=exposure
        firmrows=f; rowsel=selected
    }
    else {
        if((substr(st_vartype(vv[1]),1,3)=="str")!=(substr(st_vartype(vv[2]),1,3)=="str")) fegraph__fail("origin and destination must both be numeric or both string")
        sk=fegraph__key(vv[2]); firmrows=fegraph__code(keys \ sk,levels)
        if(any(firmrows:==0)) fegraph__fail("prepared-flow endpoints cannot be missing")
        f=firmrows[1..n]; to=firmrows[n+1..2*n]; nf=rows(levels)
        g.ids=levels; g.N=J(nf,11,.); g.N[,1]=J(nf,1,0)
        if(st_local("outside")!="") {
            idx=fegraph__which(levels:==st_local("outside"))
            if(rows(idx)!=1) fegraph__fail("outside() ID is not present in the edge table")
            outid=idx[1]; g.N[outid,1]=2
        }
        weight=1; x=J(n,1,1)
        if(st_local("flow")!="") x=fegraph__v(st_local("flow"))
        if(any(x:>=.) | any(x:<0)) fegraph__fail("flow() must be finite and nonnegative")
        raw=fegraph__pick((f,to,x,J(n,2,0)),(x:>0):&(f:!=to))
        g.N[,10]=J(nf,1,.)
        if(st_local("exposure")!="") {
            x=fegraph__v(st_local("exposure"))
            if(any(x:>=.) | any(x:<0)) fegraph__fail("exposure() must be finite and nonnegative")
            g.N[,10]=fegraph__attribute(f,x,nf,"exposure()")
        }
        g.N[,2]=J(nf,1,1); rowsel=J(2*n,1,1)
    }
    g.stats[3]=sum(g.N[,1]:==0)
    g.E=fegraph__sum(raw)
    g.labels=g.ids
    opts=("nodecolor","order","level")
    for(j=1;j<=3;j++) {
        option=opts[j]; vv=tokens(st_local(option))
        if(cols(vv)) {
            vals=fegraph__v(vv[1])
            if(!panel) vals=vals \ fegraph__v(vv[2])
            g.N[,j+2]=fegraph__attribute(fegraph__pick(firmrows,rowsel),fegraph__pick(vals,rowsel),rows(g.N),option+"()")
        }
    }
    vv=tokens(st_local("effectgroup"))
    if(cols(vv)) {
        groupkeys=fegraph__key(vv[1])
        if(!panel) groupkeys=groupkeys \ fegraph__key(vv[2])
        attr=fegraph__code(groupkeys,dummy)
        attr[fegraph__which(attr:==0)]=J(sum(attr:==0),1,.)
        g.N[,11]=fegraph__attribute(fegraph__pick(firmrows,rowsel),fegraph__pick(attr,rowsel),rows(g.N),"effectgroup()")
    }
    vv=tokens(st_local("label"))
    if(cols(vv)) {
        s=fegraph__key(vv[1]); if(!panel) s=s \ fegraph__key(vv[2])
        s=fegraph__label(fegraph__pick(firmrows,rowsel),fegraph__pick(s,rowsel),rows(g.N))
        idx=fegraph__which(s:!=""); if(rows(idx)) g.labels[idx]=s[idx]
    }
    sz=st_local("nodesize")
    if(!anyof(("employment","matches","flow","equal"),sz)) {
        vv=tokens(sz); x=fegraph__v(vv[1]); if(!panel) x=x \ fegraph__v(vv[2])
        g.N[,2]=fegraph__attribute(fegraph__pick(firmrows,rowsel),fegraph__pick(x,rowsel),rows(g.N),"nodesize()")
        if(any(fegraph__pick((g.N[,2]:>=.):|(g.N[,2]:<0),g.N[,1]:==0))) fegraph__fail("supplied node sizes must be nonmissing and nonnegative for all nodes")
    }
    if(sz=="equal") g.N[,2]=J(rows(g.N),1,1)
    if(sz=="flow") {
        g.N[,2]=J(rows(g.N),1,0)
        for(i=1;i<=rows(g.E);i++) { a=g.E[i,1]; b=g.E[i,2]; g.N[a,2]=g.N[a,2]+g.E[i,3]; g.N[b,2]=g.N[b,2]+g.E[i,3]; }
    }
    if(outid) if(g.N[outid,2]>=.) g.N[outid,2]=1
    if(outid) { g.labels[outid]=st_local("outsidelabel"); g.N[outid,(3,4,5,11)]=J(1,4,.); }
    g.original=g.ids; g.mapping=(1::rows(g.N))
    if(g.type=="bipartite") {
        vals=J(nw,11,.); vals[,1]=J(nw,1,1); vals[,2]=J(nw,1,.3); vals[,10]=J(nw,1,0)
        if(st_local("workercolor")!="") {
            attr=fegraph__attribute(fegraph__pick(w,selected),fegraph__pick(fegraph__v(st_local("workercolor")),selected),rows(wlevels),"workercolor()")
            vals[,3]=attr[wid]
        }
        g.N=g.N \ vals; g.ids=g.ids \ wlevels[wid]; g.labels=g.labels \ ("w:" :+ wlevels[wid])
    }
    fegraph__select(g)
    if(st_local("effectgroup")!="" & !fegraph__flag("pooled")) {
        x=fegraph__pick(g.N[,11],(g.N[,1]:==0):&g.N[,9])
        if(any(x:>=.) | rows(uniqrows(sort(x,1)))>1) fegraph__fail("effects/ranks have missing or different comparison groups; select one group or explicitly specify pooled")
    }
    if(g.type=="ladder" | fegraph__opt("bins")>0) fegraph__bins(g)
    // Recompute directed pair totals after aggregation; do not threshold before binning/netting.
    g.E=g.E,J(rows(g.E),6,0)
    dict=asarray_create("real",2)
    for(i=1;i<=rows(g.E);i++) asarray(dict,g.E[i,(1,2)],g.E[i,3])
    inc=J(rows(g.N),1,0)
    for(i=1;i<=rows(g.E);i++) inc[g.E[i,1]]=inc[g.E[i,1]]+g.E[i,3]
    for(i=1;i<=rows(g.E);i++) {
        a=g.E[i,1]; b=g.E[i,2]
        if(asarray_contains(dict,(b,a))) g.E[i,6]=asarray(dict,(b,a))
        g.E[i,7]=g.E[i,3]-g.E[i,6]
        g.E[i,8]=fegraph__choose(g.net,g.E[i,7],g.E[i,3])
        if(g.statistic!="count") {
            den=fegraph__choose(g.statistic=="share",inc[a],g.N[a,10])
            if(den<=0 | den>=.) fegraph__fail("positive flow has missing or zero denominator")
            if(g.statistic=="probability" & inc[a]>den+1e-8*max((1,den))) fegraph__fail("departures exceed supplied exposure")
            g.E[i,8]=g.E[i,3]/den
        }
        effectchange=.; wagechange=.
        k=fegraph__choose(st_local("level")!="",5,3)
        if(g.N[a,k]<. & g.N[b,k]<.) effectchange=g.N[b,k]-g.N[a,k]
        if(g.E[i,5]>0) wagechange=g.E[i,4]/g.E[i,5]
        g.E[i,9]=.
        if(g.edgecolor=="effect") g.E[i,9]=effectchange
        if(g.edgecolor=="wage") g.E[i,9]=wagechange
        g.E[i,11]=abs(g.E[i,8])
        if(g.edgesize=="effect") g.E[i,11]=abs(effectchange)
        if(g.edgesize=="wage") g.E[i,11]=abs(wagechange)
        valid=g.N[a,9] & g.N[b,9] & (a!=b | g.type=="heatmap")
        g.E[i,10]=valid & (fegraph__choose(g.net,abs(g.E[i,7]),g.E[i,3])>=fegraph__opt("minflow"))
        if(g.net) g.E[i,10]=g.E[i,10] & g.E[i,7]>0
        if(g.net & g.E[i,7]==0) g.E[i,10]=0
    }
    if(fegraph__opt("top")>0) {
        idx=fegraph__which(g.E[,10])
        if(rows(idx)>fegraph__opt("top")) {
            p=order((-abs(g.E[idx,8]),g.E[idx,(1,2)]),(1,2,3))
            g.E[idx[p[fegraph__opt("top")+1..rows(p)]],10]=J(rows(p)-fegraph__opt("top"),1,0)
        }
    }
    if(g.net & g.type=="heatmap") {
        dict=asarray_create("real",2)
        for(i=1;i<=rows(g.E);i++) if(g.E[i,10]) asarray(dict,g.E[i,(1,2)],1)
        for(i=1;i<=rows(g.E);i++) if(asarray_contains(dict,g.E[i,(2,1)])) g.E[i,10]=1
    }
    if(sum(g.E[,10])>fegraph__opt("maxedges")) fegraph__fail("too many displayed edges; use minflow(), top(), bins() or an ego graph")
    g.stats[9]=rows(g.N); g.stats[10]=rows(g.E)
    g.stats[11]=sum(g.N[,9]); g.stats[12]=sum(g.E[,10]); g.stats[13]=sum(g.E[,3])
    for(i=1;i<=rows(g.E);i++) {
        a=g.E[i,1]; b=g.E[i,2]
        if(g.E[i,10]) g.stats[14]=g.stats[14]+g.E[i,3]
        if(g.N[a,9]!=g.N[b,9]) g.stats[15]=g.stats[15]+g.E[i,3]
        if(a==b & g.N[a,9]) g.stats[16]=g.stats[16]+g.E[i,3]
        if(g.net & g.E[i,10] & g.type!="heatmap") g.stats[14]=g.stats[14]+g.E[i,6]
    }
    if(g.net) g.stats[17]=sum(g.E[,3])-sum(fegraph__pick(g.E[,7],g.E[,7]:>0))
    g.stats[18]=sum((g.N[,3]:>=.):&g.N[,9]:&(g.N[,1]:==0))
    fegraph__layout(g)
}
void fegraph__coordinates(struct fegraph__graph scalar g) {
    real colvector kind,x,y,ix
    string colvector id
    transmorphic scalar dict
    string scalar key
    real scalar i,j
    if(g.type=="ladder" | g.type=="heatmap") fegraph__fail("coordinates() applies to free network layouts, not data-defined axes")
    id=st_sdata(.,"id"); kind=st_data(.,"kind"); x=st_data(.,"x"); y=st_data(.,"y")
    dict=asarray_create("string",1)
    for(i=1;i<=rows(id);i++) {
        key=strofreal(kind[i])+":"+id[i]
        if(asarray_contains(dict,key)) fegraph__fail("coordinate table has duplicate (kind,id) keys")
        asarray(dict,key,i)
    }
    for(j=1;j<=rows(g.N);j++) if(g.N[j,9]) {
        key=strofreal(g.N[j,1])+":"+g.ids[j]
        if(!asarray_contains(dict,key)) fegraph__fail("coordinate table is missing a displayed node")
        i=asarray(dict,key)
        if(x[i]>=. | y[i]>=.) fegraph__fail("displayed coordinates must be finite")
        g.N[j,(6,7)]=(x[i],y[i])
    }
}
void fegraph__write(real matrix values, string rowvector names) {
    real scalar j
    for(j=1;j<=cols(names);j++) (void) st_addvar("double",names[j])
    st_addobs(rows(values))
    if(rows(values)) st_store(.,names,values)
}
void fegraph__strings(string scalar name, string colvector values) {
    real scalar width
    string scalar storage
    width=max((1,max(strlen(values))))
    storage="strL"
    if(width<=2045) storage="str"+strofreal(width)
    (void) st_addvar(storage,name)
    if(rows(values)) st_sstore(.,name,values)
}
void fegraph__nodes(struct fegraph__graph scalar g) {
    real scalar j
    string rowvector names
    fegraph__write((1::rows(g.N)),("node"))
    names=("kind","size","color","ordering","level","x","y","component","displayed","exposure","effectgroup")
    for(j=1;j<=cols(names);j++) { (void) st_addvar("double",names[j]); st_store(.,names[j],g.N[,j]); }
    fegraph__strings("id",g.ids); fegraph__strings("label",g.labels)
}
void fegraph__edges(struct fegraph__graph scalar g) {
    real matrix e
    real colvector meanw,missingw
    e=g.E; meanw=J(rows(e),1,.)
    missingw=fegraph__which(e[,5]:>0)
    if(rows(missingw)) meanw[missingw]=e[missingw,4]:/e[missingw,5]
    fegraph__write((e,meanw),("origin","destination","gross","wage_sum","wage_n","reverse","net","value","color","displayed","width_value","mean_wage_change"))
    fegraph__strings("origin_id",g.ids[e[,1]]); fegraph__strings("destination_id",g.ids[e[,2]])
}
void fegraph__mapping(struct fegraph__graph scalar g) {
    fegraph__write(g.mapping,("node"))
    fegraph__strings("original_id",g.original)
    fegraph__strings("node_id",g.ids[g.mapping])
}
real colvector fegraph__colorbins(real colvector v, real scalar signedscale, real rowvector limits, real scalar categorical) {
    real colvector out,ix,unique
    real scalar lo,hi,m,i
    string rowvector given
    out=J(rows(v),1,0); ix=fegraph__which(v:<.)
    limits=(.,.)
    if(!rows(ix)) return(out)
    lo=min(v[ix]); hi=max(v[ix]); limits=(lo,hi)
    if(categorical) {
        unique=uniqrows(sort(v[ix],1))
        if(rows(unique)>7) fegraph__fail("categorical node colors support at most seven values")
        for(i=1;i<=rows(unique);i++) out[fegraph__which(v:==unique[i])]=J(sum(v:==unique[i]),1,i)
        st_local("categories",invtokens(strofreal(unique',"%9.4g")))
        return(out)
    }
    if(signedscale) { m=max(abs((lo,hi))); lo=-m; hi=m; limits=(lo,hi); }
    given=tokens(st_local(fegraph__choose(signedscale,"edgelimits","colorlimits")))
    if(cols(given)) { lo=strtoreal(given[1]); hi=strtoreal(given[2]); limits=(lo,hi); }
    if(hi==lo) out[ix]=J(rows(ix),1,4)
    else out[ix]=rowmax((J(rows(ix),1,1),rowmin((J(rows(ix),1,7),1:+floor(7*(v[ix]:-lo)/(hi-lo))))))
    return(out)
}
// Assign short links first, reusing a lane only for disjoint rank intervals.
// Side is a routing choice, independent of movement direction or effect sign.
real colvector fegraph__ladderlanes(struct fegraph__graph scalar g, real colvector ei) {
    real colvector lane,rank,ni,ix,lo,hi,p,conflict
    real matrix ends,used
    real scalar m,k,i,j,a,b,above,below,side,reverse,nabove,nbelow
    transmorphic scalar lookup
    m=rows(ei); lane=J(m,1,0)
    if(!m) return(lane)
    ni=fegraph__which((g.N[,1]:==0):&g.N[,9])
    if(!rows(ni)) return(lane)
    ni=ni[order((g.N[ni,(6,7)],ni),(1,2,3))]
    rank=J(rows(g.N),1,0); rank[ni]=(1::rows(ni))
    ends=g.E[ei,(1,2)]
    ix=fegraph__which((rank[ends[,1]]:>0):&(rank[ends[,2]]:>0):&(ends[,1]:!=ends[,2]))
    if(!rows(ix)) return(lane)
    lo=rowmin((rank[ends[,1]],rank[ends[,2]])); hi=rowmax((rank[ends[,1]],rank[ends[,2]]))
    p=ix[order((hi[ix]-lo[ix],lo[ix],hi[ix],ends[ix,.]),(1,2,3,4,5))]
    lookup=asarray_create("real",2)
    for(i=1;i<=m;i++) asarray(lookup,ends[i,.],i)
    nabove=0; nbelow=0
    for(k=1;k<=rows(p);k++) {
        i=p[k]; a=ends[i,1]; b=ends[i,2]
        // Touching intervals conflict too: separate arrows at shared endpoints.
        conflict=fegraph__which((lane:!=0):&(lo:<=hi[i]):&(hi:>=lo[i]))
        used=J(m+1,2,0)
        for(j=1;j<=rows(conflict);j++) {
            reverse=lane[conflict[j]]
            used[abs(reverse),fegraph__choose(reverse>0,1,2)]=1
        }
        above=1; below=1
        while(used[above,1]) above++
        while(used[below,2]) below++
        side=fegraph__choose(above<below | (above==below & nabove<=nbelow),1,-1)
        // Reciprocal gross arrows always use opposite sides of the same chord.
        if(asarray_contains(lookup,(b,a))) {
            reverse=lane[asarray(lookup,(b,a))]
            if(reverse!=0) side=-sign(reverse)
        }
        lane[i]=side*fegraph__choose(side>0,above,below)
        if(side>0) nabove++
        else nbelow++
    }
    return(lane)
}

real rowvector fegraph__bezier(real rowvector a, real rowvector c, real rowvector b, real scalar t) {
    return((1-t)^2*a+2*(1-t)*t*c+t^2*b)
}

// Work in normalized plot coordinates. Clip along the curved path, so its
// terminal segment points toward the destination instead of past its marker.
real matrix fegraph__ladderpath(real rowvector a, real rowvector b, real scalar lane, real scalar ra, real scalar rb) {
    real rowvector delta,normal,c,point
    real matrix path
    real scalar d,bend,orient,left,right,t,ta,tb,i,j,radius
    delta=b-a; d=sqrt(sum(delta:^2))
    if(d<1e-10) fegraph__fail("connected displayed nodes share coordinates; use rank bins or distinct coordinates")
    orient=1
    if(delta[1]<0 | (delta[1]==0 & delta[2]<0)) orient=-1
    normal=orient*(-delta[2],delta[1])/d
    bend=.20+.16*d+.16*sqrt(abs(lane)-1)
    c=(a+b)/2+sign(lane)*bend*normal
    ta=0; tb=1
    for(j=1;j<=2;j++) {
        radius=fegraph__choose(j==1,ra,rb)
        if(radius<=0) continue
        // Ladder plots are wider than tall; use an elliptical marker clearance.
        point=fegraph__bezier(a,c,b,.5)
        if(j==1) point=point-a
        else point=point-b
        radius=min((radius,.8*sqrt(sum((point:*(1,.4)):^2))))
        left=0; right=.5
        for(i=1;i<=30;i++) {
            t=(left+right)/2
            if(j==1) point=fegraph__bezier(a,c,b,t)-a
            else point=fegraph__bezier(a,c,b,1-t)-b
            if(sqrt(sum((point:*(1,.4)):^2))<radius) left=t
            else right=t
        }
        if(j==1) ta=(left+right)/2
        else tb=1-(left+right)/2
    }
    path=J(25,2,.)
    for(i=1;i<=25;i++) path[i,.]=fegraph__bezier(a,c,b,ta+(tb-ta)*(i-1)/24)
    return(path)
}

void fegraph__plot(struct fegraph__graph scalar g) {
    real colvector ix,ni,ei,nc,ns,ec,es,weight,kind,ord,vec,nodeclass,lanes
    real rowvector limits,clim,elim,wlim
    real matrix out,paths,curve
    string colvector labs
    real scalar n,m,i,j,a,b,r,q,x1,y1,x2,y2,cx,cy,x,y,px,py,sx,sy,dx,dy,d,bend,maxsize,maxweight,k,lo,hi,value,ra,rb
    transmorphic scalar lookup
    string scalar notes,legend,xlabels,ylabels,axislabel
    // Columns: nx,ny,nkind,ncolor,nsize,ex,ey,ax,ay,bx,by,ecolor,esize,hx,hlo,hhi,hcolor
    ni=fegraph__which(g.N[,9]); ei=fegraph__which(g.E[,10]); n=rows(ni); m=rows(ei)
    out=J(0,17,.); labs=J(0,1,"")
    st_local("workermin","."); st_local("workermax",".")
    if(g.type=="heatmap") {
        ord=order(g.N[ni,6],1); ni=ni[ord]; lookup=asarray_create("real",2)
        for(i=1;i<=rows(g.E);i++) asarray(lookup,g.E[i,(1,2)],i)
        out=J(n*n,17,.); vec=J(n*n,1,.); labs=J(n*n,1,""); r=0
        for(a=1;a<=n;a++) for(b=1;b<=n;b++) {
            r++; i=ni[a]; j=ni[b]; value=0
            if(asarray_contains(lookup,(i,j))) {
                k=asarray(lookup,(i,j))
                if(g.E[k,10]) value=g.E[k,8]
            }
            else if(g.net & asarray_contains(lookup,(j,i))) {
                k=asarray(lookup,(j,i))
                if(g.E[k,10]) value=-g.E[k,8]
            }
            vec[r]=value; out[r,(14,15,16)]=(b,a-.48,a+.48)
        }
        out[,17]=fegraph__colorbins(vec,g.net,clim,0)
        // Zero cells are neutral; colors still use the full nonzero scale.
        ix=fegraph__which(vec:==0); if(rows(ix)) out[ix,17]=J(rows(ix),1,0)
        xlabels=""; ylabels=""
        for(i=1;i<=n;i++) {
            // Axis labels are numeric node indices; original IDs remain in the node table.
            axislabel=substr(g.labels[ni[i]],1,24)
            axislabel=subinstr(subinstr(subinstr(axislabel,char(34),"'"),char(96),"'"),char(10)," ")
            xlabels=xlabels+" "+strofreal(i)+" "+char(34)+axislabel+char(34)
        }
        st_local("heatlabels",xlabels)
        st_local("heatmax",strofreal(n+.5))
        notes="Cells: "+g.statistic+fegraph__choose(g.net," (net)"," (gross)")+"; color range "+strofreal(clim[1],"%9.3g")+" to "+strofreal(clim[2],"%9.3g")+"."
        st_local("scale_note",notes)
        st_local("colormin",strofreal(clim[1])); st_local("colormax",strofreal(clim[2]))
    }
    else {
        out=J(n,17,.); labs=g.labels[ni]
        out[,(1,2,3)]=g.N[ni,(6,7,1)]
        nc=J(n,1,0); clim=(.,.); wlim=(.,.)
        ix=fegraph__which(g.N[ni,1]:==0)
        if(rows(ix)) nc[ix]=fegraph__colorbins(g.N[ni[ix],3],0,clim,fegraph__flag("categorical"))
        ix=fegraph__which(g.N[ni,1]:==1)
        if(rows(ix)) nc[ix]=fegraph__colorbins(g.N[ni[ix],3],0,wlim,0)
        out[,4]=nc
        st_local("workermin",strofreal(wlim[1])); st_local("workermax",strofreal(wlim[2]))
        maxsize=max((max(fegraph__pick(g.N[ni,2],g.N[ni,1]:!=1)),1e-12))
        if(fegraph__opt("sizemax")>0) maxsize=fegraph__opt("sizemax")
        ns=ceil(4*sqrt(g.N[ni,2]/maxsize)); ns=rowmax((J(n,1,1),rowmin((J(n,1,4),ns))))
        out[,5]=ns
        nodeclass=J(rows(g.N),1,1); nodeclass[ni]=ns
        weight=g.E[ei,11]
        maxweight=0
        if(rows(fegraph__pick(weight,weight:<.))) maxweight=max(fegraph__pick(weight,weight:<.))
        if(fegraph__opt("widthmax")>0) maxweight=fegraph__opt("widthmax")
        es=J(m,1,1)
        if(maxweight>0) es=rowmax((J(m,1,1),rowmin((J(m,1,4),ceil(4*sqrt(weight/maxweight))))))
        ix=fegraph__which(weight:>=.); if(rows(ix)) es[ix]=J(rows(ix),1,1)
        ec=fegraph__colorbins(g.E[ei,9],1,elim,0)
        if(g.edgecolor=="none") ec=J(m,1,0)
        sx=max((max(out[,1])-min(out[,1]),.1)); sy=max((max(out[,2])-min(out[,2]),.1))
        lanes=J(m,1,0)
        if(g.type=="ladder") lanes=fegraph__ladderlanes(g,ei)
        out=out \ J(m*26,17,.)
        labs=labs \ J(m*26,1,"")
        for(i=1;i<=m;i++) {
            a=g.E[ei[i],1]; b=g.E[ei[i],2]
            if(a==b) continue
            x1=g.N[a,6]; y1=g.N[a,7]; x2=g.N[b,6]; y2=g.N[b,7]
            dx=(x2-x1)/sx; dy=(y2-y1)/sy; d=sqrt(dx^2+dy^2)
            if(d<1e-10) fegraph__fail("connected displayed nodes share coordinates; use rank bins or distinct coordinates")
            ra=0; rb=0
            if(g.directed) {
                ra=min((.015+.014*nodeclass[a],d*.22)); rb=min((.025+.016*nodeclass[b],d*.24))
            }
            if(lanes[i]!=0) {
                if(g.directed) { ra=.008+.006*nodeclass[a]; rb=.015+.007*nodeclass[b]; }
                curve=fegraph__ladderpath((x1/sx,y1/sy),(x2/sx,y2/sy),lanes[i],ra,rb)
            }
            else {
                // Preserve straight/reciprocal routing in other views and outside flows.
                x1=x1+ra*sx*dx/d; y1=y1+ra*sy*dy/d
                x2=x2-rb*sx*dx/d; y2=y2-rb*sy*dy/d
                cx=(x1+x2)/2; cy=(y1+y2)/2
                if(g.directed & !g.net & g.E[ei[i],6]>0) { cx=cx-.12*dy*sx; cy=cy+.12*dx*sy; }
            }
            paths=J(26,17,.)
            for(j=1;j<=25;j++) {
                if(lanes[i]!=0) { x=curve[j,1]*sx; y=curve[j,2]*sy; }
                else {
                    q=(j-1)/24; x=(1-q)^2*x1+2*(1-q)*q*cx+q^2*x2; y=(1-q)^2*y1+2*(1-q)*q*cy+q^2*y2
                }
                paths[j,(6,7,12,13)]=(x,y,ec[i],es[i])
                if(j==25 & g.directed) paths[j,(8,9,10,11)]=(px,py,x,y)
                px=x; py=y
            }
            // Missing final row separates paths in each style layer.
            paths[26,(12,13)]=(ec[i],es[i])
            out[|n+(i-1)*26+1,1 \ n+i*26,17|]=paths
        }
        notes="Node color: "+fegraph__choose(clim[1]<.,strofreal(clim[1],"%9.3g")+" to "+strofreal(clim[2],"%9.3g"),"not supplied")+"; gray = missing."
        if(wlim[1]<.) notes=notes+" Worker color: "+strofreal(wlim[1],"%9.3g")+" to "+strofreal(wlim[2],"%9.3g")+"."
        notes=notes+" Sizes use 4 global area classes (max "+strofreal(maxsize,"%9.3g")+")."
        st_local("scale_note",notes)
        st_local("colormin",strofreal(clim[1])); st_local("colormax",strofreal(clim[2]))
        st_local("edge_note","Widths: "+g.edgesize+", 4 classes; max "+strofreal(maxweight,"%9.3g")+". "+fegraph__choose(g.edgecolor!="none","Color: "+g.edgecolor+", orange = loss; teal = gain.",""))
        if(g.type=="ladder") {
            ix=fegraph__which((g.N[,1]:==2):&g.N[,9])
            if(rows(ix)) {
                lo=min(fegraph__pick(g.N[,7],(g.N[,1]:==0):&g.N[,9])); hi=g.N[ix[1],7]
                st_local("outside_line",strofreal((lo+hi)/2))
                st_local("edge_note",st_local("edge_note")+" Outside state has no measured level/rank.")
                vec=fegraph__pick(g.N[,7],(g.N[,1]:==0):&g.N[,9])
                xlabels=""
                for(j=0;j<=4;j++) xlabels=xlabels+" "+strofreal(min(vec)+(max(vec)-min(vec))*j/4)
                st_local("ladderlabels",xlabels)
            }
        }
    }
    st_local("coverage_note",fegraph__choose(g.directed,"Shown gross flow ",fegraph__choose(g.type=="bipartite","Shown matches ","Shown shared-worker connections "))+strofreal(g.stats[14],"%12.5g")+" / "+strofreal(g.stats[13],"%12.5g")+"; boundary flow "+strofreal(g.stats[15],"%12.5g")+"; within-node moves "+strofreal(g.stats[16],"%12.5g")+".")
    fegraph__write(out,("nx","ny","nkind","ncolor","nsize","ex","ey","ax","ay","bx","by","ecolor","esize","hx","hlo","hhi","hcolor"))
    // Printable graph labels only: tables retain complete IDs/labels.
    fegraph__strings("nlabel",substr(labs,1,80))
}
end
