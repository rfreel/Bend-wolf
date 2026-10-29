import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
if(process.argv.length!==3) throw Error('usage: node validate_candidate.mjs candidate.mjs');
const G=(await import(pathToFileURL(resolve(process.argv[2])).href)).default;
const permutations=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];
function expand(x){let g=0;for(let u=0;u<3;u++)for(let v=0;v<3;v++)if(x&(1<<(3*u+v)))g|=1<<(4*u+v);return g;}
function relabel(g,p){let out=0;for(let u=0;u<3;u++)for(let v=0;v<3;v++)if(g&(1<<(4*u+v)))out|=1<<(4*p[u]+p[v]);return out;}
for(let i=0;i<512;i++){
 const edges=expand(i),expected=Math.min(...permutations.map(p=>relabel(edges,p))),got=G.canonical(3,edges);
 if(got.$!=='GraphKey'||got.nodes!==3||got.edges!==expected){
   console.error(`candidate mismatch at compact graph ${i}: expected ${expected}, observed ${JSON.stringify(got)}`);process.exit(1);
 }
}
const count=G.reduced_count(3);
if(count.$!=='ReducedCount'||count.count!==104){console.error('candidate mismatch in reduced count');process.exit(1);}
console.log('candidate validation passed: all 512 graph keys and count');
