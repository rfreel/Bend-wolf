import Base

# Boolean formulas. Variables denote zero-based bits in an assignment.
type Expr is Data:
  ETrue{}
  EFalse{}
  EVar{id: U32}
  ENot{expr: Expr}
  EAnd{left: Expr, right: Expr}
  EOr{left: Expr, right: Expr}
  EXor{left: Expr, right: Expr}

# Invalid means a variable is outside the declared domain or n > 16.
type Outcome is Data:
  Invalid{}
  Unsat{}
  Sat{assignment: U32}
  Equivalent{}
  Different{assignment: U32}

def eval(expr: Expr, +assignment: U32) -> Bool:
  match expr:
    case ETrue{}: True{}
    case EFalse{}: False{}
    case EVar{id}: U32.is_eq(U32.and(U32.shrn(assignment, U32.to_nat(id)), 1), 1)
    case ENot{expr}: Bool.not(eval(expr, assignment))
    case EAnd{left, right}: Bool.and(eval(left, assignment), eval(right, assignment))
    case EOr{left, right}: Bool.or(eval(left, assignment), eval(right, assignment))
    case EXor{left, right}: Bool.xor(eval(left, assignment), eval(right, assignment))

def valid(expr: Expr, +n: Nat) -> Bool:
  match expr:
    case ETrue{}: True{}
    case EFalse{}: True{}
    case EVar{id}: U32.is_lt(id, U32.from_nat(n))
    case ENot{expr}: valid(expr, n)
    case EAnd{left, right}: Bool.and(valid(left, n), valid(right, n))
    case EOr{left, right}: Bool.and(valid(left, n), valid(right, n))
    case EXor{left, right}: Bool.and(valid(left, n), valid(right, n))

def subst_var(id: U32, value: Expr, same: Bool) -> Expr:
  match same:
    case True{}: value
    case False{}: EVar{id}

def substitute(expr: Expr, +id: U32, +value: Expr) -> Expr:
  match expr:
    case ETrue{}: ETrue{}
    case EFalse{}: EFalse{}
    case EVar{+var}: subst_var(var, value, U32.is_eq(var, id))
    case ENot{expr}: ENot{substitute(expr, id, value)}
    case EAnd{left, right}: EAnd{substitute(left, id, value), substitute(right, id, value)}
    case EOr{left, right}: EOr{substitute(left, id, value), substitute(right, id, value)}
    case EXor{left, right}: EXor{substitute(left, id, value), substitute(right, id, value)}

# Enumerate all masks in ascending order, evaluating each at most once.
def search(fuel: Nat, +expr: Expr, +assignment: U32, good: Bool) -> Outcome:
  match fuel good:
    case 0n _: Unsat{}
    case 1n+rest True{}: Sat{assignment}
    case 1n+rest False{}:
      +next = (assignment + 1 : U32)
      search(rest, expr, next, eval(expr, next))

def satisfy_checked(+n: Nat, +expr: Expr, ok: Bool) -> Outcome:
  match ok:
    case False{}: Invalid{}
    case True{}: search(Nat.pow(2n, n), expr, 0, eval(expr, 0))

def satisfy(+n: Nat, +expr: Expr) -> Outcome:
  satisfy_checked(n, expr, Bool.and(Nat.is_le(n, 16n), valid(expr, n)))

def equivalence_result(result: Outcome) -> Outcome:
  match result:
    case Invalid{}: Invalid{}
    case Unsat{}: Equivalent{}
    case Sat{assignment}: Different{assignment}
    case Equivalent{}: Invalid{}
    case Different{assignment}: Invalid{}

def equivalent(n: Nat, left: Expr, right: Expr) -> Outcome:
  equivalence_result(satisfy(n, EXor{left, right}))

# Exact finite Boolean quantifier elimination, retaining all other variables.
def exists(+expr: Expr, +id: U32) -> Expr:
  EOr{substitute(expr, id, EFalse{}), substitute(expr, id, ETrue{})}

