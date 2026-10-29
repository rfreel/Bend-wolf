import assert from 'node:assert/strict';
import D from '../build/Dynamics.mjs';
const code=25; // 0 -> 1, 1 -> 2, 2 -> 1
assert.deepEqual(D.iterate(3,code,0,0),{$:'State',value:0});
assert.deepEqual(D.iterate(3,code,0,5),{$:'State',value:1});
assert.deepEqual(D.orbit(3,code,0),{$:'Orbit',preperiod:1,period:2,entry:1});
assert.deepEqual(D.orbit(1,0,0),{$:'Orbit',preperiod:0,period:1,entry:0});
assert.equal(D.iterate(3,63,0,1).$,'DynInvalid');
assert.equal(D.iterate(4,0,4,1).$,'DynInvalid');
assert.equal(D.iterate(4,0,0,1000001).$,'DynInvalid');
assert.deepEqual(D.recurrence(0,1,1,2,3,5),{$:'Recurrence',first:1,second:1,next:8});
assert.deepEqual(D.recurrence(1,1,1,2,1,2),{$:'NoRecurrence'});
console.log('dynamics tests passed');
// Transition 0->1, 1->2, 2->1. Restrict to states {0,1}: no state can stay forever.
assert.deepEqual(D.invariant(3,25,3),{$:'Invariant',mask:0});
assert.deepEqual(D.invariant(3,25,6),{$:'Invariant',mask:6});
assert.deepEqual(D.invariant(3,25,7),{$:'Invariant',mask:7});
assert.equal(D.invariant(3,25,8).$,'DynInvalid');
// Graph with 0->1, 0->2, 1->2 and 2->2: two walks of length 2 reach 2.
assert.deepEqual(D.walks(3,2+4+64+1024,0,2,2),{$:'WalkCount',value:2});
assert.deepEqual(D.walks(3,2+4+64+1024,0,2,0),{$:'WalkCount',value:0});
assert.equal(D.walks(3,2,0,3,2).$,'DynInvalid');
console.log('invariant and dynamic programming tests passed');
// States 0<->1, with coordinates (0,1) and (1,0): x+y is conserved.
assert.deepEqual(D.find_linear_invariant(2,1,4,1),{$:'LinearInvariant',a:1,b:1});
// States 0->1, 1->1 with coordinates (0,0) and (1,1): no nonzero a,b >= 0 invariant.
assert.deepEqual(D.find_linear_invariant(2,5,4,4),{$:'NoLinearInvariant'});
assert.equal(D.find_linear_invariant(2,1,16,1).$,'DynInvalid');
console.log('linear invariant discovery tests passed');
assert.deepEqual(D.iterate(1,0,0,1000000),{$:'State',value:0});
assert.equal(D.walks(1,1,0,0,1000).value,1);
assert.equal(D.walks(1,1,0,0,1001).$,'DynInvalid');
