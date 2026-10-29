import Base
import ./Graph.bend as G
import ./Dynamics.bend as D

type Experiment is Data:
  Experiment{h_num: Nat, h_den: Nat, n_num: Nat, n_den: Nat}

type InferResult is Data:
  InferInvalid{}
  ImpossibleEvidence{}
  Posterior{numerator: Nat, denominator: Nat}
  ExperimentChoice{choice: U32}
  Intervention{numerator: Nat, denominator: Nat}
  InterventionChoice{choice: U32, numerator: Nat, denominator: Nat}
  Starts{mask: U32}

def probability_ok(num: Nat, +den: Nat, limit: Nat) -> Bool:
  Bool.and(Nat.is_gt(den, 0n), Bool.and(Nat.is_le(den, limit), Nat.is_le(num, den)))

def posterior_result(num: Nat, den: Nat, zero: Bool) -> InferResult:
  match zero:
    case True{}: ImpossibleEvidence{}
    case False{}: Posterior{num, den}

def bayes_checked(+p: Nat, +q: Nat, +a: Nat, +b: Nat, +c: Nat, +d: Nat, valid: Bool) -> InferResult:
  match valid:
    case False{}: InferInvalid{}
    case True{}:
      +yes = ((p * a : Nat) * d : Nat)
      +no = (((q - p : Nat) * c : Nat) * b : Nat)
      +den = (yes + no : Nat)
      posterior_result(yes, den, Nat.is_eq(den, 0n))

def bayes(+p: Nat, +q: Nat, +a: Nat, +b: Nat, +c: Nat, +d: Nat) -> InferResult:
  bayes_checked(p, q, a, b, c, d, Bool.and(probability_ok(p, q, Nat.pow(2n, 10n)), Bool.and(probability_ok(a, b, Nat.pow(2n, 10n)), probability_ok(c, d, Nat.pow(2n, 10n)))))

def experiment_ok(ex: Experiment) -> Bool:
  match ex:
    case Experiment{a, b, c, d}: Bool.and(probability_ok(a, b, 64n), probability_ok(c, d, 64n))

def accuracy_numerator(+p: Nat, +q: Nat, ex: Experiment) -> Nat:
  match ex:
    case Experiment{+a, +b, +c, +d}:
      +yes_h = ((p * a : Nat) * d : Nat)
      +yes_n = (((q - p : Nat) * c : Nat) * b : Nat)
      +no_h = ((p * (b - a : Nat) : Nat) * d : Nat)
      +no_n = (((q - p : Nat) * (d - c : Nat) : Nat) * b : Nat)
      (Nat.max(yes_h, yes_n) + Nat.max(no_h, no_n) : Nat)

def accuracy_denominator(q: Nat, ex: Experiment) -> Nat:
  match ex:
    case Experiment{a, b, c, d}: ((q * b : Nat) * d : Nat)

def select_experiment(first: Bool) -> InferResult:
  match first:
    case True{}: ExperimentChoice{0}
    case False{}: ExperimentChoice{1}

def choose_checked(+p: Nat, +q: Nat, +a: Experiment, +b: Experiment, ok: Bool) -> InferResult:
  match ok:
    case False{}: InferInvalid{}
    case True{}:
      +left = (accuracy_numerator(p, q, a) * accuracy_denominator(q, b) : Nat)
      +right = (accuracy_numerator(p, q, b) * accuracy_denominator(q, a) : Nat)
      select_experiment(Nat.is_ge(left, right))

def choose_experiment(+p: Nat, +q: Nat, +a: Experiment, +b: Experiment) -> InferResult:
  choose_checked(p, q, a, b, Bool.and(probability_ok(p, q, 64n), Bool.and(experiment_ok(a), experiment_ok(b))))

def intervention_checked(+table: U32, +p: Nat, +q: Nat, x: U32, ok: Bool) -> InferResult:
  match ok:
    case False{}: InferInvalid{}
    case True{}:
      +position = (2n * U32.to_nat(x) : Nat)
      +y0 = U32.to_nat(U32.and(U32.shrn(table, position), 1))
      +y1 = U32.to_nat(U32.and(U32.shrn(table, (position + 1n : Nat)), 1))
      Intervention{(((q - p : Nat) * y0 : Nat) + (p * y1 : Nat) : Nat), q}

def intervene(+table: U32, +p: Nat, +q: Nat, +x: U32) -> InferResult:
  intervention_checked(table, p, q, x, Bool.and(U32.is_lt(table, 16), Bool.and(U32.is_lt(x, 2), probability_ok(p, q, Nat.pow(2n, 10n)))))

# Observation bits are ordered by time: least significant bit is the first.
def matches_trace(fuel: Nat, +code: U32, +emissions: U32, +observations: U32, +state: U32, +pos: Nat) -> Bool:
  match fuel:
    case 0n: True{}
    case 1n+rest:
      +actual = U32.and(U32.shrn(emissions, U32.to_nat(state)), 1)
      +expected = U32.and(U32.shrn(observations, pos), 1)
      Bool.and(U32.is_eq(actual, expected), matches_trace(rest, code, emissions, observations, G.mapped(code, U32.to_nat(state)), (pos + 1n : Nat)))

def starts_go(fuel: Nat, +len: Nat, +code: U32, +emissions: U32, +observations: U32, +state: U32, mask: U32) -> U32:
  match fuel:
    case 0n: mask
    case 1n+rest:
      +is_match = Bool.to_u32(matches_trace(len, code, emissions, observations, state, 0n))
      starts_go(rest, len, code, emissions, observations, (state + 1 : U32), U32.or(mask, U32.shln(is_match, U32.to_nat(state))))

def starts_bits_checked(n: Nat, code: U32, emissions: U32, observations: U32, len: Nat, ok: Bool) -> InferResult:
  match ok:
    case False{}: InferInvalid{}
    case True{}: Starts{starts_go(n, len, code, emissions, observations, 0, 0)}

def starts_range_checked(+n: Nat, +code: U32, +emissions: U32, +observations: U32, +len: Nat, ok: Bool) -> InferResult:
  match ok:
    case False{}: InferInvalid{}
    case True{}:
      +valid_emissions = U32.is_eq(U32.and(emissions, U32.not(G.nodes_mask(n))), 0)
      +valid_obs = U32.is_eq(U32.and(observations, U32.shln(4294967295, len)), 0)
      starts_bits_checked(n, code, emissions, observations, len, Bool.and(valid_emissions, valid_obs))

def infer_starts(+n: Nat, +code: U32, +emissions: U32, +observations: U32, +len: Nat) -> InferResult:
  starts_range_checked(n, code, emissions, observations, len, Bool.and(D.map_valid(n, code), Nat.is_le(len, 16n)))

def intervention_pick(a: Nat, b: Nat, den: Nat, first: Bool) -> InferResult:
  match first:
    case True{}: InterventionChoice{0, a, den}
    case False{}: InterventionChoice{1, b, den}

def intervention_compare(a: InferResult, b: InferResult) -> InferResult:
  match a b:
    case Intervention{+na, dena} Intervention{+nb, denb}:
      intervention_pick(na, nb, dena, Nat.is_ge(na, nb))
    case _ _: InferInvalid{}

def choose_intervention(+table: U32, +p: Nat, +q: Nat) -> InferResult:
  intervention_compare(intervene(table, p, q, 0), intervene(table, p, q, 1))