def forall(+expr: Expr, +id: U32) -> Expr:
  EAnd{substitute(expr, id, EFalse{}), substitute(expr, id, ETrue{})}

type CoreResult is Data:
  CoreInvalid{}
  NoCore{}
  Core{mask: U32}

def selected(expr: Expr, active: Bool) -> Expr:
  match active:
    case True{}: expr
    case False{}: ETrue{}

def core_formula(a: Expr, b: Expr, c: Expr, d: Expr, +mask: U32) -> Expr:
  EAnd{EAnd{selected(a, U32.is_ne(U32.and(mask, 1), 0)), selected(b, U32.is_ne(U32.and(mask, 2), 0))}, EAnd{selected(c, U32.is_ne(U32.and(mask, 4), 0)), selected(d, U32.is_ne(U32.and(mask, 8), 0))}}

def removal(current: U32, candidate: U32, outcome: Outcome) -> U32:
  match outcome:
    case Unsat{}: candidate
    case _: current

# Deleting a constraint once is sufficient for inclusion minimality by monotonicity.
def core_go(fuel: Nat, +n: Nat, +a: Expr, +b: Expr, +c: Expr, +d: Expr, +pos: Nat, +mask: U32) -> CoreResult:
  match fuel:
    case 0n: Core{mask}
    case 1n+rest:
      +cand = U32.and(mask, U32.not(U32.shln(1, pos)))
      +trial = satisfy(n, core_formula(a, b, c, d, cand))
      core_go(rest, n, a, b, c, d, (pos + 1n : Nat), removal(mask, cand, trial))

def core_start(+n: Nat, +a: Expr, +b: Expr, +c: Expr, +d: Expr, full: Outcome) -> CoreResult:
  match full:
    case Invalid{}: CoreInvalid{}
    case Sat{assignment}: NoCore{}
    case Unsat{}: core_go(4n, n, a, b, c, d, 0n, 15)
    case _: CoreInvalid{}

def minimal_core4(+n: Nat, +a: Expr, +b: Expr, +c: Expr, +d: Expr) -> CoreResult:
  core_start(n, a, b, c, d, satisfy(n, core_formula(a, b, c, d, 15)))

type PropagationResult is Data:
  PropagationInvalid{}
  PropagationUnsat{}
  Propagated{must_true: U32, must_false: U32}

def is_unsat(result: Outcome) -> Bool:
  match result:
    case Unsat{}: True{}
    case _: False{}

def propagate_go(fuel: Nat, +n: Nat, +expr: Expr, +pos: Nat, must_true: U32, must_false: U32) -> PropagationResult:
  match fuel:
    case 0n: Propagated{must_true, must_false}
    case 1n+rest:
      +bit = U32.shln(1, pos)
      +v = {EVar{U32.from_nat(pos)} : Expr}
      +cannot_false = is_unsat(satisfy(n, EAnd{expr, ENot{v}}))
      +cannot_true = is_unsat(satisfy(n, EAnd{expr, v}))
      propagate_go(rest, n, expr, (pos + 1n : Nat), U32.or(must_true, (Bool.to_u32(cannot_false) * bit : U32)), U32.or(must_false, (Bool.to_u32(cannot_true) * bit : U32)))

def propagation_start(+n: Nat, expr: Expr, result: Outcome) -> PropagationResult:
  match result:
    case Invalid{}: PropagationInvalid{}
    case Unsat{}: PropagationUnsat{}
    case Sat{assignment}: propagate_go(n, n, expr, 0n, 0, 0)
    case _: PropagationInvalid{}

def propagation_range(+n: Nat, +expr: Expr, ok: Bool) -> PropagationResult:
  match ok:
    case False{}: PropagationInvalid{}
    case True{}: propagation_start(n, expr, satisfy(n, expr))

def propagate(+n: Nat, expr: Expr) -> PropagationResult:
  propagation_range(n, expr, Nat.is_le(n, 12n))
