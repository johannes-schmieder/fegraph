// Unit execution in a small DOM/Canvas mock, not a browser rendering test.
'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),directory=process.argv[2]||path.join(root,'build/animation'),files=fs.readdirSync(directory).filter(f=>f.endsWith('.html'));
for(const file of files){
 const html=fs.readFileSync(path.join(directory,file),'utf8'),payload=html.match(/<script type="application\/json" id="fegraph-data">([\s\S]*?)<\/script>/)[1],data=JSON.parse(payload),script=[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1];
 let calls=0,raf;
 const context=new Proxy({}, {get:(t,k)=>k in t?t[k]:(...args)=>{for(const a of args)if(typeof a==='number')assert.ok(Number.isFinite(a),`${file}: ${k} nonfinite`);calls++;},set:(t,k,v)=>(t[k]=v,true)});
 class Element{
  constructor(){this.textContent='';this.style={};this.hidden=false;this.children=[];this.handlers={};this.options=[];this.value='';this.parentElement=this;}
  append(...v){this.children.push(...v);}replaceChildren(...v){this.children=[...v];}setAttribute(){}addEventListener(k,v){this.handlers[k]=v;}getContext(){return context;}getBoundingClientRect(){return {width:850,height:520,left:0,top:0};}setPointerCapture(){}add(v){this.options.push(v);}
 }
 const ids={};for(const id of [...html.matchAll(/id="([^"]+)"/g)].map(m=>m[1]))ids[id]=new Element();ids['fegraph-data'].textContent=payload;ids.speed.options=[.25,.5,1,2,4].map(v=>({value:String(v)}));
 const document={getElementById:id=>{assert.ok(ids[id],id);return ids[id];},createElement:()=>new Element(),createTextNode:v=>v,documentElement:{dataset:{}},hidden:false};
 const ctx={document,window:{devicePixelRatio:2,addEventListener(){}},matchMedia:()=>({matches:false,addEventListener(){}}),getComputedStyle:()=>({getPropertyValue:k=>({'--ink':'#17223a','--muted':'#5c6a86','--line':'#d8dfea','--accent':'#3d5fd0','--surface':'#fff','--neutral':'#eee'}[k])}),ResizeObserver:class{observe(){}},Option:class{constructor(t,v){this.value=v;}},requestAnimationFrame:f=>{raf=f;},console};
 vm.runInNewContext(script,ctx,{timeout:2000,filename:file});assert.ok(calls>0);assert.ok(!ids.play.disabled,file+': viewer initialized');
 assert.ok(html.indexOf('id="play"')<html.indexOf('id="graph"'),file+': controls precede plot');
 const checkEmpty=frame=>{const expected=!frame.values.some(v=>v[3]!==0);assert.equal(ids.empty.hidden,!expected,file+': empty-period notice');if(expected)assert.ok(ids.empty.textContent.length>0);};
 checkEmpty(data.frames[0]);
 for(let i=0;i<70;i++)raf(i*100);
 ids.play.handlers.click();ids.restart.handlers.click();ids.theme.handlers.change();ids.reset.handlers.click();
 if(data.mode==='time'){ids.next.handlers.click();assert.equal(ids.period.textContent,data.frames[Math.min(1,data.frames.length-1)].label);ids.timeline.value=data.frames.length-1;ids.timeline.handlers.input();assert.equal(ids.period.textContent,data.frames.at(-1).label);checkEmpty(data.frames.at(-1));ids.prev.handlers.click();}
 ids.graph.handlers.pointermove({clientX:200,clientY:200});ids.graph.handlers.pointerleave();
 assert.ok(ids.details.children.length>0);
 const originalGetContext=ids.graph.getContext;
 ids.graph.getContext=()=>null;
 vm.runInNewContext(script,{...ctx,console:{error(){}}},{timeout:2000,filename:file});
 assert.match(ids.status.textContent,/2D canvas/);assert.equal(ids.play.disabled,true);
 ids.graph.getContext=originalGetContext;
}
console.log('FEGRAPH_ANIMATION_VIEWER_UNIT_OK ('+files.length+' artifacts)');
