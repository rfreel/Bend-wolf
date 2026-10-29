import Base
import ./Logic.bend as L
import ./Graph.bend as G
import ./Dynamics.bend as D
import ./Inference.bend as I
import ./Optimize.bend as O
import ./Arithmetic.bend as A
import ./Quantify.bend as Q

# Cross-module smoke test. Return values remain visible in a native build.
def main() -> L.Outcome & (G.GraphResult & (D.DynResult & (I.InferResult & (O.OptimizeResult & (D.DynResult & (A.ExactResult & Q.RealResult)))))):
  (L.satisfy(2n, L.EAnd{L.EVar{0}, L.ENot{L.EVar{1}}}), (G.shortest_path(3n, 66, 0, 2), (D.orbit(3n, 25, 0), (I.bayes(1n, 3n, 4n, 5n, 1n, 10n), (O.min_cost_flow4(4n, O.FlowEdges{O.FlowEdge{0, 1, 2, 1n}, O.FlowEdge{0, 2, 2, 3n}, O.FlowEdge{1, 3, 2, 1n}, O.FlowEdge{2, 3, 2, 1n}}, 0, 3, 3n), (D.find_linear_invariant(2n, 1, 4, 1), (A.exact_roots(A.ExactPolynomial{2n, 0n, 1n, 0n}, A.ExactPolynomial{0n, 3n, 0n, 0n}, Nat.pow(10n, 3n)), Q.exists_pair(Q.Inequality{2n, 0n, 0n, 4n, True{}}, Q.Inequality{0n, 1n, 2n, 0n, False{}}))))))))
