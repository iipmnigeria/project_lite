const DAY = 86400000;
const iso = d => new Date(d).toISOString().slice(0,10);
const addDays = (date,n) => iso(new Date(new Date(date).getTime()+n*DAY));
const dateDiff = (a,b) => Math.max(0,Math.round((new Date(b)-new Date(a))/DAY));

export function normalizeDependencies(task){
  if(Array.isArray(task.dependencies)) return task.dependencies;
  if(task.predecessor) return String(task.predecessor).split(',').filter(Boolean).map(wbs=>({wbs:wbs.trim(),type:'FS',lag:0}));
  return [];
}

export function calculateSchedule(tasks=[]){
  if(!tasks.length)return {tasks:[],projectDuration:0,projectStart:null,projectFinish:null,hasCycle:false,links:[]};
  const dated=tasks.filter(t=>t.start&&t.finish);
  const projectStart=dated.length?dated.map(t=>t.start).sort()[0]:new Date().toISOString().slice(0,10);
  const nodes=new Map(tasks.map(t=>[String(t.wbs),{...t,duration:t.duration||Math.max(1,dateDiff(t.start||projectStart,t.finish||t.start||projectStart)+1),deps:normalizeDependencies(t),successors:[],indegree:0,es:Math.max(0,dateDiff(projectStart,t.start||projectStart))}]));
  const links=[];
  for(const node of nodes.values())for(const dep of node.deps){const pred=nodes.get(String(dep.wbs));if(pred){node.indegree++;pred.successors.push({node,type:dep.type||'FS',lag:Number(dep.lag||0)});links.push({from:pred.wbs,to:node.wbs,type:dep.type||'FS',lag:Number(dep.lag||0)})}}
  const queue=[...nodes.values()].filter(n=>n.indegree===0).sort((a,b)=>a.es-b.es),order=[];
  while(queue.length){const n=queue.shift();order.push(n);n.ef=n.es+n.duration;for(const edge of n.successors){const s=edge.node,lag=edge.lag;let candidate=n.ef+lag;if(edge.type==='SS')candidate=n.es+lag;else if(edge.type==='FF')candidate=n.ef+lag-s.duration;else if(edge.type==='SF')candidate=n.es+lag-s.duration;s.es=Math.max(s.es,candidate);s.indegree--;if(s.indegree===0)queue.push(s)}}
  const hasCycle=order.length!==nodes.size;
  if(hasCycle){for(const n of nodes.values())if(!order.includes(n)){n.ef=n.es+n.duration;order.push(n)}}
  const projectDuration=Math.max(...order.map(n=>n.ef),0);
  for(const n of order){n.lf=projectDuration;n.ls=n.lf-n.duration}
  for(const n of [...order].reverse())for(const edge of n.successors){const s=edge.node,lag=edge.lag;let bound=s.ls-lag;if(edge.type==='SS')bound=s.ls-lag+n.duration;else if(edge.type==='FF')bound=s.lf-lag;else if(edge.type==='SF')bound=s.lf-lag+n.duration;n.lf=Math.min(n.lf,bound);n.ls=n.lf-n.duration}
  const result=order.map(n=>({...n,earlyStart:addDays(projectStart,n.es),earlyFinish:addDays(projectStart,Math.max(n.es,n.ef-1)),lateStart:addDays(projectStart,n.ls),lateFinish:addDays(projectStart,Math.max(n.ls,n.lf-1)),totalFloat:Math.max(0,n.ls-n.es),critical:Math.abs(n.ls-n.es)<0.001}));
  return {tasks:result,projectDuration,projectStart,projectFinish:addDays(projectStart,Math.max(0,projectDuration-1)),hasCycle,links};
}

export function networkLayout(schedule){
  const byWbs=new Map(schedule.tasks.map(t=>[String(t.wbs),t])),layers=new Map();
  const depth=w=>{if(layers.has(w))return layers.get(w);const n=byWbs.get(w);const deps=n?.deps?.filter(d=>byWbs.has(String(d.wbs)))||[];const value=deps.length?Math.max(...deps.map(d=>depth(String(d.wbs))))+1:0;layers.set(w,value);return value};
  schedule.tasks.forEach(t=>depth(String(t.wbs)));
  const groups=[];for(const t of schedule.tasks){const d=layers.get(String(t.wbs));(groups[d]||(groups[d]=[])).push(t)}
  const nodes=[],width=Math.max(900,groups.length*245),height=Math.max(360,Math.max(...groups.map(g=>g?.length||0))*125+70);
  groups.forEach((group,x)=>group.forEach((task,y)=>nodes.push({...task,x:40+x*235,y:35+y*115,width:190,height:78})));
  return {nodes,width,height};
}
