# Bend-wolf

Bend 2 × Wolfram: bounded implementation kernel.

This is executable source, a deliberately restricted Wolfram-to-Bend compiler, mathematical references, and reproducible checks. Each of the 40 workflows has an explicitly bounded implementation; these do **not** reproduce the general Wolfram Language. See `IMPLEMENTATION_CATALOG.md` for the exact status of every item and `RESULTS.md` for the evidence.

## Start

Requirements: Bend 2.0.39, Node.js, Python 3, a Bend-compatible clang, and Lean for `--verdict`. The last recorded run used Node 24.22.1, clang 18.1.3 and Lean 4.34.0. `bend --help` describes the compiler's requirements. Bend installation and language guide: https://github.com/bendlang/bend

```sh
bash verify.sh
```

If Bend is not on `PATH`, set `BEND=/path/to/bend`; ensure clang and Lean are also on `PATH`. The proof check needs the kernel supported by that Bend release. An incompatible Lean is not a proof failure: it is an environment failure.

To regenerate and run the sample that Wolfram minimized:

```sh
python3 tools/emit_bend.py evidence/wolfram_boolean_ir.json Generated.bend
bend Generated.bend
# Logic.Equivalent{}
```

The JSON and the Wolfram code that produced it are in `evidence/`. The generator accepts only its documented Boolean expression operators and declared variables; unsupported syntax is rejected. It does not parse or execute arbitrary Wolfram code. With an explicit condition, the generated program returns **both** the condition's satisfiability result and the conditional-equivalence result, so a vacuous condition is visible. Wolfram's provenance fields are records, not authentication.

## Public surface

| File | Supported operations and key limits |
|---|---|
| `Logic.bend` | Boolean AST, evaluation, substitution, SAT and equivalence (at most 16 variables); exact per-variable propagation (at most 12); a core of four formulas; Boolean quantifier elimination. `Invalid` is distinct from `Unsat`. |
| `Rewrite.bend` | Fixed recursive Boolean simplifier; exact-syntax ground rules; bounded repetition; truth-table keys for at most five variables. `RewriteLimit` is distinct from convergence. |
| `Arithmetic.bend` | Exact bounded cubic expansion, signed-difference factoring and integer root counting; separate U32 modular polynomial operations. It is not arbitrary-precision integer/rational algebra. |
| `Graph.bend` | Directed graph construction, shortest path, cycle, isomorphism, canonical label and topological ranking for at most four vertices; unweighted symmetric global cut; symmetry-reduced edge-addition reachability and all-graph counting up to three vertices. |
| `Dynamics.bend` | Deterministic four-state orbits, restricted recurrence fitting and linear-invariant discovery, greatest closed subset of a supplied set, and modular walk counting. |
| `Inference.bend` | Exact binary Bayesian ratios, two-experiment ranking by expected classification accuracy, a small structural intervention model and choice, deterministic hidden-state trace matching. |
| `Optimize.bend` | Four-point Pareto set and four-item exact budget search; integer minimum-cost flow on a four-edge, four-vertex network with bounded capacities and costs. |
| `Quantify.bend` | Exact elimination of one real variable from two linear inequalities with strictness; coefficient components <=1000. |
| `Abstract.bend` | Boolean partial-valuation overapproximation and bounded counterexample-driven splitting. |
| `Pattern.bend` | Boolean patterns with up to four metavariables; bounded repeated replacement with every pass checked for finite equivalence. |
| `Proof.bend` | Exhaustive Boolean equivalence and conditional equivalence; verification of a finite truth-table certificate. `PROOF.bend` also exports a proof-carrying Boolean simplification. |
| `Synthesis.bend` | DNF generation from a truth table, search over a configurable finite grammar, and counterexample-guided selection among four supplied candidates. |
| `Research.bend` | Four-slot semantic cache, four-candidate checked expression improvement with an optional truth-table certificate, and a four-node evidence graph with separate support and contradiction edges. |
| `Permutations.bend` | Generated permutation and bit-mask routines used by the graph implementation. `tools/generate_permutations.py` independently checks the supplied tables before emitting this file. |

All limits are part of the contract. `U32` arithmetic wraps modulo 2^32. Native `Nat` is finite; the bounded numerical APIs reject inputs before their declared safe limits are exceeded. The list above identifies supported entry points; lower-level helper definitions are not separately hardened public APIs. The JS backend exposes Bend definitions to JavaScript: foreign callers must supply well-formed constructors and `U32` values, since raw JS objects do not carry Bend's static type guarantees.

A graph on `n` vertices uses bit `4*u+v` for edge `u -> v`; vertices are `0..n-1`. Bits outside the graph are invalid. `Path.nodes` packs the start and subsequent vertices into successive 2-bit fields; `Path.length` is the number of edges. `Topology.code` maps original vertex numbers to 2-bit ranks. A cut requires symmetric edges; loops contribute zero. Walk counts wrap modulo 2^32.

For the evidence graph, node IDs are opaque external references, node kind/status codes are caller-defined integers 0..3, and edges distinguish support from contradiction. Connectivity is not a determination of truth or evidential warrant. Cache context IDs must distinguish every external assumption and implementation version relevant to a result; the library cannot guarantee that callers assign unique context IDs. Cache entries and evidence graphs are in memory only.

## Verification meaning

`LAWS.bend` has six laws. `PROOF.bend --verdict` checked all six using Bend's secondary kernel. The strongest is universal with respect to this library's own evaluator: for every Boolean expression and every `U32` assignment, recursively simplifying the expression preserves `Logic.eval`. It is not a proof that the evaluator or compiler implements Wolfram's complete semantics. A deliberate bad negation rewrite compiles, but the law proof then fails. The other algorithms and the truth-table certificate checker have tests, not universal correctness proofs. Each of the 14 core modules also passed a secondary-kernel type and termination check; that check is not a semantic correctness theorem.

`Proof.check` enumerates the declared finite Boolean domain; a checked result is not an independently kernel-verified theorem about the checker. `Proof.under` accepts vacuous implications, so first check whether the condition is satisfiable. The five-variable certificate records a common truth table and its checker recomputes both expressions; it is not a general symbolic proof object.

`bench/evaluate_candidates.py` independently checks each of four existing candidate graph implementations over all 512 three-vertex inputs before ranking measured native runs; it never modifies or promotes a candidate.

The graph benchmark is a narrow three-vertex workload. The recorded optimized Bend median was about 0.99 times the optimized C median, with variation and different anti-hoisting measures; do not generalize that result to other tasks. No GPU benchmark was run. Reproduce both CPU comparisons with `bash bench/run_benchmarks.sh`.
