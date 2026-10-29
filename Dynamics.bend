import Base
import ./Graph.bend as G

type Counts is Data:
  Counts{c0: U32, c1: U32, c2: U32, c3: U32}

type DynResult is Data:
  DynInvalid{}
  State{value: U32}
  Orbit{preperiod: Nat, period: Nat, entry: U32}
  Recurrence{first: U32, second: U32, next: U32}
  NoRecurrence{}
  Invariant{mask: U32}
  WalkCount{value: U32}
  LinearInvariant{a: U32, b: U32}
  NoLinearInvariant{}

def map_valid_go(fuel: Nat, +n: Nat, +code: U32, +pos: Nat) -> Bool:
  match fuel:
    case 0n: True{}
    case 1n+rest: Bool.and(U32.is_lt(G.mapped(code, pos), U32.from_nat(n)), map_valid_go(rest, n, code, (pos + 1n : Nat)))

def map_valid_checked(+n: Nat, +code: U32, bounds: Bool) -> Bool:
  match bounds:
    case False{}: False{}
    case True{}: Bool.and(U32.is_lt(code, U32.from_nat(Nat.pow(4n, n))), map_valid_go(n, n, code, 0n))

def map_valid(+n: Nat, code: U32) -> Bool:
  map_valid_checked(n, code, Bool.and(Nat.is_ge(n, 1n), Nat.is_le(n, 4n)))

def iterate_go(steps: Nat, +code: U32, state: U32) -> U32:
  match steps:
    case 0n: state
    case 1n+rest: iterate_go(rest, code, G.mapped(code, U32.to_nat(state)))

def iterate_checked(n: Nat, code: U32, state: U32, steps: Nat, ok: Bool) -> DynResult:
  match ok:
    case False{}: DynInvalid{}
    case True{}: State{iterate_go(steps, code, state)}

def iterate(+n: Nat, +code: U32, +state: U32, +steps: Nat) -> DynResult:
  iterate_checked(n, code, state, steps, Bool.and(map_valid(n, code), Bool.and(U32.is_lt(state, U32.from_nat(n)), Nat.is_le(steps, Nat.pow(10n, 6n)))))

def orbit_go(fuel: Nat, +code: U32, +state: U32, +seen: U32, +times: U32, +time: Nat, found: Bool) -> DynResult:
  match fuel found:
    case _ True{}:
      +first = U32.to_nat(U32.and(U32.shrn(times, (3n * U32.to_nat(state) : Nat)), 7))
      Orbit{first, (time - first : Nat), state}
    case 0n False{}: DynInvalid{}
    case 1n+rest False{}:
      +mark = U32.shln(1, U32.to_nat(state))
      +next = G.mapped(code, U32.to_nat(state))
      +new_seen = U32.or(seen, mark)
      +new_times = U32.or(times, U32.shln(U32.from_nat(time), (3n * U32.to_nat(state) : Nat)))
      orbit_go(rest, code, next, new_seen, new_times, (time + 1n : Nat), U32.is_ne(U32.and(new_seen, U32.shln(1, U32.to_nat(next))), 0))

def orbit_checked(n: Nat, code: U32, state: U32, ok: Bool) -> DynResult:
  match ok:
    case False{}: DynInvalid{}
    case True{}: orbit_go(n, code, state, 0, 0, 0n, False{})

def orbit(+n: Nat, +code: U32, +state: U32) -> DynResult:
  orbit_checked(n, code, state, Bool.and(map_valid(n, code), U32.is_lt(state, U32.from_nat(n))))

def recurrence_ok(+a: U32, +b: U32, +s0: U32, +s1: U32, +s2: U32, +s3: U32, +s4: U32, +s5: U32) -> Bool:
  Bool.and(U32.is_eq(s2, ((a * s1 : U32) + (b * s0 : U32) : U32)), Bool.and(U32.is_eq(s3, ((a * s2 : U32) + (b * s1 : U32) : U32)), Bool.and(U32.is_eq(s4, ((a * s3 : U32) + (b * s2 : U32) : U32)), U32.is_eq(s5, ((a * s4 : U32) + (b * s3 : U32) : U32)))))

def recurrence_go(fuel: Nat, +s0: U32, +s1: U32, +s2: U32, +s3: U32, +s4: U32, +s5: U32, +code: U32, ok: Bool) -> DynResult:
  match fuel ok:
    case _ True{}:
      +a = U32.and(code, 3)
      +b = U32.shrn(code, 2n)
      Recurrence{a, b, ((a * s5 : U32) + (b * s4 : U32) : U32)}
    case 0n False{}: NoRecurrence{}
    case 1n+rest False{}:
      +next = (code + 1 : U32)
      recurrence_go(rest, s0, s1, s2, s3, s4, s5, next, recurrence_ok(U32.and(next, 3), U32.shrn(next, 2n), s0, s1, s2, s3, s4, s5))

def recurrence(+s0: U32, +s1: U32, +s2: U32, +s3: U32, +s4: U32, +s5: U32) -> DynResult:
  recurrence_go(15n, s0, s1, s2, s3, s4, s5, 0, recurrence_ok(0, 0, s0, s1, s2, s3, s4, s5))

