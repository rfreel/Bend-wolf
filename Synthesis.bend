import Base
import ./Logic.bend as L
import ./Rewrite.bend as R
import ./Proof.bend as P

type Choices is Data:
  Choices{a: L.Expr, b: L.Expr, c: L.Expr, d: L.Expr}

type Grammar is Data:
  Grammar{allow_not: Bool, allow_and: Bool, allow_or: Bool, allow_xor: Bool}

type SynthResult is Data:
  SynthInvalid{}
  SynthExpr{expr: L.Expr}
  SearchFound{index: U32, witnesses: U32}
  SearchExhausted{witnesses: U32}
  GrammarExhausted{}

def literal(id: U32, truth: Bool) -> L.Expr:
  match truth:
    case True{}: L.EVar{id}
    case False{}: L.ENot{L.EVar{id}}

def minterm(fuel: Nat, +assignment: U32, +pos: Nat, acc: L.Expr) -> L.Expr:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +truth = U32.is_ne(U32.and(U32.shrn(assignment, pos), 1), 0)
      minterm(rest, assignment, (pos + 1n : Nat), L.EAnd{acc, literal(U32.from_nat(pos), truth)})

def add_minterm(acc: L.Expr, term: L.Expr, selected: Bool) -> L.Expr:
  match selected:
    case False{}: acc
    case True{}: L.EOr{acc, term}

def dnf_go(fuel: Nat, +n: Nat, +bits: U32, +assignment: U32, acc: L.Expr) -> L.Expr:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +selected = U32.is_ne(U32.and(U32.shrn(bits, U32.to_nat(assignment)), 1), 0)
      dnf_go(rest, n, bits, (assignment + 1 : U32), add_minterm(acc, minterm(n, assignment, 0n, L.ETrue{}), selected))

def dnf_bits(+n: Nat, bits: U32, ok: Bool) -> SynthResult:
  match ok:
    case False{}: SynthInvalid{}
    case True{}: SynthExpr{dnf_go(Nat.pow(2n, n), n, bits, 0, L.EFalse{})}

def dnf_range(+n: Nat, +bits: U32, ok: Bool) -> SynthResult:
  match ok:
    case False{}: SynthInvalid{}
    case True{}:
      +high = U32.shln(4294967295, Nat.pow(2n, n))
      dnf_bits(n, bits, U32.is_eq(U32.and(bits, high), 0))

def dnf(+n: Nat, bits: U32) -> SynthResult:
  dnf_range(n, bits, Nat.is_le(n, 5n))

def pick(choices: Choices, index: U32) -> L.Expr:
  match choices index:
    case Choices{a, b, c, d} 0: a
    case Choices{a, b, c, d} 1: b
    case Choices{a, b, c, d} 2: c
    case Choices{a, b, c, d} _: d

def sampled_decision(n: Nat, target: L.Expr, candidate: L.Expr, +different: U32, empty: Bool) -> L.Outcome:
  match empty:
    case True{}: P.check(n, target, candidate)
    case False{}:
      +lowest = U32.and(different, (0 - different : U32))
      L.Different{U32.from_nat(U32.log2(lowest))}

def sampled_keys(n: Nat, target: L.Expr, candidate: L.Expr, witnesses: U32, a: R.KeyResult, b: R.KeyResult) -> L.Outcome:
  match a b:
    case R.TruthKey{left} R.TruthKey{right}:
      +different = U32.and(U32.xor(left, right), witnesses)
      sampled_decision(n, target, candidate, different, U32.is_eq(different, 0))
    case _ _: L.Invalid{}

def sampled(+n: Nat, +target: L.Expr, +candidate: L.Expr, witnesses: U32) -> L.Outcome:
  sampled_keys(n, target, candidate, witnesses, R.truth_table(n, target), R.truth_table(n, candidate))

def cegis_go(fuel: Nat, +n: Nat, +target: L.Expr, +choices: Choices, +index: U32, +witnesses: U32, result: L.Outcome) -> SynthResult:
  match fuel result:
    case _ L.Equivalent{}: SearchFound{index, witnesses}
    case 0n L.Different{assignment}: SearchExhausted{U32.or(witnesses, U32.shln(1, U32.to_nat(assignment)))}
    case 1n+rest L.Different{assignment}:
      +next = (index + 1 : U32)
      +seen = U32.or(witnesses, U32.shln(1, U32.to_nat(assignment)))
      cegis_go(rest, n, target, choices, next, seen, sampled(n, target, pick(choices, next), seen))
    case _ _: SynthInvalid{}

