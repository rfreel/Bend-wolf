#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
BEND="${BEND:-bend}"
NODE="${NODE:-node}"
PYTHON="${PYTHON:-python3}"
export BEND BEND_NO_TELEMETRY=1
mkdir -p build
"$BEND" version
"$PYTHON" tools/generate_permutations.py evidence/wolfram_permutations.json build/permutations-check.bend --masks evidence/wolfram_masks.json
cmp Permutations.bend build/permutations-check.bend
"$PYTHON" tools/emit_bend.py evidence/wolfram_boolean_ir.json build/generated-check.bend
cmp Generated.bend build/generated-check.bend
for module in Logic Rewrite Arithmetic Graph Dynamics Inference Optimize Abstract Proof Synthesis Research Pattern Quantify; do
  "$BEND" "$module.bend" -o "build/$module.mjs"
done
"$BEND" PROOF.bend --verdict
"$BEND" ProofDemo.bend --verdict
for test in logic rewrite arithmetic graph dynamics inference optimize abstract synthesis research pattern quantify; do
  "$NODE" "tests/${test}_test.mjs"
done
"$NODE" tests/wolfram_cases.mjs
"$NODE" tests/differential.mjs
"$PYTHON" tests/translator_test.py
"$PYTHON" tests/permutations_test.py
"$PYTHON" tests/proof_mutation_test.py
"$PYTHON" tests/kernel_modules_test.py
"$PYTHON" tests/candidate_validation_test.py
result=$("$BEND" Generated.bend)
[ "$result" = 'Logic.Equivalent{}' ] || { printf 'Unexpected generated result: %s\n' "$result" >&2; exit 1; }
result=$("$BEND" ProofDemo.bend)
[ "$result" = 'Logic.EVar{0}' ] || { printf 'Unexpected proof-carrying demo result: %s\n' "$result" >&2; exit 1; }
"$BEND" NativeSmoke.bend -o build/native_smoke
result=$(./build/native_smoke)
expected='(Logic.Sat{1}, Graph.Path{2, 36}, Dynamics.Orbit{1n, 2n, 1}, Inference.Posterior{40n, 50n}, Optimize.Flow4{102, 8n}, Dynamics.LinearInvariant{1, 1}, Arithmetic.ExactRoots{1n, 2n}, Quantify.RealFalse{})'
[ "$result" = "$expected" ] || { printf 'Unexpected native result: %s\n' "$result" >&2; exit 1; }
printf 'Generated program and native cross-module smoke test passed.\n'
