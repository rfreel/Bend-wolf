import Base

# Arithmetic is the ring Z/(2^32); it is not exact unbounded integer arithmetic.
type AExpr is Data:
  AConst{value: U32}
  AVar{}
  APlus{left: AExpr, right: AExpr}
  AMul{left: AExpr, right: AExpr}

# Exact naturals within the explicitly checked coefficient and input bounds.
type ExactPolynomial is Data:
  ExactPolynomial{c0: Nat, c1: Nat, c2: Nat, c3: Nat}

type ExactExpr is Data:
  ExactConst{value: Nat}
  ExactVar{}
  ExactAdd{left: ExactExpr, right: ExactExpr}
  ExactMul{left: ExactExpr, right: ExactExpr}

type ExpansionResult is Data:
  ExactExpanded{poly: ExactPolynomial}
  ExpansionOverflow{}

type ExactResult is Data:
  ExactInvalid{}
  ExactNoRoot{}
  ExactRoots{first: Nat, count: Nat}
  ExactFactor{root: Nat, q0p: Nat, q0n: Nat, q1p: Nat, q1n: Nat, q2p: Nat, q2n: Nat}

type ArithResult is Data:
  ArithInvalid{}
  DegreeOverflow{}
  Polynomial{c0: U32, c1: U32, c2: U32, c3: U32}
  Root{value: U32}
  NoRoot{}
  Factorization{root: U32, q0: U32, q1: U32, q2: U32}

def eval(expr: AExpr, +x: U32) -> U32:
  match expr:
    case AConst{value}: value
    case AVar{}: x
    case APlus{left, right}: (eval(left, x) + eval(right, x) : U32)
    case AMul{left, right}: (eval(left, x) * eval(right, x) : U32)

def poly_add(a: ArithResult, b: ArithResult) -> ArithResult:
  match a b:
    case Polynomial{a0, a1, a2, a3} Polynomial{b0, b1, b2, b3}:
      Polynomial{(a0 + b0 : U32), (a1 + b1 : U32), (a2 + b2 : U32), (a3 + b3 : U32)}
    case _ _: DegreeOverflow{}

def poly_finish(c0: U32, c1: U32, c2: U32, c3: U32, valid: Bool) -> ArithResult:
  match valid:
    case False{}: DegreeOverflow{}
    case True{}: Polynomial{c0, c1, c2, c3}

def poly_mul(a: ArithResult, b: ArithResult) -> ArithResult:
  match a b:
    case Polynomial{+a0, +a1, +a2, +a3} Polynomial{+b0, +b1, +b2, +b3}:
      +c0 = (a0 * b0 : U32)
      +c1 = ((a0 * b1 : U32) + (a1 * b0 : U32) : U32)
      +c2 = (((a0 * b2 : U32) + (a1 * b1 : U32) : U32) + (a2 * b0 : U32) : U32)
      +c3 = ((((a0 * b3 : U32) + (a1 * b2 : U32) : U32) + (a2 * b1 : U32) : U32) + (a3 * b0 : U32) : U32)
      +c4 = (((a1 * b3 : U32) + (a2 * b2 : U32) : U32) + (a3 * b1 : U32) : U32)
      +c5 = ((a2 * b3 : U32) + (a3 * b2 : U32) : U32)
      +c6 = (a3 * b3 : U32)
      poly_finish(c0, c1, c2, c3, Bool.and(U32.is_eq(c4, 0), Bool.and(U32.is_eq(c5, 0), U32.is_eq(c6, 0))))
    case _ _: DegreeOverflow{}

def polynomial(expr: AExpr) -> ArithResult:
  match expr:
    case AConst{value}: Polynomial{value, 0, 0, 0}
    case AVar{}: Polynomial{0, 1, 0, 0}
    case APlus{left, right}: poly_add(polynomial(left), polynomial(right))
    case AMul{left, right}: poly_mul(polynomial(left), polynomial(right))

def root_go(fuel: Nat, +left: AExpr, +right: AExpr, +x: U32, found: Bool) -> ArithResult:
  match fuel found:
    case _ True{}: Root{x}
    case 0n False{}: NoRoot{}
    case 1n+rest False{}:
      +next = (x + 1 : U32)
      root_go(rest, left, right, next, U32.is_eq(eval(left, next), eval(right, next)))

