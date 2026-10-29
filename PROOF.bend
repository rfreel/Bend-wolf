import Base
import ./Logic.bend as L
import ./Rewrite.bend as R
import ./LAWS.bend as Laws

def double_neg(b: Bool) -> {Bool.not(Bool.not(b)) == b : Bool}:
  match b:
    case True{}: {==}
    case False{}: {==}

def Laws.double_negation(expr, assignment): double_neg(L.eval(expr, assignment))
def Laws.and_true_left(expr, assignment): {==}
def Laws.and_false_left(expr, assignment): {==}

def Laws.simplify_double_negation(expr, assignment):
  Equal.sym(Bool, Bool.not(Bool.not(L.eval(expr, assignment))), L.eval(expr, assignment), double_neg(L.eval(expr, assignment)))

def Laws.simplify_and_true(expr, assignment):
  match expr:
    case L.ETrue{}: {==}
    case L.EFalse{}: {==}
    case L.EVar{id}: {==}
    case L.ENot{inner}: {==}
    case L.EAnd{left, right}: {==}
    case L.EOr{left, right}: {==}
    case L.EXor{left, right}: {==}

def and_right_false(b: Bool) -> {Bool.and(b, False{}) == False{} : Bool}:
  match b:
    case True{}: {==}
    case False{}: {==}

def and_right_true(b: Bool) -> {Bool.and(b, True{}) == b : Bool}:
  match b:
    case True{}: {==}
    case False{}: {==}

def or_right_false(b: Bool) -> {Bool.or(b, False{}) == b : Bool}:
  match b:
    case True{}: {==}
    case False{}: {==}

def or_right_true(b: Bool) -> {Bool.or(b, True{}) == True{} : Bool}:
  match b:
    case True{}: {==}
    case False{}: {==}

def not_sound(+expr: L.Expr, +assignment: U32) -> {L.eval(R.simplify_not(expr), assignment) == Bool.not(L.eval(expr, assignment)) : Bool}:
  match expr:
    case L.ETrue{}: {==}
    case L.EFalse{}: {==}
    case L.ENot{+inner}:
      Equal.sym(Bool, Bool.not(Bool.not(L.eval(inner, assignment))), L.eval(inner, assignment), double_neg(L.eval(inner, assignment)))
    case L.EVar{id}: {==}
    case L.EAnd{left, right}: {==}
    case L.EOr{left, right}: {==}
    case L.EXor{left, right}: {==}

def and_right_sound(+left: L.Expr, +right: L.Expr, +assignment: U32) -> {L.eval(R.and_right(left, right), assignment) == Bool.and(L.eval(left, assignment), L.eval(right, assignment)) : Bool}:
  match right:
    case L.EFalse{}:
      Equal.sym(Bool, Bool.and(L.eval(left, assignment), False{}), False{}, and_right_false(L.eval(left, assignment)))
    case L.ETrue{}:
      Equal.sym(Bool, Bool.and(L.eval(left, assignment), True{}), L.eval(left, assignment), and_right_true(L.eval(left, assignment)))
    case L.EVar{id}: {==}
    case L.ENot{inner}: {==}
    case L.EAnd{a, b}: {==}
    case L.EOr{a, b}: {==}
    case L.EXor{a, b}: {==}

def and_sound(+left: L.Expr, +right: L.Expr, +assignment: U32) -> {L.eval(R.simplify_and(left, right), assignment) == Bool.and(L.eval(left, assignment), L.eval(right, assignment)) : Bool}:
  match left:
    case L.EFalse{}: {==}
    case L.ETrue{}: {==}
    case L.EVar{id}: and_right_sound(L.EVar{id}, right, assignment)
    case L.ENot{inner}: and_right_sound(L.ENot{inner}, right, assignment)
    case L.EAnd{a, b}: and_right_sound(L.EAnd{a, b}, right, assignment)
    case L.EOr{a, b}: and_right_sound(L.EOr{a, b}, right, assignment)
    case L.EXor{a, b}: and_right_sound(L.EXor{a, b}, right, assignment)

