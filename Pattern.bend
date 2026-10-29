import Base
import ./Logic.bend as L
import ./Rewrite.bend as R
import ./Proof.bend as Proof

# Metavariables (Meta) are distinct from literal object variables (PAtom).
type Pattern is Data:
  PTrue{}
  PFalse{}
  PAtom{id: U32}
  Meta{id: U32}
  PNot{expr: Pattern}
  PAnd{left: Pattern, right: Pattern}
  POr{left: Pattern, right: Pattern}
  PXor{left: Pattern, right: Pattern}

type Slot is Data:
  SlotEmpty{}
  SlotBound{expr: L.Expr}

type Slots is Data:
  Slots{s0: Slot, s1: Slot, s2: Slot, s3: Slot}

type SlotResult is Data:
  SlotOK{slot: Slot}
  SlotMismatch{}

type MatchResult is Data:
  Matched{slots: Slots}
  Mismatch{}
  BadPattern{}

type GateResult is Data:
  GateAccepted{expr: L.Expr}
  GateRejected{assignment: U32}
  GateInvalid{}
  GateRepeatDone{expr: L.Expr, steps: Nat}
  GateRepeatLimit{expr: L.Expr, steps: Nat}

type TemplateResult is Data:
  Built{expr: L.Expr}
  TemplateInvalid{}

def depth(pattern: Pattern) -> Nat:
  match pattern:
    case PTrue{}: 1n
    case PFalse{}: 1n
    case PAtom{id}: 1n
    case Meta{id}: 1n
    case PNot{expr}: (1n + depth(expr) : Nat)
    case PAnd{left, right}: (1n + Nat.max(depth(left), depth(right)) : Nat)
    case POr{left, right}: (1n + Nat.max(depth(left), depth(right)) : Nat)
    case PXor{left, right}: (1n + Nat.max(depth(left), depth(right)) : Nat)

def pattern_valid(pattern: Pattern) -> Bool:
  match pattern:
    case PTrue{}: True{}
    case PFalse{}: True{}
    case PAtom{id}: True{}
    case Meta{id}: U32.is_lt(id, 4)
    case PNot{expr}: pattern_valid(expr)
    case PAnd{left, right}: Bool.and(pattern_valid(left), pattern_valid(right))
    case POr{left, right}: Bool.and(pattern_valid(left), pattern_valid(right))
    case PXor{left, right}: Bool.and(pattern_valid(left), pattern_valid(right))

def meta_mask(pattern: Pattern) -> U32:
  match pattern:
    case PTrue{}: 0
    case PFalse{}: 0
    case PAtom{id}: 0
    case Meta{id}: U32.shln(1, U32.to_nat(id))
    case PNot{expr}: meta_mask(expr)
    case PAnd{left, right}: U32.or(meta_mask(left), meta_mask(right))
    case POr{left, right}: U32.or(meta_mask(left), meta_mask(right))
    case PXor{left, right}: U32.or(meta_mask(left), meta_mask(right))

def slot_decide(slot: Slot, same: Bool) -> SlotResult:
  match same:
    case True{}: SlotOK{slot}
    case False{}: SlotMismatch{}

def update_slot(slot: Slot, +expr: L.Expr) -> SlotResult:
  match slot:
    case SlotEmpty{}: SlotOK{SlotBound{expr}}
    case SlotBound{+old}: slot_decide(SlotBound{old}, R.expr_equal(old, expr))

def merge0(result: SlotResult, b: Slot, c: Slot, d: Slot) -> MatchResult:
  match result:
    case SlotMismatch{}: Mismatch{}
    case SlotOK{slot}: Matched{Slots{slot, b, c, d}}

def merge1(result: SlotResult, a: Slot, c: Slot, d: Slot) -> MatchResult:
  match result:
    case SlotMismatch{}: Mismatch{}
    case SlotOK{slot}: Matched{Slots{a, slot, c, d}}

def merge2(result: SlotResult, a: Slot, b: Slot, d: Slot) -> MatchResult:
  match result:
    case SlotMismatch{}: Mismatch{}
    case SlotOK{slot}: Matched{Slots{a, b, slot, d}}

def merge3(result: SlotResult, a: Slot, b: Slot, c: Slot) -> MatchResult:
  match result:
    case SlotMismatch{}: Mismatch{}
    case SlotOK{slot}: Matched{Slots{a, b, c, slot}}

