# Results and limits

Recorded 2026-10-29. Raw input, Wolfram Language scripts, reference JSON, benchmark samples and toolchain details are in `evidence/`; the tests are in `tests/`.

## Wolfram-to-Bend

Wolfram Language 15.0.1 generated a Boolean IR for `(a && b) || (a && !b)` and its minimized candidate `a`. The restricted translator emitted `Generated.bend`. Bend ran it and returned `Logic.Equivalent{}`. A test replaced the candidate with `True`; the generated Bend program returned a counterexample at assignment 0. Another test used an unsatisfiable condition and exposed `Unsat{}` alongside the vacuous equivalence result.

Wolfram also produced the permutation codes and three-vertex edge-shift masks used to generate `Permutations.bend`. The Python generator independently validates that the codes are exactly the required permutations and that every mask sends every allowed edge bit to the correct destination. The resulting Bend code was checked over all 512 directed graphs with loops on three vertices against independently enumerated relabelings. These checks are exhaustive over that finite graph domain, but they are not a kernel-checked proof of graph canonicalization.

Additional Wolfram calculations supplied eight Boolean truth tables; cubic polynomial coefficients and values; a Fibonacci recurrence; a binary posterior; a path distance; a triangle cut; a three-edge minimum-cost flow of 7; a four-edge flow of 8 and its flow matrix; linear-invariant nullspace `{1,1}`; a modular difference-of-squares factorization; finite Boolean quantification and exact real linear elimination examples; exact integer polynomial roots and a signed factor; an isomorphism example; a bounded root; graph walks; an intervention; an allocation optimum; a Burnside count of 1, 2, 10, 104 unlabeled directed graphs with loops on zero through three vertices; and reachable-class counts 1, 8, 24, 48 from a one-edge graph after zero through three edge additions. `tests/wolfram_cases.mjs` and `tests/differential.mjs` compare the relevant Bend results.

## Proof and testing

`PROOF.verified_simplification` returns a dependent pair containing the actual simplified expression and a universal proof for that expression. `ProofDemo.bend` consumes this pair and passed the secondary kernel. Six laws passed `bend PROOF.bend --verdict`, including the universal equation `eval(simplify(expr), assignment) = eval(expr, assignment)` for the actual exported simplifier, every Boolean AST and every U32 assignment. The equation is relative to `Logic.eval`, not to an independently formalized Wolfram semantics. The implementation, Base, the two checkers and their toolchain remain in the trust boundary. All 14 core modules also passed the secondary kernel as type/termination checks; those checks do not prove their algorithms correct. No general solver, certificate checker or graph algorithm has a universal correctness proof here.

A mutation changed double-negation elimination to return a single negation. The mutated module compiled by itself, while the law check rejected the altered implementation at `simplify_double_negation`. A second mutation changed the expression returned with the universal proof; the dependent type check rejected it.

The independent differential suite exercised 2,560 Boolean assignments from 320 generated expressions; 300 pattern-rewrite cases; all 256 two-variable grammar/target combinations; 2,500 pairs of real linear inequalities checked against rational witnesses; 8,640 abstract-interpretation cases; 60 minimal-core instances; all 512 directed three-vertex graphs and their 4,608 source/target path cases; 1,024 sampled four-vertex graph canonicalizations; 16 symmetry-reduced reachability cases; 64 symmetric graph cuts; 200 modular arithmetic expressions; 200 exact integer-root cases; 200 exact expansions; 150 exact signed and 150 modular factorizations; 216 finite invariants; 1,080 Bayesian cases; and 250 three-edge and 200 four-edge minimum-cost-flow cases; and 200 linear-invariant searches. Random cases use a fixed seed. The suite includes domain and invalid-input cases; it does not establish unbounded correctness.

The same sources compiled to JavaScript modules and to a native CPU cross-module program. The native program returned a SAT witness, a path, a deterministic orbit, the posterior 40/50, the four-edge flow cost 8, a linear invariant, the exact root count 2 and the unsatisfiable strict real boundary.

## CPU benchmark

Workload: count the equivalence classes of all 512 directed graphs on three vertices, with loops permitted. Both implementations returned 104 per count. Measurements include process startup and output, exclude compilation, use warmups and alternating order, and retain raw samples. The C reference is test/benchmark code, not the Bend implementation.

For 1,000 repetitions, the original generic Bend implementation had median 0.557 s; the specialized Bend version had median 0.00293 s in a direct alternating comparison, roughly 190x faster on that narrow workload. The faster version uses generated fixed bit masks and direct compact expansion. An outlier is retained in the raw samples.

For 10,000 repetitions, final Bend had median 0.02219 s and an optimized C version using the same bit-mask technique had median 0.02243 s, a Bend/C ratio of 0.989. The seven samples vary; this does not establish a speed advantage over optimized C. That C benchmark uses a volatile offset to prevent loop hoisting; the Bend executable was separately checked at 10, 1,000 and 10,000 repetitions for scaling. This is one small fixed workload, not a general language benchmark. A second C implementation independently enumerates six permutations and is retained as a cross-check.

No GPU was exposed, so GPU execution and performance remain untested.

## What remains

Each of the 40 entries has a working bounded form. Missing general capabilities include unrestricted patterns, broad exact integer/rational algebra and real quantifier elimination, unbounded flow and synthesis, general proof-object translation, automatic predicate discovery, durable provenance-aware caching, and autonomous self-improvement. These limits are substantive: the narrow implementations are not full ports of the corresponding Wolfram functions. The catalog states each domain. `IMPLEMENTATION_CATALOG.md` records each gap rather than classifying it as a completed port.


## Measured candidate search

`bench/evaluate_candidates.py` compiled four existing Bend implementations, validated every three-vertex canonical key against an independent permutation enumeration, then timed five rotated runs for each accepted candidate. All four passed. The recorded medians were 0.5450 s for the baseline, 0.1035 s for the permutation-table version, 0.02569 s for the masked version, and 0.00362 s for the compact version, over 1,000 repetitions. The selection is confined to this workload; no candidate is automatically promoted. A deliberately incorrect canonicalizer compiled but was rejected by the validation gate. The first version of that test incorrectly treated a missing validator as rejection; it was corrected to require a passing control and the expected mismatch message.

## Secondary-kernel diagnostic

A direct large natural literal caused the secondary check to fail with a stack overflow even when the ordinary compiler accepted the file. A minimal `1000n` example reproduced the failure, while the same number represented as `Nat.pow(10n, 3n)` passed. Replacing the large constants with equal small-power expressions preserved the specified bounds and enabled the affected modules to pass. This is an observed compiler/checker limitation, not a finding that a proposition was false.

The first Wolfram attempt to extract the exact polynomial roots with `ToRules` produced an export error. The failed request and output are retained in `evidence/wolfram_exact_first_attempt.txt`; the corrected request used integer enumeration and `Reduce`.
