import assert from 'node:assert/strict';
import I from '../build/Inference.mjs';
assert.deepEqual(I.bayes(1,3,4,5,1,10),{$:'Posterior',numerator:40,denominator:50});
assert.equal(I.bayes(1,2,0,1,0,1).$,'ImpossibleEvidence');
assert.equal(I.bayes(2,1,1,1,1,1).$,'InferInvalid');
assert.equal(I.bayes(1,0,1,1,1,1).$,'InferInvalid');
const A={$:'Experiment',h_num:4,h_den:5,n_num:1,n_den:5};
const B={$:'Experiment',h_num:3,h_den:5,n_num:2,n_den:5};
assert.deepEqual(I.choose_experiment(1,2,A,B),{$:'ExperimentChoice',choice:0});
assert.deepEqual(I.choose_experiment(1,2,B,A),{$:'ExperimentChoice',choice:1});
// Y = X xor U, P(U=1)=1/4: do(X=0) => 1/4, do(X=1) => 3/4.
assert.deepEqual(I.intervene(6,1,4,0),{$:'Intervention',numerator:1,denominator:4});
assert.deepEqual(I.intervene(6,1,4,1),{$:'Intervention',numerator:3,denominator:4});
assert.equal(I.intervene(16,1,4,0).$,'InferInvalid');
// 0->1, 1->2, 2->1; state 1 emits 1, other states emit 0.
assert.deepEqual(I.infer_starts(3,25,2,2,3),{$:'Starts',mask:5}); // 0,1,0 is emitted by starts 0 and 2
assert.deepEqual(I.infer_starts(3,25,2,0,0),{$:'Starts',mask:7});
assert.equal(I.infer_starts(3,25,8,0,0).$,'InferInvalid');
console.log('inference tests passed');
assert.deepEqual(I.choose_intervention(6,1,4),{$:'InterventionChoice',choice:1,numerator:3,denominator:4});
assert.deepEqual(I.choose_intervention(0,1,4),{$:'InterventionChoice',choice:0,numerator:0,denominator:4});
assert.equal(I.choose_intervention(16,1,4).$,'InferInvalid');
console.log('causal intervention search tests passed');
assert.equal(I.bayes(1,1024,1,1,1,1).$,'Posterior');
assert.equal(I.bayes(1,1025,1,1,1,1).$,'InferInvalid');