def bind(id: U32, expr: L.Expr, slots: Slots) -> MatchResult:
  match id slots:
    case 0 Slots{a, b, c, d}: merge0(update_slot(a, expr), b, c, d)
    case 1 Slots{a, b, c, d}: merge1(update_slot(b, expr), a, c, d)
    case 2 Slots{a, b, c, d}: merge2(update_slot(c, expr), a, b, d)
    case 3 Slots{a, b, c, d}: merge3(update_slot(d, expr), a, b, c)
    case _ _: BadPattern{}

def atom_match(slots: Slots, same: Bool) -> MatchResult:
  match same:
    case True{}: Matched{slots}
    case False{}: Mismatch{}

def match_go(fuel: Nat, pattern: Pattern, +expr: L.Expr, prior: MatchResult) -> MatchResult:
  match fuel pattern expr prior:
    case _ _ _ Mismatch{}: Mismatch{}
    case _ _ _ BadPattern{}: BadPattern{}
    case 0n _ _ _: BadPattern{}
    case 1n+rest PTrue{} L.ETrue{} Matched{slots}: Matched{slots}
    case 1n+rest PFalse{} L.EFalse{} Matched{slots}: Matched{slots}
    case 1n+rest PAtom{x} L.EVar{y} Matched{slots}: atom_match(slots, U32.is_eq(x, y))
    case 1n+rest Meta{id} _ Matched{slots}: bind(id, expr, slots)
    case 1n+rest PNot{p} L.ENot{e} Matched{slots}: match_go(rest, p, e, Matched{slots})
    case 1n++rest PAnd{pl, pr} L.EAnd{el, er} Matched{slots}:
      match_go(rest, pr, er, match_go(rest, pl, el, Matched{slots}))
    case 1n++rest POr{pl, pr} L.EOr{el, er} Matched{slots}:
      match_go(rest, pr, er, match_go(rest, pl, el, Matched{slots}))
    case 1n++rest PXor{pl, pr} L.EXor{el, er} Matched{slots}:
      match_go(rest, pr, er, match_go(rest, pl, el, Matched{slots}))
    case _ _ _ _: Mismatch{}

def match_checked(+pattern: Pattern, expr: L.Expr, ok: Bool) -> MatchResult:
  match ok:
    case False{}: BadPattern{}
    case True{}: match_go(depth(pattern), pattern, expr, Matched{Slots{SlotEmpty{}, SlotEmpty{}, SlotEmpty{}, SlotEmpty{}}})

def match_root(+pattern: Pattern, expr: L.Expr) -> MatchResult:
  match_checked(pattern, expr, Bool.and(Nat.is_le(depth(pattern), 64n), pattern_valid(pattern)))

def slot_value(slot: Slot) -> TemplateResult:
  match slot:
    case SlotEmpty{}: TemplateInvalid{}
    case SlotBound{expr}: Built{expr}

def lookup(id: U32, slots: Slots) -> TemplateResult:
  match id slots:
    case 0 Slots{a, b, c, d}: slot_value(a)
    case 1 Slots{a, b, c, d}: slot_value(b)
    case 2 Slots{a, b, c, d}: slot_value(c)
    case 3 Slots{a, b, c, d}: slot_value(d)
    case _ _: TemplateInvalid{}

def combine_not(result: TemplateResult) -> TemplateResult:
  match result:
    case Built{expr}: Built{L.ENot{expr}}
    case TemplateInvalid{}: TemplateInvalid{}

def combine_and(a: TemplateResult, b: TemplateResult) -> TemplateResult:
  match a b:
    case Built{left} Built{right}: Built{L.EAnd{left, right}}
    case _ _: TemplateInvalid{}

def combine_or(a: TemplateResult, b: TemplateResult) -> TemplateResult:
  match a b:
    case Built{left} Built{right}: Built{L.EOr{left, right}}
    case _ _: TemplateInvalid{}

def combine_xor(a: TemplateResult, b: TemplateResult) -> TemplateResult:
  match a b:
    case Built{left} Built{right}: Built{L.EXor{left, right}}
    case _ _: TemplateInvalid{}

def instantiate(pattern: Pattern, +slots: Slots) -> TemplateResult:
  match pattern:
    case PTrue{}: Built{L.ETrue{}}
    case PFalse{}: Built{L.EFalse{}}
    case PAtom{id}: Built{L.EVar{id}}
    case Meta{id}: lookup(id, slots)
    case PNot{expr}: combine_not(instantiate(expr, slots))
    case PAnd{left, right}: combine_and(instantiate(left, slots), instantiate(right, slots))
    case POr{left, right}: combine_or(instantiate(left, slots), instantiate(right, slots))
    case PXor{left, right}: combine_xor(instantiate(left, slots), instantiate(right, slots))

