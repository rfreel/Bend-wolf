import Base
import ./Logic.bend as L
import ./Rewrite.bend as R

# Double negation holds for every expression and every bit assignment.
law double_negation:
  for +expr: L.Expr
  for +assignment: U32
  {L.eval(L.ENot{L.ENot{expr}}, assignment) == L.eval(expr, assignment) : Bool}

# True is a left identity for conjunction at every assignment.
law and_true_left:
  for +expr: L.Expr
  for +assignment: U32
  {L.eval(L.EAnd{L.ETrue{}, expr}, assignment) == L.eval(expr, assignment) : Bool}

# False is a left annihilator for conjunction.
law and_false_left:
  for expr: L.Expr
  for assignment: U32
  {L.eval(L.EAnd{L.EFalse{}, expr}, assignment) == False{} : Bool}

# The simplifier's local double-negation rule preserves every evaluation.
law simplify_double_negation:
  for +expr: L.Expr
  for +assignment: U32
  {L.eval(R.simplify_not(L.ENot{expr}), assignment) == L.eval(L.ENot{L.ENot{expr}}, assignment) : Bool}

# The simplifier's conjunction identity is valid for every expression.
law simplify_and_true:
  for +expr: L.Expr
  for +assignment: U32
  {L.eval(R.simplify_and(L.ETrue{}, expr), assignment) == L.eval(L.EAnd{L.ETrue{}, expr}, assignment) : Bool}

# Full recursive simplification preserves Boolean meaning at every assignment.
law simplify_sound:
  for +expr: L.Expr
  for +assignment: U32
  {L.eval(R.simplify(expr), assignment) == L.eval(expr, assignment) : Bool}