def root_checked(+left: AExpr, +right: AExpr, limit: U32, ok: Bool) -> ArithResult:
  match ok:
    case False{}: ArithInvalid{}
    case True{}: root_go(U32.to_nat(limit), left, right, 0, U32.is_eq(eval(left, 0), eval(right, 0)))

def solve_eq(+left: AExpr, +right: AExpr, +limit: U32) -> ArithResult:
  root_checked(left, right, limit, U32.is_le(limit, 100000))

# Factor a cubic polynomial as (x - root) * (q0 + q1*x + q2*x^2) mod 2^32.
def polynomial_eval(poly: ArithResult, +x: U32) -> U32:
  match poly:
    case Polynomial{c0, c1, c2, c3}: (c0 + (x * (c1 + (x * (c2 + (x * c3 : U32) : U32) : U32) : U32) : U32) : U32)
    case _: 0

def factor_result(poly: ArithResult, +root: U32) -> ArithResult:
  match poly:
    case Polynomial{c0, c1, c2, +c3}:
      +q2 = c3
      +q1 = (c2 + (root * q2 : U32) : U32)
      +q0 = (c1 + (root * q1 : U32) : U32)
      Factorization{root, q0, q1, q2}
    case _: ArithInvalid{}

def factor_go(fuel: Nat, +poly: ArithResult, +x: U32, found: Bool) -> ArithResult:
  match fuel found:
    case _ True{}: factor_result(poly, x)
    case 0n False{}: NoRoot{}
    case 1n+rest False{}:
      +next = (x + 1 : U32)
      factor_go(rest, poly, next, U32.is_eq(polynomial_eval(poly, next), 0))

def factor_type(+poly: ArithResult, limit: U32) -> ArithResult:
  match poly:
    case Polynomial{c0, c1, c2, c3}: factor_go(U32.to_nat(limit), poly, 0, U32.is_eq(polynomial_eval(poly, 0), 0))
    case _: ArithInvalid{}

def factor_checked(poly: ArithResult, limit: U32, ok: Bool) -> ArithResult:
  match ok:
    case False{}: ArithInvalid{}
    case True{}: factor_type(poly, limit)

def factor_monic(poly: ArithResult, +limit: U32) -> ArithResult:
  factor_checked(poly, limit, U32.is_le(limit, 100000))

# Equality of two nonnegative-coefficient cubics represents a signed equation.
# Coefficients and x are <=1000, so every intermediate is below 2^48.
def exact_poly_ok(poly: ExactPolynomial) -> Bool:
  match poly:
    case ExactPolynomial{c0, c1, c2, c3}:
      +limit = Nat.pow(10n, 3n)
      Bool.and(Bool.and(Nat.is_le(c0, limit), Nat.is_le(c1, limit)), Bool.and(Nat.is_le(c2, limit), Nat.is_le(c3, limit)))

def exact_eval(poly: ExactPolynomial, +x: Nat) -> Nat:
  match poly:
    case ExactPolynomial{c0, c1, c2, c3}:
      (c0 + (x * (c1 + (x * (c2 + (x * c3 : Nat) : Nat) : Nat) : Nat) : Nat) : Nat)

def first_root(x: Nat, first: Nat, choose: Bool) -> Nat:
  match choose:
    case True{}: x
    case False{}: first

def exact_finish(first: Nat, count: Nat, found: Bool) -> ExactResult:
  match found:
    case True{}: ExactRoots{first, count}
    case False{}: ExactNoRoot{}

def exact_roots_go(fuel: Nat, +left: ExactPolynomial, +right: ExactPolynomial, +x: Nat, first: Nat, count: Nat, +found: Bool) -> ExactResult:
  match fuel:
    case 0n: exact_finish(first, count, found)
    case 1n+rest:
      +equal = Nat.is_eq(exact_eval(left, x), exact_eval(right, x))
      exact_roots_go(rest, left, right, (x + 1n : Nat), first_root(x, first, Bool.and(equal, Bool.not(found))), (count + U32.to_nat(Bool.to_u32(equal)) : Nat), Bool.or(found, equal))

def exact_checked(+left: ExactPolynomial, +right: ExactPolynomial, +limit: Nat, ok: Bool) -> ExactResult:
  match ok:
    case False{}: ExactInvalid{}
    case True{}: exact_roots_go((limit + 1n : Nat), left, right, 0n, 0n, 0n, False{})