# Greatest closed subset of an allowed set for the supplied finite transition.
def filter_states(fuel: Nat, +code: U32, +current: U32, +state: U32, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +next = G.mapped(code, U32.to_nat(state))
      +here = U32.and(U32.shrn(current, U32.to_nat(state)), 1)
      +there = U32.and(U32.shrn(current, U32.to_nat(next)), 1)
      filter_states(rest, code, current, (state + 1 : U32), U32.or(acc, U32.shln(U32.and(here, there), U32.to_nat(state))))

def invariant_go(fuel: Nat, +n: Nat, +code: U32, current: U32) -> U32:
  match fuel:
    case 0n: current
    case 1n+rest: invariant_go(rest, n, code, filter_states(n, code, current, 0, 0))

def invariant_checked(+n: Nat, code: U32, allowed: U32, ok: Bool) -> DynResult:
  match ok:
    case False{}: DynInvalid{}
    case True{}: Invariant{invariant_go(n, n, code, allowed)}

def invariant_range(+n: Nat, code: U32, +allowed: U32, ok: Bool) -> DynResult:
  match ok:
    case False{}: DynInvalid{}
    case True{}: invariant_checked(n, code, allowed, U32.is_eq(U32.and(allowed, U32.not(G.nodes_mask(n))), 0))

def invariant(+n: Nat, +code: U32, allowed: U32) -> DynResult:
  invariant_range(n, code, allowed, map_valid(n, code))

def edge(edges: U32, u: Nat, v: Nat) -> U32:
  U32.and(U32.shrn(edges, ((4n * u : Nat) + v : Nat)), 1)

def count_target(+edges: U32, +target: Nat, +a: U32, +b: U32, +c: U32, +d: U32) -> U32:
  (((a * edge(edges, 0n, target) : U32) + (b * edge(edges, 1n, target) : U32) : U32) + ((c * edge(edges, 2n, target) : U32) + (d * edge(edges, 3n, target) : U32) : U32) : U32)

def advance_counts(+edges: U32, counts: Counts) -> Counts:
  match counts:
    case Counts{+a, +b, +c, +d}:
      Counts{count_target(edges, 0n, a, b, c, d), count_target(edges, 1n, a, b, c, d), count_target(edges, 2n, a, b, c, d), count_target(edges, 3n, a, b, c, d)}

def walks_go(fuel: Nat, +edges: U32, counts: Counts) -> Counts:
  match fuel:
    case 0n: counts
    case 1n+rest: walks_go(rest, edges, advance_counts(edges, counts))

def count_pick(counts: Counts, target: U32) -> U32:
  match counts target:
    case Counts{a, b, c, d} 0: a
    case Counts{a, b, c, d} 1: b
    case Counts{a, b, c, d} 2: c
    case Counts{a, b, c, d} _: d

def walks_checked(edges: U32, +start: U32, goal: U32, steps: Nat, ok: Bool) -> DynResult:
  match ok:
    case False{}: DynInvalid{}
    case True{}:
      +a = Bool.to_u32(U32.is_eq(start, 0))
      +b = Bool.to_u32(U32.is_eq(start, 1))
      +c = Bool.to_u32(U32.is_eq(start, 2))
      +d = Bool.to_u32(U32.is_eq(start, 3))
      WalkCount{count_pick(walks_go(steps, edges, Counts{a, b, c, d}), goal)}

def walks(+n: Nat, +edges: U32, +start: U32, +goal: U32, +steps: Nat) -> DynResult:
  walks_checked(edges, start, goal, steps, Bool.and(G.valid(n, edges), Bool.and(U32.is_lt(start, U32.from_nat(n)), Bool.and(U32.is_lt(goal, U32.from_nat(n)), Nat.is_le(steps, Nat.pow(10n, 3n))))))

# Search all nonzero coefficients a,b in 0..3 for an invariant a*x+b*y.
# Each coordinate is packed as one two-bit field per state.
def linear_value(+state: U32, +x: U32, +y: U32, a: U32, b: U32) -> U32:
  ((a * G.mapped(x, U32.to_nat(state)) : U32) + (b * G.mapped(y, U32.to_nat(state)) : U32) : U32)

def linear_check(fuel: Nat, +code: U32, +x: U32, +y: U32, +a: U32, +b: U32, +state: U32) -> Bool:
  match fuel:
    case 0n: True{}
    case 1n+rest:
      +next = G.mapped(code, U32.to_nat(state))
      +same = U32.is_eq(linear_value(state, x, y, a, b), linear_value(next, x, y, a, b))
      Bool.and(same, linear_check(rest, code, x, y, a, b, (state + 1 : U32)))

def linear_find(fuel: Nat, +n: Nat, +code: U32, +x: U32, +y: U32, +coeff: U32, valid: Bool) -> DynResult:
  match fuel valid:
    case _ True{}: LinearInvariant{U32.and(coeff, 3), U32.shrn(coeff, 2n)}
    case 0n False{}: NoLinearInvariant{}
    case 1n+rest False{}:
      +next = (coeff + 1 : U32)
      linear_find(rest, n, code, x, y, next, linear_check(n, code, x, y, U32.and(next, 3), U32.shrn(next, 2n), 0))

def linear_checked(+n: Nat, +code: U32, +x: U32, +y: U32, valid: Bool) -> DynResult:
  match valid:
    case False{}: DynInvalid{}
    case True{}: linear_find(14n, n, code, x, y, 1, linear_check(n, code, x, y, 1, 0, 0))

def linear_range(+n: Nat, code: U32, +x: U32, +y: U32, valid: Bool) -> DynResult:
  match valid:
    case False{}: DynInvalid{}
    case True{}:
      +limit = U32.from_nat(Nat.pow(4n, n))
      linear_checked(n, code, x, y, Bool.and(U32.is_lt(x, limit), U32.is_lt(y, limit)))

def find_linear_invariant(+n: Nat, +code: U32, x: U32, y: U32) -> DynResult:
  linear_range(n, code, x, y, map_valid(n, code))
