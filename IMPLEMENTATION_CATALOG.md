# Forty-workflow implementation status

The catalog uses **bounded** when a working implementation covers the specific bounded form described below, and **partial** when a central part of the original general workflow remains absent. Both are limitations relative to Wolfram's full function. Every listed component was compiled and exercised in the recorded run. A Wolfram reference case, where present, is noted in the last column; it is a finite comparison, not a semantic-equivalence theorem.

| ID | Status | Implemented scope and remaining gap | Evidence |
|---|---|---|---|
| B01 | bounded | SAT for Boolean expressions, <=16 variables; simplification is not global Boolean minimization. | Eight Wolfram truth tables; independent enumeration |
| B02 | bounded | First Boolean counterexample for equivalence, <=16 variables. | independent exhaustive assignments |
| B03 | bounded | Exact forced true/false variables by repeated SAT, <=12 variables. | independent model sets |
| B04 | bounded | Inclusion-minimal inconsistent subset of four formulas. | 60 independently checked cores; Wolfram example |
| B05 | bounded | First-order Boolean patterns with up to four metavariables, repeated matches, and bounded top-down replacement; each checked pass is gated by finite equivalence. | 300 independent pattern cases; positive and rejected rewrite tests |
| B06 | bounded | Exhaustive Boolean rule check, including explicit conditions. | Wolfram-generated candidate and negative test |
| B07 | bounded | Boolean truth-table key <=5 variables and graph canonical key <=4 vertices. | exhaustive 3-vertex graphs |
| B08 | bounded | Exact cubic expansion with nonnegative coefficients <=1000 and exact signed-difference factoring at a found nonnegative integer root; modular cubic expansion and factoring are separate. No general rational algebra. | Wolfram cubic and factor; 200 exact expansions, 150 exact and 150 modular factorizations |
| B09 | bounded | Exact root count and first witness for equality of two cubics on integers 0..1000 with coefficients <=1000; also modular U32 root search. No general Groebner basis. | Wolfram exact roots {1,2}; 200 independent exact-root cases |
| B10 | bounded | Boolean quantifier elimination by substitution; exact real existential/universal elimination for a conjunction of two linear inequalities, including strict boundaries. Coefficient components <=1000. | Wolfram Resolve examples; 2,500 independent rational-witness cases |
| B11 | bounded | Four-vertex directed adjacency construction. | validation and graph tests |
| B12 | bounded | Shortest path and distance for unweighted directed graphs <=4. | 4,608 exhaustive graph/path comparisons; Wolfram distance |
| B13 | bounded | Graph isomorphism via explicit relabelings <=4 vertices. | exhaustive three-vertex and 1,024 four-vertex tests; Wolfram example |
| B14 | bounded | Minimum adjacency encoding under every vertex permutation <=4. The numeric key is our convention, not necessarily Wolfram's canonical encoding. | same exhaustive tests |
| B15 | bounded | Directed cycle existence <=4; no enumeration of every cycle. | 512 directed graphs; Wolfram example |
| B16 | bounded | Global unweighted minimum cut for symmetric graphs, 2–4 vertices. | 64 symmetric graphs; Wolfram triangle |
| B17 | bounded | Integer minimum-cost flow on arbitrary directed networks with <=4 vertices and four edges, capacities <=3 and nonnegative costs <=1000; plus the three-edge special case. | 200 independent four-edge cases; Wolfram cost 8 and flow matrix |
| B18 | bounded | Topological rank assignment for four-vertex directed graphs. | all 512 three-vertex graphs |
| B19 | bounded | Dynamic programming for directed walk counts on <=4 vertices, modulo 2^32; this is one concrete DP domain. | Wolfram matrix power |
| B20 | bounded | Exact orbit/preperiod/period for a supplied deterministic transition on <=4 states. | Wolfram orbit |
| B21 | bounded | Reachability classes under directed-edge addition from any graph on <=3 vertices; arbitrary transition relations and colored vertices are outside scope. | Wolfram reachable-class counts 1,8,24,48; independent exploration cases; CPU benchmark |
| B22 | bounded | Second-order recurrence with coefficients 0..3 fitted to six U32 terms; not a general recurrence finder. | Wolfram Fibonacci recurrence |
| B23 | bounded | Predicts one next term for the restricted recurrence; a finite prefix may admit multiple models. | Wolfram Fibonacci example |
| B24 | bounded | Discovers nonzero two-variable linear invariants with coefficients 0..3 for <=4 states, and computes the greatest closed subset of a supplied set. | Wolfram nullspace; 200 linear-invariant and 216 closed-set cases |
| B25 | bounded | Finds possible initial states for a deterministic <=4-state transition system with binary emissions; no probabilistic hidden Markov inference. | trace tests |
| B26 | bounded | Exact binary Bayesian update with bounded natural numerators and denominators; impossible evidence is explicit. | Wolfram posterior; 1,080 cases |
| B27 | bounded | Chooses between two binary experiments by exact expected best-classifier accuracy; that objective is not information gain. | Wolfram score example |
| B28 | bounded | Chooses between interventions in a supplied binary structural model `Y=f(X,U)` with exogenous U. Does not infer causality from observation. | Wolfram XOR model and intervention choice |
| B29 | bounded | Exact four-item 0/1 budget optimization plus a four-point two-objective Pareto comparison; no continuous optimizer. | Wolfram allocation example |
| B30 | bounded | Pareto frontier for exactly four two-objective U32 points; duplicate nondominated points are kept. | boundary and tie tests |
| B31 | bounded | Searches a configurable finite Boolean grammar of constants, literals and enabled binary operators for <=3 variables; also constructs DNF from truth tables up to five variables. | all 256 two-variable grammar/target combinations; 16 DNF targets |
| B32 | bounded | Counterexample-guided selection from four supplied Boolean candidates, <=5 variables; no open-ended candidate-generation loop. | positive, negative and invalid-candidate tests |
| B33 | bounded | Non-relational Boolean partial-valuation abstract interpreter; unknown correlations are overapproximated. | 8,640 soundness comparisons |
| B34 | bounded | Splits Boolean variable assignments until a violation or safety result; does not invent arbitrary new semantic predicates. | independent comparisons to concrete SAT |
| B35 | bounded | Full equivalence over a declared finite Boolean domain; no general symbolic semantic equivalence. | Wolfram-generated and counterexample examples |
| B36 | bounded | `PROOF.verified_simplification` returns the actual optimized Boolean expression together with a universal dependent proof; other finite improvements carry independently recomputed truth-table certificates. No general equational proof-object translator. | kernel-checked proof-carrying demo; wrong result and bad rewrite mutants rejected |
| B37 | bounded | Exact selection of four independent 0/1 opportunities under one budget; no multi-resource dependency scheduling. | independent cases; Wolfram allocation |
| B38 | bounded | In-memory evidence graph <=4 nodes with IDs, caller-supplied kind/status and separate support/contradiction edges; no persistence or source authentication. | graph tests |
| B39 | bounded | Four in-memory entries keyed by exact Boolean truth table, variable count and caller-supplied context ID; no general or persistent semantic cache. | hit, context, domain and invalid tests |
| B40 | bounded | Validates and benchmarks four existing Bend graph variants, ranks the valid candidates and never automatically promotes one; expression-level search also checks equivalence and emits certificates. No autonomous agent self-modification. | all candidate graph keys checked over 512 states; deliberate mutant rejected; measured candidate ranking |

No workflow is claimed to implement all of its named Wolfram functions. No global cross-language semantic equivalence has been proved. Property verification applies to the particular six Boolean laws, not to the entire library. Performance is measured only for the narrow graph workload in `RESULTS.md`.
