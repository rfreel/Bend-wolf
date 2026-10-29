import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import L from '../build/Logic.mjs';
import R from '../build/Rewrite.mjs';
import A from '../build/Abstract.mjs';
import Ar from '../build/Arithmetic.mjs';
import G from '../build/Graph.mjs';
import D from '../build/Dynamics.mjs';
import O from '../build/Optimize.mjs';
import I from '../build/Inference.mjs';
import Pat from '../build/Pattern.mjs';
import Synth from '../build/Synthesis.mjs';
import Q from '../build/Quantify.mjs';
import {isDeepStrictEqual} from 'node:util';

const T={$:'ETrue'}, F={$:'EFalse'};
const v=id=>({$:'EVar',id});
const no=expr=>({$:'ENot',expr});
const and=(left,right)=>({$:'EAnd',left,right});
const or=(left,right)=>({$:'EOr',left,right});
const xor=(left,right)=>({$:'EXor',left,right});
const evalRef=(e,m)=>{
  switch(e.$){
    case 'ETrue': return true; case 'EFalse': return false;
    case 'EVar': return ((m >>> e.id)&1)===1;
    case 'ENot': return !evalRef(e.expr,m);
    case 'EAnd': return evalRef(e.left,m)&&evalRef(e.right,m);
    case 'EOr': return evalRef(e.left,m)||evalRef(e.right,m);
    case 'EXor': return evalRef(e.left,m)!==evalRef(e.right,m);
    default: throw Error('invalid test expression');
  }
};
let seed=0x6d2b79f5;
function rnd(max){seed^=seed<<13; seed^=seed>>>17; seed^=seed<<5; return (seed>>>0)%max;}
function randomExpr(depth){
  if(depth===0){const k=rnd(5); return k===3?T:k===4?F:v(k);}
  const k=rnd(6); if(k===0)return no(randomExpr(depth-1));
  if(k<=3){const x=randomExpr(depth-1),y=randomExpr(depth-1); return [and,or,xor][k-1](x,y);}
  return randomExpr(0);
}
const ref=JSON.parse(readFileSync(new URL('../evidence/wolfram_reference.json',import.meta.url)));
const [a,b,c]=[v(0),v(1),v(2)];
const examples=[and(and(or(or(a,b),c),or(no(a),no(b))),or(no(b),no(c))),xor(a,b),or(and(a,b),and(a,no(b))),or(no(and(a,b)),c),and(or(a,b),or(no(a),c)),no(xor(a,b)),xor(xor(a,b),c),or(or(and(a,b),and(b,c)),and(a,c))];
for(let i=0;i<examples.length;i++){
  const actual=Array.from({length:8},(_,m)=>Number(L.eval(examples[i],m)));
  assert.deepEqual(actual,ref.truths[i],`Wolfram truth table ${i}`);
}
let booleanAssignments=0, abstractChecks=0, coreChecks=0;
for(let i=0;i<320;i++){
  const e=randomExpr(4), table=Array.from({length:8},(_,m)=>evalRef(e,m));
  for(let m=0;m<8;m++){assert.equal(L.eval(e,m),table[m]); booleanAssignments++;}
  const propagated=L.propagate(3,e);
  if (!table.includes(true)) assert.equal(propagated.$,'PropagationUnsat');
  else {
    let mustTrue=0,mustFalse=0;
    for(let bit=0;bit<3;bit++){
      const models=table.flatMap((yes,m)=>yes?[m]:[]);
      if(models.every(m=>(m&(1<<bit))!==0))mustTrue|=1<<bit;
      if(models.every(m=>(m&(1<<bit))===0))mustFalse|=1<<bit;
    }
    assert.deepEqual(propagated,{$:'Propagated',must_true:mustTrue,must_false:mustFalse});
  }
  const sat=L.satisfy(3,e), first=table.indexOf(true);
  if(first<0) assert.equal(sat.$,'Unsat'); else assert.deepEqual(sat,{$:'Sat',assignment:first});
  const simplified=R.simplify(e); assert.equal(L.equivalent(3,e,simplified).$,'Equivalent');
  const bits=table.reduce((s,x,i)=>s+(x?2**i:0),0);
  assert.deepEqual(R.truth_table(3,e),{$:'TruthKey',bits});
  const varId=rnd(3), ex=L.exists(e,varId), all=L.forall(e,varId);
  for(let m=0;m<8;m++){
    const a0=m&~(1<<varId),a1=m|(1<<varId);
    assert.equal(L.eval(ex,m),table[a0]||table[a1]);
    assert.equal(L.eval(all,m),table[a0]&&table[a1]);
  }
  for(let known=0;known<8;known++) for(let val=0;val<8;val++) if((val&~known)===0){
    let concrete=0; for(let m=0;m<8;m++) if((m&known)===val) concrete|=table[m]?2:1;
    const out=A.analyze(3,e,known,val); assert.equal(out.$,'AbstractValue');
    assert.equal(concrete & ~out.possible,0,'abstract output missed a concrete value'); abstractChecks++;
  }
  const ce=A.counterexample(3,e);
  if(first<0)assert.equal(ce.$,'Safe'); else {assert.equal(ce.$,'Violation');assert.equal(table[ce.assignment],true);}
  if(i<60){
    const cs=[e,randomExpr(3),randomExpr(3),randomExpr(3)];
    const core=L.minimal_core4(3,...cs);
    const satMask=mask=>Array.from({length:8},(_,m)=>cs.every((q,j)=>!(mask&(1<<j))||evalRef(q,m))).some(Boolean);
    if(core.$==='NoCore') assert.equal(satMask(15),true);
    else {assert.equal(core.$,'Core'); assert.equal(satMask(core.mask),false);for(let j=0;j<4;j++)if(core.mask&(1<<j))assert.equal(satMask(core.mask&~(1<<j)),true);}
    coreChecks++;
  }
}
function randomPattern(depth){
 if(depth===0){let k=rnd(6);if(k<4)return {$:'Meta',id:k};return k===4?{$:'PTrue'}:{$:'PAtom',id:rnd(3)};}
 let k=rnd(5);if(k===0)return {$:'PNot',expr:randomPattern(depth-1)};
 if(k<=3)return {$:['PAnd','POr','PXor'][k-1],left:randomPattern(depth-1),right:randomPattern(depth-1)};
 return randomPattern(0);
}
function metas(p){switch(p.$){case'Meta':return [p.id];case'PNot':return metas(p.expr);case'PAnd':case'POr':case'PXor':return [...metas(p.left),...metas(p.right)];default:return [];}}
function matchRef(p,e,env){
 if(p.$==='Meta'){if(p.id in env)return isDeepStrictEqual(env[p.id],e);env[p.id]=e;return true;}
 if(p.$==='PTrue')return e.$==='ETrue';if(p.$==='PFalse')return e.$==='EFalse';
 if(p.$==='PAtom')return e.$==='EVar'&&e.id===p.id;
 if(p.$==='PNot')return e.$==='ENot'&&matchRef(p.expr,e.expr,env);
 const target={PAnd:'EAnd',POr:'EOr',PXor:'EXor'}[p.$];
 return e.$===target&&matchRef(p.left,e.left,env)&&matchRef(p.right,e.right,env);
}
function instantiateRef(p,env){switch(p.$){case'Meta':return env[p.id];case'PTrue':return T;case'PFalse':return F;case'PAtom':return v(p.id);case'PNot':return no(instantiateRef(p.expr,env));case'PAnd':return and(instantiateRef(p.left,env),instantiateRef(p.right,env));case'POr':return or(instantiateRef(p.left,env),instantiateRef(p.right,env));case'PXor':return xor(instantiateRef(p.left,env),instantiateRef(p.right,env));}}
function rewriteRef(e,p,t){const env={};if(matchRef(p,e,env))return instantiateRef(t,env);switch(e.$){case'ENot':return no(rewriteRef(e.expr,p,t));case'EAnd':return and(rewriteRef(e.left,p,t),rewriteRef(e.right,p,t));case'EOr':return or(rewriteRef(e.left,p,t),rewriteRef(e.right,p,t));case'EXor':return xor(rewriteRef(e.left,p,t),rewriteRef(e.right,p,t));default:return e;}}
let patternChecks=0;
for(let i=0;i<300;i++){
 const p=randomPattern(3),ids=metas(p),t=ids.length?{$:'PNot',expr:{$:'Meta',id:ids[rnd(ids.length)]}}:{$:'PFalse'},e=randomExpr(4);
 assert.deepEqual(Pat.rewrite_all(e,p,t),{$:'Built',expr:rewriteRef(e,p,t)});
 patternChecks++;
}
let grammarChecks=0;
for(let flags=0;flags<16;flags++){
  const config={$:'Grammar',allow_not:!!(flags&1),allow_and:!!(flags&2),allow_or:!!(flags&4),allow_xor:!!(flags&8)};
  const atoms=[F,T,v(0),v(1)];if(config.allow_not)atoms.push(no(v(0)),no(v(1)));
  const possible=new Set();const key=e=>Array.from({length:4},(_,m)=>evalRef(e,m)?1<<m:0).reduce((a,b)=>a|b,0);
  for(const e of atoms)possible.add(key(e));
  for(const x of atoms)for(const y of atoms){if(config.allow_and)possible.add(key(and(x,y)));if(config.allow_or)possible.add(key(or(x,y)));if(config.allow_xor)possible.add(key(xor(x,y)));}
  for(let target=0;target<16;target++){
    const got=Synth.synthesize_grammar(2,target,config);
    if(possible.has(target)){assert.equal(got.$,'SynthExpr');assert.equal(key(got.expr),target);}else assert.equal(got.$,'GrammarExhausted');
    grammarChecks++;
  }
}
let quantifierChecks=0;
const toIneq=(a,b,strict,offset=0)=>({$:'Inequality',ap:Math.max(a,0)+offset,an:Math.max(-a,0)+offset,bp:Math.max(b,0)+offset,bn:Math.max(-b,0)+offset,strict});
function witnessExists(i,j){
 const boundaries=[];for(const c of [i,j])if(c.a!==0){let p=BigInt(-c.b),q=BigInt(c.a);if(q<0n){p=-p;q=-q;}boundaries.push([p,q]);}
 const points=[[-10n,1n],[10n,1n],...boundaries];
 for(let u=0;u<boundaries.length;u++)for(let v=u+1;v<boundaries.length;v++){const [p,q]=boundaries[u],[r,s]=boundaries[v];points.push([p*s+r*q,2n*q*s]);}
 return points.some(([p,q])=>[i,j].every(c=>{const z=BigInt(c.a)*p+BigInt(c.b)*q;return c.strict?z<0n:z<=0n;}));
}
const inequalities=[];for(let a=-2;a<=2;a++)for(let b=-2;b<=2;b++)for(const strict of [false,true])inequalities.push({a,b,strict});
for(const i of inequalities)for(const j of inequalities){
 const a=toIneq(i.a,i.b,i.strict,1),b=toIneq(j.a,j.b,j.strict,2);
 assert.equal(Q.exists_pair(a,b).$==='RealTrue',witnessExists(i,j));
 const universal=[i,j].every(c=>c.a===0&&(c.strict?c.b<0:c.b<=0));
 assert.equal(Q.forall_pair(a,b).$==='RealTrue',universal);quantifierChecks++;
}
function graphFromCompact(n,x){let g=0;for(let u=0;u<n;u++)for(let w=0;w<n;w++)if(x&(1<<(n*u+w)))g|=1<<(4*u+w);return g>>>0;}
function edge(g,u,w){return (g>>>(4*u+w))&1;}
function permutations(a){if(!a.length)return [[]];return a.flatMap((x,i)=>permutations(a.filter((_,j)=>j!==i)).map(t=>[x,...t]));}
function relabel(g,n,p){let out=0;for(let u=0;u<n;u++)for(let w=0;w<n;w++)if(edge(g,u,w))out|=1<<(4*p[u]+p[w]);return out>>>0;}
function distance(g,n,start,goal){const d=Array(n).fill(Infinity);d[start]=0;const queue=[start];for(let i=0;i<queue.length;i++){const u=queue[i];for(let w=0;w<n;w++)if(edge(g,u,w)&&d[w]===Infinity){d[w]=d[u]+1;queue.push(w);}}return d[goal];}
function cycle(g,n){let t=Array.from({length:n},(_,u)=>Array.from({length:n},(_,w)=>Boolean(edge(g,u,w))));for(let k=0;k<n;k++)for(let i=0;i<n;i++)for(let j=0;j<n;j++)t[i][j] ||= t[i][k]&&t[k][j];return t.some((r,i)=>r[i]);}
let graphChecks=0,cutChecks=0;
const perms=permutations([0,1,2]);
for(let x=0;x<512;x++){
  const g=graphFromCompact(3,x), canonical=Math.min(...perms.map(p=>relabel(g,3,p)));
  assert.deepEqual(G.canonical(3,g),{$:'GraphKey',nodes:3,edges:canonical});
  const cyc=cycle(g,3);assert.equal(G.has_cycle(3,g).$,cyc?'Cyclic':'Acyclic');
  const topo=G.topological(3,g);
  if(cyc) assert.equal(topo.$,'Cyclic'); else {assert.equal(topo.$,'Topology');for(let u=0;u<3;u++)for(let w=0;w<3;w++)if(edge(g,u,w))assert.ok(G.mapped(topo.code,u)<G.mapped(topo.code,w));}
  for(let u=0;u<3;u++)for(let w=0;w<3;w++){
    const dist=distance(g,3,u,w), result=G.shortest(3,g,u,w);
    if(dist===Infinity)assert.equal(result.$,'Unreachable');else assert.deepEqual(result,{$:'Distance',value:dist});
    const path=G.shortest_path(3,g,u,w);
    if(dist===Infinity)assert.equal(path.$,'Unreachable');else {
      assert.equal(path.$,'Path');assert.equal(path.length,dist);
      assert.equal(path.nodes&3,u);assert.equal((path.nodes>>>(2*dist))&3,w);
      for(let k=0;k<dist;k++)assert.equal(edge(g,(path.nodes>>>(2*k))&3,(path.nodes>>>(2*(k+1)))&3),1);
    }
    graphChecks++;
  }
  let sym=true;for(let u=0;u<3;u++)for(let w=0;w<3;w++)sym &&=edge(g,u,w)===edge(g,w,u);
  if(sym){const costs=[];for(let s=1;s<7;s++){let cost=0;for(let u=0;u<3;u++)for(let w=0;w<3;w++)if((s&(1<<u))&&!(s&(1<<w)))cost+=edge(g,u,w);costs.push(cost);}assert.equal(G.min_cut(3,g).size,Math.min(...costs));cutChecks++;}
}
let reachabilityCases=0;
for(const startCompact of [0,2,21,42]){
  const start=graphFromCompact(3,startCompact);
  const startPop=Array.from(startCompact.toString(2)).filter(x=>x==='1').length;
  for(let k=0;k<=3;k++){
    const representatives=new Set();
    for(let compact=0;compact<512;compact++){
      const pop=Array.from(compact.toString(2)).filter(x=>x==='1').length;
      if((compact&startCompact)!==startCompact || pop-startPop>k)continue;
      const g=graphFromCompact(3,compact);
      representatives.add(Math.min(...perms.map(p=>relabel(g,3,p))));
    }
    assert.equal(G.reduced_reachable_count(3,start,k).count,representatives.size);
    reachabilityCases++;
  }
}
for(let n=0;n<=4;n++){
  const ps=permutations(Array.from({length:n},(_,i)=>i));
  const count=n<=2?2**(n*n):n===3?0:1024;
  for(let j=0;j<count;j++){
    const g=graphFromCompact(n,n===4?rnd(65536):j);
    const expected=Math.min(...ps.map(p=>relabel(g,n,p)));
    assert.deepEqual(G.canonical(n,g),{$:'GraphKey',nodes:n,edges:expected});
  }
}
assert.deepEqual([0,1,2,3].map(n=>G.reduced_count(n).count),ref.unlabeledDirectedWithLoops);
assert.equal(G.shortest(3,2+64,0,2).value,ref.shortest);
const triangle=2+4+16+64+256+512;
assert.equal(G.min_cut(3,triangle).size,ref.triangleCut);
const mask32=(1n<<32n)-1n;
const av={$:'AVar'}, con=value=>({$:'AConst',value}), plus=(left,right)=>({$:'APlus',left,right}), mul=(left,right)=>({$:'AMul',left,right});
function evalBig(e,x){switch(e.$){case'AConst':return BigInt(e.value);case'AVar':return BigInt(x);case'APlus':return (evalBig(e.left,x)+evalBig(e.right,x))&mask32;case'AMul':return (evalBig(e.left,x)*evalBig(e.right,x))&mask32;}}
function randomAr(d){if(!d)return rnd(2)?av:con(rnd(0x100000000));return rnd(2)?plus(randomAr(d-1),randomAr(d-1)):mul(randomAr(d-1),randomAr(d-1));}
let arChecks=0;
for(let i=0;i<200;i++){
  const e=randomAr(3), x=rnd(0x100000000), value=Number(evalBig(e,x));
  assert.equal(Ar.eval(e,x),value); const p=Ar.polynomial(e);
  if(p.$==='Polynomial') {const y=BigInt(x);const pp=(BigInt(p.c0)+BigInt(p.c1)*y+BigInt(p.c2)*y*y+BigInt(p.c3)*y*y*y)&mask32;assert.equal(Number(pp),value);}
  arChecks++;
}
let exactRootChecks=0;
for(let i=0;i<200;i++){
 const ca=Array.from({length:4},()=>rnd(20)),cb=Array.from({length:4},()=>rnd(20)),limit=rnd(40);
 const mk=c=>({$:'ExactPolynomial',c0:c[0],c1:c[1],c2:c[2],c3:c[3]});
 const evaluate=(c,x)=>c.reduce((sum,a,j)=>sum+BigInt(a)*BigInt(x)**BigInt(j),0n);
 const roots=Array.from({length:limit+1},(_,x)=>x).filter(x=>evaluate(ca,x)===evaluate(cb,x));
 const got=Ar.exact_roots(mk(ca),mk(cb),limit);
 if(roots.length)assert.deepEqual(got,{$:'ExactRoots',first:roots[0],count:roots.length});else assert.equal(got.$,'ExactNoRoot');
 exactRootChecks++;
}
let exactFactorChecks=0,exactExpandChecks=0;
const ep=c=>({$:'ExactPolynomial',c0:Number(c[0]),c1:Number(c[1]),c2:Number(c[2]),c3:Number(c[3])});
for(let i=0;i<150;i++){
 const r=BigInt(rnd(11)),q=[BigInt(rnd(11)),BigInt(rnd(11)),BigInt(rnd(11))];
 const c=[-r*q[0],q[0]-r*q[1],q[1]-r*q[2],q[2]],pos=c.map(x=>x>0n?x:0n),neg=c.map(x=>x<0n?-x:0n);
 const got=Ar.exact_factor(ep(pos),ep(neg),10);assert.equal(got.$,'ExactFactor');
 const x=BigInt(got.root),a=BigInt(got.q0p)-BigInt(got.q0n),b=BigInt(got.q1p)-BigInt(got.q1n),d=BigInt(got.q2p)-BigInt(got.q2n);
 assert.deepEqual([-x*a,a-x*b,b-x*d,d],c);exactFactorChecks++;
}
function randomExact(d){if(!d)return rnd(2)?{$:'ExactVar'}:{$:'ExactConst',value:rnd(5)};return {$:rnd(2)?'ExactAdd':'ExactMul',left:randomExact(d-1),right:randomExact(d-1)};}
function exactCoeffs(e){
 if(e.$==='ExactVar')return [0n,1n,0n,0n];if(e.$==='ExactConst')return [BigInt(e.value),0n,0n,0n];
 const a=exactCoeffs(e.left),b=exactCoeffs(e.right);if(!a||!b)return null;
 let c=Array(7).fill(0n);
 if(e.$==='ExactAdd')for(let i=0;i<4;i++)c[i]=a[i]+b[i];else for(let i=0;i<4;i++)for(let j=0;j<4;j++)c[i+j]+=a[i]*b[j];
 if(c.slice(4).some(x=>x!==0n)||c.slice(0,4).some(x=>x>1000n))return null;return c.slice(0,4);
}
for(let i=0;i<200;i++){
 const e=randomExact(3),expected=exactCoeffs(e),got=Ar.exact_expand(e);
 if(expected)assert.deepEqual(got,{$:'ExactExpanded',poly:ep(expected)});else assert.equal(got.$,'ExpansionOverflow');
 exactExpandChecks++;
}
let factoringChecks=0;
for(let i=0;i<150;i++){
 const r=BigInt(rnd(11)),q=[BigInt(rnd(0x100000000)),BigInt(rnd(0x100000000)),BigInt(rnd(0x100000000))];
 const c=[(-r*q[0])&mask32,(q[0]-r*q[1])&mask32,(q[1]-r*q[2])&mask32,q[2]];
 const got=Ar.factor_monic({$:'Polynomial',c0:Number(c[0]),c1:Number(c[1]),c2:Number(c[2]),c3:Number(c[3])},10);
 assert.equal(got.$,'Factorization');const x=BigInt(got.root),t=[BigInt(got.q0),BigInt(got.q1),BigInt(got.q2)];
 assert.deepEqual([(-x*t[0])&mask32,(t[0]-x*t[1])&mask32,(t[1]-x*t[2])&mask32,t[2]],c);
 factoringChecks++;
}
const cube=mul(mul(plus(av,con(1)),plus(av,con(1))),plus(av,con(1)));
const poly=Ar.polynomial(cube);assert.deepEqual([poly.c0,poly.c1,poly.c2,poly.c3],ref.polyCoefficients);
assert.deepEqual(Array.from({length:6},(_,x)=>Ar.eval(cube,x)),ref.polyAt0to5);
const fib=D.recurrence(0,1,1,2,3,5);assert.deepEqual([fib.first,fib.second],ref.fibonacciRecurrence);
let invariantChecks=0;
for(let m0=0;m0<3;m0++)for(let m1=0;m1<3;m1++)for(let m2=0;m2<3;m2++){
 const map=[m0,m1,m2],code=m0+4*m1+16*m2;
 for(let allowed=0;allowed<8;allowed++){
  let keep=allowed,prior=-1;while(keep!==prior){prior=keep;for(let i=0;i<3;i++)if((keep&(1<<i))&&!(prior&(1<<map[i])))keep &= ~(1<<i);}
  assert.deepEqual(D.invariant(3,code,allowed),{$:'Invariant',mask:keep});invariantChecks++;
 }
}
const bayes=I.bayes(1,3,4,5,1,10);assert.equal(bayes.numerator*ref.bayesDenominator,bayes.denominator*ref.bayesNumerator);
let bayesChecks=0,flowChecks=0;
for(let q=1;q<=5;q++)for(let p=0;p<=q;p++)for(let bden=1;bden<=4;bden++)for(let anum=0;anum<=bden;anum++)for(let cnum=0;cnum<=bden;cnum++){
 const got=I.bayes(p,q,anum,bden,cnum,bden), yes=p*anum, den=yes+(q-p)*cnum;
 if(!den)assert.equal(got.$,'ImpossibleEvidence');else {assert.equal(got.$,'Posterior');assert.equal(got.numerator*den,got.denominator*yes);}bayesChecks++;
}
for(let i=0;i<250;i++){
 const demand=rnd(8), c1=rnd(5),c2=rnd(5),c3=rnd(5),v1=rnd(8),v2=rnd(8),v3=rnd(8);
 const candidates=[];for(let x=0;x<=demand;x++)if(x<=c1&&x<=c3&&demand-x<=c2)candidates.push({via:x,direct:demand-x,cost:x*v1+(demand-x)*v2+x*v3});
 const got=O.min_cost_flow(demand,c1,c2,c3,v1,v2,v3);
 if(!candidates.length)assert.equal(got.$,'NoFlow');else {const best=candidates.reduce((p,q)=>q.cost<p.cost?q:p);assert.deepEqual(got,{$:'Flow',...best});}flowChecks++;
}
let flow4Checks=0,linearInvariantChecks=0;
for(let i=0;i<200;i++){
 const es=Array.from({length:4},()=>({from:rnd(4),to:rnd(4),capacity:rnd(4),cost:rnd(6)}));
 const demand=rnd(6), valid=[];
 for(let code=0;code<256;code++){
  const flows=es.map((_,j)=>(code>>>(2*j))&3);if(flows.some((x,j)=>x>es[j].capacity))continue;
  const balance=[0,0,0,0];flows.forEach((x,j)=>{balance[es[j].from]+=x;balance[es[j].to]-=x;});
  if(balance.some((x,j)=>x!==(j===0?demand:j===3?-demand:0)))continue;
  valid.push({code,cost:flows.reduce((sum,x,j)=>sum+x*es[j].cost,0)});
 }
 const obj=e=>({$:'FlowEdge',...e});const network={$:'FlowEdges',a:obj(es[0]),b:obj(es[1]),c:obj(es[2]),d:obj(es[3])};
 const got=O.min_cost_flow4(4,network,0,3,demand);
 if(!valid.length)assert.equal(got.$,'NoFlow');else {
  const best=valid.reduce((p,q)=>q.cost<p.cost?q:p);assert.deepEqual(got,{$:'Flow4',flows:best.code,cost:best.cost});
 }
 flow4Checks++;
}
for(let i=0;i<200;i++){
 const map=Array.from({length:3},()=>rnd(3)), code=map[0]+4*map[1]+16*map[2];
 const xs=Array.from({length:3},()=>rnd(4)), ys=Array.from({length:3},()=>rnd(4));
 const pack=arr=>arr[0]+4*arr[1]+16*arr[2];
 const candidates=[];for(let c=1;c<16;c++){const a=c&3,b=c>>2;if(map.every((j,k)=>a*xs[k]+b*ys[k]===a*xs[j]+b*ys[j]))candidates.push({a,b});}
 const got=D.find_linear_invariant(3,code,pack(xs),pack(ys));
 if(!candidates.length)assert.equal(got.$,'NoLinearInvariant');else assert.deepEqual(got,{$:'LinearInvariant',...candidates[0]});
 linearInvariantChecks++;
}
const flow=O.min_cost_flow(3,2,2,2,3,1,2);assert.equal(flow.cost,ref.flowCost);assert.equal(flow.via,ref.flowMatrix[0][1]);assert.equal(flow.direct,ref.flowMatrix[0][2]);
console.log(JSON.stringify({wolframTruthTables:examples.length,booleanAssignments,patternChecks,grammarChecks,quantifierChecks,abstractChecks,coreChecks,directedGraphs:512,randomFourVertexGraphs:1024,reachabilityCases,graphDistances:graphChecks,undirectedCuts:cutChecks,arithmeticCases:arChecks,exactRootChecks,exactFactorChecks,exactExpandChecks,factoringChecks,invariantChecks,bayesChecks,flowChecks,flow4Checks,linearInvariantChecks,wolframVersion:ref.version}));