def cegis_checked(+n: Nat, +target: L.Expr, +choices: Choices, ok: Bool) -> SynthResult:
  match ok:
    case False{}: SynthInvalid{}
    case True{}: cegis_go(3n, n, target, choices, 0, 0, P.check(n, target, pick(choices, 0)))

def cegis(+n: Nat, +target: L.Expr, choices: Choices) -> SynthResult:
  cegis_checked(n, target, choices, Bool.and(Nat.is_le(n, 5n), L.valid(target, n)))

# Finite grammar: constants, variables, optional negated variables, and one
# enabled binary operator applied to two such atoms. Enumerates 200 candidates.
def grammar_atom(index: U32) -> L.Expr:
  match index:
    case 0: L.EFalse{}
    case 1: L.ETrue{}
    case 2: L.EVar{0}
    case 3: L.EVar{1}
    case 4: L.EVar{2}
    case 5: L.ENot{L.EVar{0}}
    case 6: L.ENot{L.EVar{1}}
    case _: L.ENot{L.EVar{2}}

def atom_allowed(index: U32, config: Grammar) -> Bool:
  match config:
    case Grammar{allow_not, allow_and, allow_or, allow_xor}: Bool.or(U32.is_lt(index, 5), allow_not)

def operation_allowed(op: U32, config: Grammar) -> Bool:
  match op config:
    case 0 Grammar{neg, conjunction, disjunction, exclusive}: conjunction
    case 1 Grammar{neg, conjunction, disjunction, exclusive}: disjunction
    case 2 Grammar{neg, conjunction, disjunction, exclusive}: exclusive
    case _ _: False{}

def grammar_binary(op: U32, left: L.Expr, right: L.Expr) -> L.Expr:
  match op:
    case 0: L.EAnd{left, right}
    case 1: L.EOr{left, right}
    case _: L.EXor{left, right}

def grammar_expr_select(+index: U32, atom: Bool) -> L.Expr:
  match atom:
    case True{}: grammar_atom(index)
    case False{}:
      +offset = (index - 8 : U32)
      +op = U32.shrn(offset, 6n)
      +left = U32.and(U32.shrn(offset, 3n), 7)
      +right = U32.and(offset, 7)
      grammar_binary(op, grammar_atom(left), grammar_atom(right))

def grammar_expr(+index: U32) -> L.Expr:
  grammar_expr_select(index, U32.is_lt(index, 8))

def grammar_allowed_select(+index: U32, +config: Grammar, atom: Bool) -> Bool:
  match atom:
    case True{}: atom_allowed(index, config)
    case False{}:
      +offset = (index - 8 : U32)
      +op = U32.shrn(offset, 6n)
      +left = U32.and(U32.shrn(offset, 3n), 7)
      +right = U32.and(offset, 7)
      Bool.and(operation_allowed(op, config), Bool.and(atom_allowed(left, config), atom_allowed(right, config)))

def grammar_allowed(+index: U32, config: Grammar) -> Bool:
  grammar_allowed_select(index, config, U32.is_lt(index, 8))

def matching_key(bits: U32, key: R.KeyResult) -> Bool:
  match key:
    case R.TruthKey{value}: U32.is_eq(bits, value)
    case R.KeyInvalid{}: False{}

def grammar_match(+n: Nat, bits: U32, +config: Grammar, +index: U32) -> Bool:
  Bool.and(grammar_allowed(index, config), matching_key(bits, R.truth_table(n, grammar_expr(index))))

def grammar_go(fuel: Nat, +n: Nat, +bits: U32, +config: Grammar, +index: U32, found: Bool) -> SynthResult:
  match fuel found:
    case _ True{}: SynthExpr{grammar_expr(index)}
    case 0n False{}: GrammarExhausted{}
    case 1n+rest False{}:
      +next = (index + 1 : U32)
      grammar_go(rest, n, bits, config, next, grammar_match(n, bits, config, next))

def grammar_bits(+n: Nat, +bits: U32, +config: Grammar, ok: Bool) -> SynthResult:
  match ok:
    case False{}: SynthInvalid{}
    case True{}: grammar_go(199n, n, bits, config, 0, grammar_match(n, bits, config, 0))

def grammar_range(+n: Nat, +bits: U32, config: Grammar, ok: Bool) -> SynthResult:
  match ok:
    case False{}: SynthInvalid{}
    case True{}:
      +high = U32.shln(4294967295, Nat.pow(2n, n))
      grammar_bits(n, bits, config, U32.is_eq(U32.and(bits, high), 0))

def synthesize_grammar(+n: Nat, bits: U32, config: Grammar) -> SynthResult:
  grammar_range(n, bits, config, Nat.is_le(n, 3n))
