import Base
import ./Logic.bend as L
import ./Proof.bend as P

def main() -> L.Outcome:
  P.check(2n, L.EOr{L.EAnd{L.EVar{0}, L.EVar{1}}, L.EAnd{L.EVar{0}, L.ENot{L.EVar{1}}}}, L.EVar{0})
