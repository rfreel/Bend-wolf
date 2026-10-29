import Base
import ./Logic.bend as L
import ./PROOF.bend as Verified

def take(-original: L.Expr, pair: &out:L.Expr -> (@assignment:U32 -> {L.eval(out, assignment) == L.eval(original, assignment) : Bool})) -> L.Expr:
  match pair:
    case Tuple{out, proof}: out

def main() -> L.Expr:
  take(L.EAnd{L.ETrue{}, L.EVar{0}}, Verified.verified_simplification(L.EAnd{L.ETrue{}, L.EVar{0}}))
