import Base

# The inequality (ap-an)*x + (bp-bn) <= 0, or < 0 when strict.
# Coefficients are exact naturals <=1000; x ranges over all reals.
type Inequality is Data:
  Inequality{ap: Nat, an: Nat, bp: Nat, bn: Nat, strict: Bool}

type RealResult is Data:
  RealInvalid{}
  RealTrue{}
  RealFalse{}

def valid(ineq: Inequality) -> Bool:
  match ineq:
    case Inequality{ap, an, bp, bn, strict}:
      +limit = Nat.pow(10n, 3n)
      Bool.and(Bool.and(Nat.is_le(ap, limit), Nat.is_le(an, limit)), Bool.and(Nat.is_le(bp, limit), Nat.is_le(bn, limit)))

def compare(pos: Nat, neg: Nat, strict: Bool) -> Bool:
  match strict:
    case True{}: Nat.is_lt(pos, neg)
    case False{}: Nat.is_le(pos, neg)

def absdiff(+p: Nat, +n: Nat) -> Nat:
  ((p - n : Nat) + (n - p : Nat) : Nat)

def exists_bool(a: Inequality, b: Inequality) -> Bool:
  match a b:
    case Inequality{+ap, +an, +bp, +bn, +sa} Inequality{+cp, +cn, +dp, +dn, +sb}:
      +nonzero_a = Nat.is_ne(ap, an)
      +nonzero_b = Nat.is_ne(cp, cn)
      +constant_a = Bool.or(nonzero_a, compare(bp, bn, sa))
      +constant_b = Bool.or(nonzero_b, compare(dp, dn, sb))
      +opposite = Bool.and(Bool.and(nonzero_a, nonzero_b), Bool.xor(Nat.is_gt(ap, an), Nat.is_gt(cp, cn)))
      +ma = absdiff(ap, an)
      +mb = absdiff(cp, cn)
      +positive = ((bp * mb : Nat) + (dp * ma : Nat) : Nat)
      +negative = ((bn * mb : Nat) + (dn * ma : Nat) : Nat)
      +compatible = compare(positive, negative, Bool.or(sa, sb))
      Bool.and(Bool.and(constant_a, constant_b), Bool.or(Bool.not(opposite), compatible))

def forall_bool(a: Inequality, b: Inequality) -> Bool:
  match a b:
    case Inequality{ap, an, bp, bn, sa} Inequality{cp, cn, dp, dn, sb}:
      Bool.and(Bool.and(Nat.is_eq(ap, an), Nat.is_eq(cp, cn)), Bool.and(compare(bp, bn, sa), compare(dp, dn, sb)))

def result(ok: Bool) -> RealResult:
  match ok:
    case True{}: RealTrue{}
    case False{}: RealFalse{}

def exists_checked(a: Inequality, b: Inequality, ok: Bool) -> RealResult:
  match ok:
    case False{}: RealInvalid{}
    case True{}: result(exists_bool(a, b))

def forall_checked(a: Inequality, b: Inequality, ok: Bool) -> RealResult:
  match ok:
    case False{}: RealInvalid{}
    case True{}: result(forall_bool(a, b))

def exists_pair(+a: Inequality, +b: Inequality) -> RealResult:
  exists_checked(a, b, Bool.and(valid(a), valid(b)))

def forall_pair(+a: Inequality, +b: Inequality) -> RealResult:
  forall_checked(a, b, Bool.and(valid(a), valid(b)))
