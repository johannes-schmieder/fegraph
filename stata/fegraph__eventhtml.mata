version 16.0
mata:
void fegraph__eventhtml(string scalar filename) {
    real scalar h,t,i,j
    real matrix x
    real colvector cohorts,ix
    string scalar line,title,subtitle,note,s
    string rowvector keys
    x=st_data(.,("cohort","origin_bin","destination_bin","event_time","mean","se","lower","upper","n_events","n_workers","shown"))
    ix=selectindex(x[,11]:==1); x=x[ix,.]
    cohorts=uniqrows(select(x[,1],x[,1]:<.))
    if(st_local("anim_mode")=="time" & !rows(cohorts)) {
        errprintf("no arrival cohort passes mincell() and the displayed group selection\n")
        _error(2000)
    }
    title=st_local("title"); subtitle=st_local("subtitle"); note=st_local("note")
    if(st_local("anim_mode")=="time") note=note+" Playback compares arrival-period cohorts, with fixed pooled bins and axes; each cohort can contain different workers."
    else note=note+" Playback highlights relative event time in pooled mean profiles; it does not animate individual workers."
    if(st_local("normalize")!="") note=note+" Each event is normalized to its own outcome at period "+st_local("normalize")+"."
    if(st_local("anim_title")!="") title=st_local("anim_title")
    if(st_local("anim_subtitle")!="") subtitle=st_local("anim_subtitle")
    if(st_local("anim_note")!="") note=st_local("anim_note")
    if(st_local("anim_notitle")!="") title=""
    if(st_local("anim_nosubtitle")!="") subtitle=""
    if(st_local("anim_nonotes")!="") note=""
    h=fopen(filename,"w"); t=fopen(st_local("anim_template"),"r")
    while((line=fget(t))!=J(0,0,"")) {
        if(line!="<!-- FEGRAPH_DATA -->") { fput(h,line); continue; }
        fput(h,"<script type="+char(34)+"application/json"+char(34)+" id="+char(34)+"fegraph-data"+char(34)+">")
        fput(h,"{"+fegraph__json("type")+":"+fegraph__json("eventstudy")+","+fegraph__json("version")+":"+fegraph__json("0.8.0")+",")
        fput(h,fegraph__json("title")+":"+fegraph__json(title)+","+fegraph__json("subtitle")+":"+fegraph__json(subtitle)+","+fegraph__json("note")+":"+fegraph__json(note)+",")
        keys=("mode","theme","speed")
        for(i=1;i<=cols(keys);i++) fput(h,fegraph__json(keys[i])+":"+fegraph__json(st_local("anim_"+keys[i]))+",")
        keys=("ytitle","grouping","wagescale","normalize")
        for(i=1;i<=cols(keys);i++) fput(h,fegraph__json(keys[i])+":"+fegraph__json(st_local(keys[i]))+",")
        keys=("pre","post","delta","mincell","cilevel","N_events","N_workers","N_shown_events","N_candidates","N_excluded_window","N_excluded_outcome","N_excluded_group")
        for(i=1;i<=cols(keys);i++) fput(h,fegraph__json(keys[i])+":"+fegraph__num(strtoreal(st_local(keys[i])))+",")
        fput(h,fegraph__json("overlay")+":"+fegraph__num(st_local("overlay")!="")+","+fegraph__json("ci")+":"+fegraph__num(st_local("ci")!="")+",")
        fput(h,fegraph__json("legend")+":"+fegraph__num(st_local("anim_nolegend")=="")+","+fegraph__json("command")+":"+fegraph__num(st_local("anim_nocommand")=="")+",")
        fput(h,fegraph__json("palette")+":"+fegraph__stringsjson(tokens(st_local("anim_palette")))+",")
        fput(h,fegraph__json("origins")+":"+fegraph__vector(strtoreal(tokens(st_local("origins"))))+",")
        fput(h,fegraph__json("destinations")+":"+fegraph__vector(strtoreal(tokens(st_local("destinations"))))+",")
        fput(h,fegraph__json("cohorts")+":"+fegraph__vector(cohorts)+",")
        // Write one row per line to avoid Stata's line-length limits.
        fput(h,fegraph__json("rows")+":[")
        for(i=1;i<=rows(x);i++) {
            s=""; if(i>1) s=",";
            fput(h,s+fegraph__vector(x[i,.]))
        }
        fput(h,"]}</script>")
    }
    fclose(t); fclose(h)
    i=strtoreal(st_local("span"))
    if(st_local("anim_mode")=="time") i=rows(cohorts)
    st_local("anim_frames",strofreal(i))
}
end