def rewrite_go(expr: L.Expr, +pattern: Pattern, +replacement: Pattern, result: MatchResult) -> TemplateResult:
  match expr result:
    case _ Matched{slots}: instantiate(replacement, slots)
    case _ BadPattern{}: TemplateInvalid{}
    case L.ETrue{} Mismatch{}: Built{L.ETrue{}}
    case L.EFalse{} Mismatch{}: Built{L.EFalse{}}
    case L.EVar{id} Mismatch{}: Built{L.EVar{id}}
    case L.ENot{+inner} Mismatch{}:
      combine_not(rewrite_go(inner, pattern, replacement, match_root(pattern, inner)))
    case L.EAnd{+left, +right} Mismatch{}:
      combine_and(rewrite_go(left, pattern, replacement, match_root(pattern, left)), rewrite_go(right, pattern, replacement, match_root(pattern, right)))
    case L.EOr{+left, +right} Mismatch{}:
      combine_or(rewrite_go(left, pattern, replacement, match_root(pattern, left)), rewrite_go(right, pattern, replacement, match_root(pattern, right)))
    case L.EXor{+left, +right} Mismatch{}:
      combine_xor(rewrite_go(left, pattern, replacement, match_root(pattern, left)), rewrite_go(right, pattern, replacement, match_root(pattern, right)))

def rewrite_validated(+expr: L.Expr, +pattern: Pattern, replacement: Pattern, valid: Bool) -> TemplateResult:
  match valid:
    case False{}: TemplateInvalid{}
    case True{}: rewrite_go(expr, pattern, replacement, match_root(pattern, expr))

def rewrite_all(+expr: L.Expr, +pattern: Pattern, +replacement: Pattern) -> TemplateResult:
  +valid = Bool.and(Bool.and(pattern_valid(pattern), pattern_valid(replacement)), Bool.and(Nat.is_le(depth(pattern), 64n), Nat.is_le(depth(replacement), 64n)))
  +bound = U32.is_eq(U32.and(meta_mask(replacement), U32.not(meta_mask(pattern))), 0)
  rewrite_validated(expr, pattern, replacement, Bool.and(valid, bound))


def gate_outcome(expr: L.Expr, outcome: L.Outcome) -> GateResult:
  match outcome:
    case L.Equivalent{}: GateAccepted{expr}
    case L.Different{assignment}: GateRejected{assignment}
    case _: GateInvalid{}

def gate_candidate(n: Nat, before: L.Expr, candidate: TemplateResult) -> GateResult:
  match candidate:
    case TemplateInvalid{}: GateInvalid{}
    case Built{+after}: gate_outcome(after, Proof.check(n, before, after))

def rewrite_checked(n: Nat, +expr: L.Expr, pattern: Pattern, replacement: Pattern) -> GateResult:
  gate_candidate(n, expr, rewrite_all(expr, pattern, replacement))


def gate_stable(current: L.Expr, result: GateResult) -> Bool:
  match result:
    case GateAccepted{next}: R.expr_equal(current, next)
    case _: False{}

def repeat_go(fuel: Nat, +n: Nat, +pattern: Pattern, +replacement: Pattern, +current: L.Expr, +steps: Nat, decision: GateResult, stable: Bool) -> GateResult:
  match fuel decision stable:
    case _ GateRejected{assignment} _: GateRejected{assignment}
    case _ GateInvalid{} _: GateInvalid{}
    case _ GateAccepted{candidate} True{}: GateRepeatDone{current, steps}
    case 0n GateAccepted{candidate} False{}: GateRepeatLimit{current, steps}
    case 1n+rest GateAccepted{+candidate} False{}:
      +next = rewrite_checked(n, candidate, pattern, replacement)
      repeat_go(rest, n, pattern, replacement, candidate, (steps + 1n : Nat), next, gate_stable(candidate, next))
    case _ _ _: GateInvalid{}

def repeat_start(+n: Nat, fuel: Nat, +expr: L.Expr, +pattern: Pattern, +replacement: Pattern, valid: Bool) -> GateResult:
  match valid:
    case False{}: GateInvalid{}
    case True{}:
      +decision = rewrite_checked(n, expr, pattern, replacement)
      repeat_go(fuel, n, pattern, replacement, expr, 0n, decision, gate_stable(expr, decision))

def repeat_checked(n: Nat, +fuel: Nat, expr: L.Expr, pattern: Pattern, replacement: Pattern) -> GateResult:
  repeat_start(n, fuel, expr, pattern, replacement, Nat.is_le(fuel, 16n))
