import Base
import ./Logic.bend as L

# Possible-value bits: 1 = false, 2 = true, 3 = either.
type AnalysisResult is Data:
  AnalysisInvalid{}
  AbstractValue{possible: U32}
  Safe{}
  Violation{assignment: U32}

def variable(flag: U32, known: Bool) -> U32:
  match known:
    case False{}: 3
    case True{}: (1 + flag : U32)

def abs_not(+x: U32) -> U32:
  U32.or(U32.shln(U32.and(x, 1), 1n), U32.shrn(U32.and(x, 2), 1n))

def abs_and(+a: U32, +b: U32) -> U32:
  U32.or(U32.or(U32.and(a, 1), U32.and(b, 1)), U32.and(U32.and(a, 2), U32.and(b, 2)))

def abs_or(+a: U32, +b: U32) -> U32:
  U32.or(U32.and(U32.and(a, 1), U32.and(b, 1)), U32.or(U32.and(a, 2), U32.and(b, 2)))

def abs_xor(+a: U32, +b: U32) -> U32:
  +af = U32.and(a, 1)
  +at = U32.shrn(U32.and(a, 2), 1n)
  +bf = U32.and(b, 1)
  +bt = U32.shrn(U32.and(b, 2), 1n)
  +f = U32.or(U32.and(af, bf), U32.and(at, bt))
  +t = U32.or(U32.and(af, bt), U32.and(at, bf))
  U32.or(f, U32.shln(t, 1n))

def eval(expr: L.Expr, +known: U32, +values: U32) -> U32:
  match expr:
    case L.ETrue{}: 2
    case L.EFalse{}: 1
    case L.EVar{id}:
      +bit = U32.shln(1, U32.to_nat(id))
      variable(Bool.to_u32(U32.is_ne(U32.and(values, bit), 0)), U32.is_ne(U32.and(known, bit), 0))
    case L.ENot{x}: abs_not(eval(x, known, values))
    case L.EAnd{left, right}: abs_and(eval(left, known, values), eval(right, known, values))
    case L.EOr{left, right}: abs_or(eval(left, known, values), eval(right, known, values))
    case L.EXor{left, right}: abs_xor(eval(left, known, values), eval(right, known, values))

def analyze_checked(expr: L.Expr, known: U32, values: U32, ok: Bool) -> AnalysisResult:
  match ok:
    case False{}: AnalysisInvalid{}
    case True{}: AbstractValue{eval(expr, known, values)}

def analyze_range(+n: Nat, +expr: L.Expr, +known: U32, +values: U32, in_range: Bool) -> AnalysisResult:
  match in_range:
    case False{}: AnalysisInvalid{}
    case True{}:
      +outside = U32.shln(4294967295, n)
      +ok = Bool.and(L.valid(expr, n), Bool.and(U32.is_eq(U32.and(known, outside), 0), U32.is_eq(U32.and(values, U32.not(known)), 0)))
      analyze_checked(expr, known, values, ok)

def analyze(+n: Nat, expr: L.Expr, known: U32, values: U32) -> AnalysisResult:
  analyze_range(n, expr, known, values, Nat.is_le(n, 16n))

def merge(a: AnalysisResult, b: AnalysisResult) -> AnalysisResult:
  match a b:
    case Violation{assignment} _: Violation{assignment}
    case Safe{} Violation{assignment}: Violation{assignment}
    case Safe{} Safe{}: Safe{}
    case _ _: AnalysisInvalid{}

# Counterexample-guided refinement of the overapproximating partial valuation.
def refine_go(fuel: Nat, +expr: L.Expr, +pos: Nat, +known: U32, +values: U32, possible: U32) -> AnalysisResult:
  match fuel possible:
    case _ 1: Safe{}
    case _ 2: Violation{values}
    case 0n _: AnalysisInvalid{}
    case 1n++rest _:
      +bit = U32.shln(1, pos)
      +next_known = U32.or(known, bit)
      +next_values = U32.or(values, bit)
      merge(refine_go(rest, expr, (pos + 1n : Nat), next_known, values, eval(expr, next_known, values)), refine_go(rest, expr, (pos + 1n : Nat), next_known, next_values, eval(expr, next_known, next_values)))

def counterexample_checked(+n: Nat, +expr: L.Expr, ok: Bool) -> AnalysisResult:
  match ok:
    case False{}: AnalysisInvalid{}
    case True{}: refine_go(n, expr, 0n, 0, 0, eval(expr, 0, 0))

def counterexample(+n: Nat, +expr: L.Expr) -> AnalysisResult:
  counterexample_checked(n, expr, Bool.and(Nat.is_le(n, 16n), L.valid(expr, n)))