def exact_roots(+left: ExactPolynomial, +right: ExactPolynomial, +limit: Nat) -> ExactResult:
  exact_checked(left, right, limit, Bool.and(Nat.is_le(limit, Nat.pow(10n, 3n)), Bool.and(exact_poly_ok(left), exact_poly_ok(right))))

# Signed quotient coefficients are explicit positive/negative pairs.
def exact_factor_make(left: ExactPolynomial, right: ExactPolynomial, +root: Nat) -> ExactResult:
  match left right:
    case ExactPolynomial{l0, l1, l2, +l3} ExactPolynomial{r0, r1, r2, +r3}:
      +q1p = (l2 + (root * l3 : Nat) : Nat)
      +q1n = (r2 + (root * r3 : Nat) : Nat)
      +q0p = (l1 + (root * q1p : Nat) : Nat)
      +q0n = (r1 + (root * q1n : Nat) : Nat)
      ExactFactor{root, q0p, q0n, q1p, q1n, l3, r3}

def exact_factor_from(left: ExactPolynomial, right: ExactPolynomial, roots: ExactResult) -> ExactResult:
  match roots:
    case ExactRoots{first, count}: exact_factor_make(left, right, first)
    case ExactNoRoot{}: ExactNoRoot{}
    case _: ExactInvalid{}

def exact_factor(+left: ExactPolynomial, +right: ExactPolynomial, limit: Nat) -> ExactResult:
  exact_factor_from(left, right, exact_roots(left, right, limit))

# Exact cubic expansion for nonnegative-coefficient expressions. It fails closed
# if an intermediate degree exceeds 3 or any coefficient exceeds 1000.
def expansion_checked(poly: ExactPolynomial, ok: Bool) -> ExpansionResult:
  match ok:
    case True{}: ExactExpanded{poly}
    case False{}: ExpansionOverflow{}

def expansion_add(a: ExpansionResult, b: ExpansionResult) -> ExpansionResult:
  match a b:
    case ExactExpanded{ExactPolynomial{a0, a1, a2, a3}} ExactExpanded{ExactPolynomial{b0, b1, b2, b3}}:
      +poly = {ExactPolynomial{(a0 + b0 : Nat), (a1 + b1 : Nat), (a2 + b2 : Nat), (a3 + b3 : Nat)} : ExactPolynomial}
      expansion_checked(poly, exact_poly_ok(poly))
    case _ _: ExpansionOverflow{}

def expansion_mul(a: ExpansionResult, b: ExpansionResult) -> ExpansionResult:
  match a b:
    case ExactExpanded{ExactPolynomial{+a0, +a1, +a2, +a3}} ExactExpanded{ExactPolynomial{+b0, +b1, +b2, +b3}}:
      +c0 = (a0 * b0 : Nat)
      +c1 = ((a0 * b1 : Nat) + (a1 * b0 : Nat) : Nat)
      +c2 = (((a0 * b2 : Nat) + (a1 * b1 : Nat) : Nat) + (a2 * b0 : Nat) : Nat)
      +c3 = ((((a0 * b3 : Nat) + (a1 * b2 : Nat) : Nat) + (a2 * b1 : Nat) : Nat) + (a3 * b0 : Nat) : Nat)
      +c4 = (((a1 * b3 : Nat) + (a2 * b2 : Nat) : Nat) + (a3 * b1 : Nat) : Nat)
      +c5 = ((a2 * b3 : Nat) + (a3 * b2 : Nat) : Nat)
      +c6 = (a3 * b3 : Nat)
      +poly = {ExactPolynomial{c0, c1, c2, c3} : ExactPolynomial}
      +high_zero = Bool.and(Nat.is_eq(c4, 0n), Bool.and(Nat.is_eq(c5, 0n), Nat.is_eq(c6, 0n)))
      expansion_checked(poly, Bool.and(exact_poly_ok(poly), high_zero))
    case _ _: ExpansionOverflow{}

def exact_expand(expr: ExactExpr) -> ExpansionResult:
  match expr:
    case ExactConst{value}:
      +poly = {ExactPolynomial{value, 0n, 0n, 0n} : ExactPolynomial}
      expansion_checked(poly, exact_poly_ok(poly))
    case ExactVar{}: ExactExpanded{ExactPolynomial{0n, 1n, 0n, 0n}}
    case ExactAdd{left, right}: expansion_add(exact_expand(left), exact_expand(right))
    case ExactMul{left, right}: expansion_mul(exact_expand(left), exact_expand(right))