def or_right_sound(+left: L.Expr, +right: L.Expr, +assignment: U32) -> {L.eval(R.or_right(left, right), assignment) == Bool.or(L.eval(left, assignment), L.eval(right, assignment)) : Bool}:
  match right:
    case L.ETrue{}:
      Equal.sym(Bool, Bool.or(L.eval(left, assignment), True{}), True{}, or_right_true(L.eval(left, assignment)))
    case L.EFalse{}:
      Equal.sym(Bool, Bool.or(L.eval(left, assignment), False{}), L.eval(left, assignment), or_right_false(L.eval(left, assignment)))
    case L.EVar{id}: {==}
    case L.ENot{inner}: {==}
    case L.EAnd{a, b}: {==}
    case L.EOr{a, b}: {==}
    case L.EXor{a, b}: {==}

def or_sound(+left: L.Expr, +right: L.Expr, +assignment: U32) -> {L.eval(R.simplify_or(left, right), assignment) == Bool.or(L.eval(left, assignment), L.eval(right, assignment)) : Bool}:
  match left:
    case L.ETrue{}: {==}
    case L.EFalse{}: {==}
    case L.EVar{id}: or_right_sound(L.EVar{id}, right, assignment)
    case L.ENot{inner}: or_right_sound(L.ENot{inner}, right, assignment)
    case L.EAnd{a, b}: or_right_sound(L.EAnd{a, b}, right, assignment)
    case L.EOr{a, b}: or_right_sound(L.EOr{a, b}, right, assignment)
    case L.EXor{a, b}: or_right_sound(L.EXor{a, b}, right, assignment)

def Laws.simplify_sound(expr, assignment):
  match expr:
    case L.ETrue{}: {==}
    case L.EFalse{}: {==}
    case L.EVar{id}: {==}
    case L.ENot{+inner}:
      %Laws.simplify_sound(inner, assignment) : {L.eval(R.simplify_not(R.simplify(inner)), assignment) == Bool.not(_) : Bool}
      not_sound(R.simplify(inner), assignment)
    case L.EAnd{+left, +right}:
      %Laws.simplify_sound(left, assignment) : {L.eval(R.simplify_and(R.simplify(left), R.simplify(right)), assignment) == Bool.and(_, L.eval(right, assignment)) : Bool}
      %Laws.simplify_sound(right, assignment) : {L.eval(R.simplify_and(R.simplify(left), R.simplify(right)), assignment) == Bool.and(L.eval(R.simplify(left), assignment), _) : Bool}
      and_sound(R.simplify(left), R.simplify(right), assignment)
    case L.EOr{+left, +right}:
      %Laws.simplify_sound(left, assignment) : {L.eval(R.simplify_or(R.simplify(left), R.simplify(right)), assignment) == Bool.or(_, L.eval(right, assignment)) : Bool}
      %Laws.simplify_sound(right, assignment) : {L.eval(R.simplify_or(R.simplify(left), R.simplify(right)), assignment) == Bool.or(L.eval(R.simplify(left), assignment), _) : Bool}
      or_sound(R.simplify(left), R.simplify(right), assignment)
    case L.EXor{+left, +right}:
      %Laws.simplify_sound(left, assignment) : {Bool.xor(L.eval(R.simplify(left), assignment), L.eval(R.simplify(right), assignment)) == Bool.xor(_, L.eval(right, assignment)) : Bool}
      %Laws.simplify_sound(right, assignment) : {Bool.xor(L.eval(R.simplify(left), assignment), L.eval(R.simplify(right), assignment)) == Bool.xor(L.eval(R.simplify(left), assignment), _) : Bool}
      {==}

# A dependent pair carrying the optimized expression and its universal proof.
def verified_simplification(+expr: L.Expr) -> &out:L.Expr -> (@assignment:U32 -> {L.eval(out, assignment) == L.eval(expr, assignment) : Bool}):
  (R.simplify(expr), assignment => Laws.simplify_sound(expr, assignment))
