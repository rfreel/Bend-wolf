import Base
import ./Logic.bend as L

# Truth-table keys are canonical only for the same declared variable count.
type KeyResult is Data:
  KeyInvalid{}
  TruthKey{bits: U32}

def truth_step(fuel: Nat, +expr: L.Expr, +assignment: U32, bits: U32) -> U32:
  match fuel:
    case 0n: bits
    case 1n+rest:
      +flag = Bool.to_u32(L.eval(expr, assignment))
      +next = (assignment + 1 : U32)
      truth_step(rest, expr, next, U32.or(bits, U32.shln(flag, U32.to_nat(assignment))))

def truth_checked(+n: Nat, +expr: L.Expr, ok: Bool) -> KeyResult:
  match ok:
    case False{}: KeyInvalid{}
    case True{}: TruthKey{truth_step(Nat.pow(2n, n), expr, 0, 0)}

def truth_table(+n: Nat, +expr: L.Expr) -> KeyResult:
  truth_checked(n, expr, Bool.and(Nat.is_le(n, 5n), L.valid(expr, n)))

def simplify_not(+x: L.Expr) -> L.Expr:
  match x:
    case L.ETrue{}: L.EFalse{}
    case L.EFalse{}: L.ETrue{}
    case L.ENot{inner}: inner
    case _: L.ENot{x}

def and_right(+left: L.Expr, +right: L.Expr) -> L.Expr:
  match right:
    case L.EFalse{}: L.EFalse{}
    case L.ETrue{}: left
    case _: L.EAnd{left, right}

def simplify_and(+left: L.Expr, right: L.Expr) -> L.Expr:
  match left:
    case L.EFalse{}: L.EFalse{}
    case L.ETrue{}: right
    case _: and_right(left, right)

def or_right(+left: L.Expr, +right: L.Expr) -> L.Expr:
  match right:
    case L.ETrue{}: L.ETrue{}
    case L.EFalse{}: left
    case _: L.EOr{left, right}

def simplify_or(+left: L.Expr, right: L.Expr) -> L.Expr:
  match left:
    case L.ETrue{}: L.ETrue{}
    case L.EFalse{}: right
    case _: or_right(left, right)

def simplify(expr: L.Expr) -> L.Expr:
  match expr:
    case L.ETrue{}: L.ETrue{}
    case L.EFalse{}: L.EFalse{}
    case L.EVar{id}: L.EVar{id}
    case L.ENot{inner}: simplify_not(simplify(inner))
    case L.EAnd{left, right}: simplify_and(simplify(left), simplify(right))
    case L.EOr{left, right}: simplify_or(simplify(left), simplify(right))
    case L.EXor{left, right}: L.EXor{simplify(left), simplify(right)}

# Ground rules match exact syntax. Object variables are not pattern metavariables.
type RewriteResult is Data:
  RewriteInvalid{}
  RewriteDone{expr: L.Expr, steps: Nat}
  RewriteLimit{expr: L.Expr, steps: Nat}

def expr_equal(a: L.Expr, b: L.Expr) -> Bool:
  match a b:
    case L.ETrue{} L.ETrue{}: True{}
    case L.EFalse{} L.EFalse{}: True{}
    case L.EVar{x} L.EVar{y}: U32.is_eq(x, y)
    case L.ENot{x} L.ENot{y}: expr_equal(x, y)
    case L.EAnd{l1, r1} L.EAnd{l2, r2}: Bool.and(expr_equal(l1, l2), expr_equal(r1, r2))
    case L.EOr{l1, r1} L.EOr{l2, r2}: Bool.and(expr_equal(l1, l2), expr_equal(r1, r2))
    case L.EXor{l1, r1} L.EXor{l2, r2}: Bool.and(expr_equal(l1, l2), expr_equal(r1, r2))
    case _ _: False{}

def replace_go(expr: L.Expr, +before: L.Expr, +after: L.Expr, equal: Bool) -> L.Expr:
  match expr equal:
    case _ True{}: after
    case L.ETrue{} False{}: L.ETrue{}
    case L.EFalse{} False{}: L.EFalse{}
    case L.EVar{id} False{}: L.EVar{id}
    case L.ENot{+inner} False{}: L.ENot{replace_go(inner, before, after, expr_equal(inner, before))}
    case L.EAnd{+left, +right} False{}: L.EAnd{replace_go(left, before, after, expr_equal(left, before)), replace_go(right, before, after, expr_equal(right, before))}
    case L.EOr{+left, +right} False{}: L.EOr{replace_go(left, before, after, expr_equal(left, before)), replace_go(right, before, after, expr_equal(right, before))}
    case L.EXor{+left, +right} False{}: L.EXor{replace_go(left, before, after, expr_equal(left, before)), replace_go(right, before, after, expr_equal(right, before))}

def replace_all(+expr: L.Expr, +before: L.Expr, after: L.Expr) -> L.Expr:
  replace_go(expr, before, after, expr_equal(expr, before))

def repeat_go(fuel: Nat, +before: L.Expr, +after: L.Expr, +current: L.Expr, +next: L.Expr, +steps: Nat, stable: Bool) -> RewriteResult:
  match fuel stable:
    case _ True{}: RewriteDone{current, steps}
    case 0n False{}: RewriteLimit{current, steps}
    case 1n+rest False{}:
      +new_next = replace_all(next, before, after)
      repeat_go(rest, before, after, next, new_next, (steps + 1n : Nat), expr_equal(next, new_next))

def repeat_checked(fuel: Nat, +expr: L.Expr, +before: L.Expr, +after: L.Expr, ok: Bool) -> RewriteResult:
  match ok:
    case False{}: RewriteInvalid{}
    case True{}:
      +next = replace_all(expr, before, after)
      repeat_go(fuel, before, after, expr, next, 0n, expr_equal(expr, next))

def repeat(+fuel: Nat, expr: L.Expr, before: L.Expr, after: L.Expr) -> RewriteResult:
  repeat_checked(fuel, expr, before, after, Nat.is_le(fuel, 16n))
