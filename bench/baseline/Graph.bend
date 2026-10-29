import Base

# Directed, unweighted graph on n <= 4 labeled vertices. Bit 4*u+v is u -> v.
type GraphResult is Data:
  GraphInvalid{}
  Distance{value: U32}
  Path{length: U32, nodes: U32}
  Unreachable{}
  Cyclic{}
  Acyclic{}
  GraphKey{nodes: Nat, edges: U32}
  Isomorphic{}
  NonIsomorphic{}
  Topology{code: U32}
  MinCut{size: U32, side: U32}
  ReducedCount{count: U32}

def nodes_mask(n: Nat) -> U32:
  U32.from_nat((Nat.pow(2n, n) - 1n : Nat))

def shape_ok(+n: Nat, edges: U32) -> Bool:
  +row = nodes_mask(n)
  +rows = U32.from_nat(((Nat.pow(16n, n) - 1n : Nat) / 15n : Nat))
  U32.is_eq(U32.and(edges, U32.not((row * rows : U32))), 0)

def valid_checked(n: Nat, edges: U32, in_range: Bool) -> Bool:
  match in_range:
    case False{}: False{}
    case True{}: shape_ok(n, edges)

def valid(+n: Nat, edges: U32) -> Bool:
  valid_checked(n, edges, Nat.is_le(n, 4n))

def neighbors(+edges: U32, +frontier: U32) -> U32:
  +r0 = U32.and(edges, 15)
  +r1 = U32.and(U32.shrn(edges, 4n), 15)
  +r2 = U32.and(U32.shrn(edges, 8n), 15)
  +r3 = U32.and(U32.shrn(edges, 12n), 15)
  +s0 = U32.and(frontier, 1)
  +s1 = U32.and(U32.shrn(frontier, 1n), 1)
  +s2 = U32.and(U32.shrn(frontier, 2n), 1)
  +s3 = U32.and(U32.shrn(frontier, 3n), 1)
  U32.or(U32.or((r0 * s0 : U32), (r1 * s1 : U32)), U32.or((r2 * s2 : U32), (r3 * s3 : U32)))

def distance_go(fuel: Nat, +edges: U32, +target: U32, +seen: U32, frontier: U32, +distance: U32, found: Bool) -> GraphResult:
  match fuel found:
    case _ True{}: Distance{distance}
    case 0n False{}: Unreachable{}
    case 1n+rest False{}:
      +next = U32.and(neighbors(edges, frontier), U32.not(seen))
      distance_go(rest, edges, target, U32.or(seen, next), next, (distance + 1 : U32), U32.is_ne(U32.and(next, target), 0))

def shortest_checked(n: Nat, edges: U32, +start: U32, +goal: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}:
      +s = U32.shln(1, U32.to_nat(start))
      +g = U32.shln(1, U32.to_nat(goal))
      distance_go(n, edges, g, s, s, 0, U32.is_eq(start, goal))

def shortest(+n: Nat, +edges: U32, +start: U32, +goal: U32) -> GraphResult:
  shortest_checked(n, edges, start, goal, Bool.and(valid(n, edges), Bool.and(U32.is_lt(start, U32.from_nat(n)), U32.is_lt(goal, U32.from_nat(n)))))

def reach_go(fuel: Nat, +edges: U32, +target: U32, +frontier: U32, found: Bool) -> Bool:
  match fuel found:
    case _ True{}: True{}
    case 0n False{}: False{}
    case 1n+rest False{}:
      +next = neighbors(edges, frontier)
      reach_go(rest, edges, target, next, U32.is_ne(U32.and(next, target), 0))

def cycle_go(fuel: Nat, +n: Nat, +edges: U32, +vertex: U32, found: Bool) -> Bool:
  match fuel found:
    case _ True{}: True{}
    case 0n False{}: False{}
    case 1n+rest False{}:
      +s = U32.shln(1, U32.to_nat(vertex))
      cycle_go(rest, n, edges, (vertex + 1 : U32), reach_go(n, edges, s, s, False{}))

def cycle_result(found: Bool) -> GraphResult:
  match found:
    case True{}: Cyclic{}
    case False{}: Acyclic{}

def cycle_checked(+n: Nat, edges: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: cycle_result(cycle_go(n, n, edges, 0, False{}))

def has_cycle(+n: Nat, +edges: U32) -> GraphResult:
  cycle_checked(n, edges, valid(n, edges))

def mapped(code: U32, pos: Nat) -> U32:
  U32.and(U32.shrn(code, (2n * pos : Nat)), 3)

def mapping_mask(fuel: Nat, +code: U32, +pos: Nat, seen: U32) -> U32:
  match fuel:
    case 0n: seen
    case 1n+rest:
      +digit = mapped(code, pos)
      mapping_mask(rest, code, (pos + 1n : Nat), U32.or(seen, U32.shln(1, U32.to_nat(digit))))

def relabel_go(fuel: Nat, +code: U32, +edges: U32, +pos: Nat, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +u = mapped(code, (pos / 4n : Nat))
      +v = mapped(code, (pos % 4n : Nat))
      +edge = U32.and(U32.shrn(edges, pos), 1)
      +newpos = U32.to_nat(((u * 4 : U32) + v : U32))
      relabel_go(rest, code, edges, (pos + 1n : Nat), U32.or(acc, U32.shln(edge, newpos)))

def candidate(+edges: U32, +code: U32, best: U32, admissible: Bool) -> U32:
  match admissible:
    case False{}: best
    case True{}: U32.min(best, relabel_go(16n, code, edges, 0n, 0))

def canonical_go(fuel: Nat, +n: Nat, +edges: U32, +code: U32, best: U32) -> U32:
  match fuel:
    case 0n: best
    case 1n+rest:
      +ok = U32.is_eq(mapping_mask(n, code, 0n, 0), nodes_mask(n))
      canonical_go(rest, n, edges, (code + 1 : U32), candidate(edges, code, best, ok))

def canonical_checked(+n: Nat, edges: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: GraphKey{n, canonical_go(Nat.pow(4n, n), n, edges, 0, 4294967295)}

def canonical(+n: Nat, +edges: U32) -> GraphResult:
  canonical_checked(n, edges, valid(n, edges))

def iso_bool(equal: Bool) -> GraphResult:
  match equal:
    case True{}: Isomorphic{}
    case False{}: NonIsomorphic{}

def compare_keys(left: GraphResult, right: GraphResult) -> GraphResult:
  match left right:
    case GraphKey{n1, e1} GraphKey{n2, e2}: iso_bool(Bool.and(Nat.is_eq(n1, n2), U32.is_eq(e1, e2)))
    case _ _: GraphInvalid{}

def isomorphic(+n: Nat, left: U32, right: U32) -> GraphResult:
  compare_keys(canonical(n, left), canonical(n, right))

# A mapping assigns each original vertex a rank; valid edges go to larger ranks.
def topo_go(fuel: Nat, +n: Nat, +edges: U32, +code: U32, found: Bool) -> GraphResult:
  match fuel found:
    case _ True{}: Topology{(code - 1 : U32)}
    case 0n False{}: Cyclic{}
    case 1n+rest False{}:
      +permutation = U32.is_eq(mapping_mask(n, code, 0n, 0), nodes_mask(n))
      +r = relabel_go(16n, code, edges, 0n, 0)
      +ordered = U32.is_eq(U32.and(r, U32.not(2254)), 0)
      topo_go(rest, n, edges, (code + 1 : U32), Bool.and(permutation, ordered))

def topo_checked(+n: Nat, edges: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: topo_go(Nat.pow(4n, n), n, edges, 0, False{})

def topological(+n: Nat, +edges: U32) -> GraphResult:
  topo_checked(n, edges, valid(n, edges))

def transpose_go(fuel: Nat, +edges: U32, +pos: Nat, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +u = (pos / 4n : Nat)
      +v = (pos % 4n : Nat)
      +edge = U32.and(U32.shrn(edges, pos), 1)
      +dest = ((v * 4n : Nat) + u : Nat)
      transpose_go(rest, edges, (pos + 1n : Nat), U32.or(acc, U32.shln(edge, dest)))

def cut_size(fuel: Nat, +edges: U32, +side: U32, +pos: Nat, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +u = (pos / 4n : Nat)
      +v = (pos % 4n : Nat)
      +src = U32.and(U32.shrn(side, u), 1)
      +dst = U32.and(U32.shrn(side, v), 1)
      +edge = U32.and(U32.shrn(edges, pos), 1)
      +cross = U32.and(U32.and(src, U32.xor(dst, 1)), edge)
      cut_size(rest, edges, side, (pos + 1n : Nat), (acc + cross : U32))

def cut_side(side: U32, best_side: U32, better: Bool) -> U32:
  match better:
    case True{}: side
    case False{}: best_side

def cut_go(fuel: Nat, +edges: U32, +side: U32, +best_size: U32, best_side: U32) -> GraphResult:
  match fuel:
    case 0n: MinCut{best_size, best_side}
    case 1n+rest:
      +size = cut_size(16n, edges, side, 0n, 0)
      cut_go(rest, edges, (side + 1 : U32), U32.min(size, best_size), cut_side(side, best_side, U32.is_lt(size, best_size)))

def min_cut_checked(n: Nat, edges: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: cut_go((Nat.pow(2n, n) - 2n : Nat), edges, 1, 4294967295, 0)

def min_cut(+n: Nat, +edges: U32) -> GraphResult:
  min_cut_checked(n, edges, Bool.and(valid(n, edges), Bool.and(Nat.is_ge(n, 2n), U32.is_eq(edges, transpose_go(16n, edges, 0n, 0)))))

# Enumerate all directed graphs with loops on <=3 vertices, quotient by relabeling.
def expand_compact(fuel: Nat, +n: Nat, +code: U32, +pos: Nat, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest:
      +row = (pos / n : Nat)
      +col = (pos % n : Nat)
      +bit = U32.and(U32.shrn(code, pos), 1)
      expand_compact(rest, n, code, (pos + 1n : Nat), U32.or(acc, U32.shln(bit, ((4n * row : Nat) + col : Nat))))

def canonical_match(edges: U32, key: GraphResult) -> Bool:
  match key:
    case GraphKey{nodes, actual}: U32.is_eq(edges, actual)
    case _: False{}

def reduced_go(fuel: Nat, +n: Nat, +code: U32, count: U32) -> U32:
  match fuel:
    case 0n: count
    case 1n+rest:
      +edges = expand_compact((n * n : Nat), n, code, 0n, 0)
      +add = Bool.to_u32(canonical_match(edges, canonical(n, edges)))
      reduced_go(rest, n, (code + 1 : U32), (count + add : U32))

def reduced_checked(+n: Nat, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: ReducedCount{reduced_go(Nat.pow(2n, (n * n : Nat)), n, 0, 0)}

def reduced_count(+n: Nat) -> GraphResult:
  reduced_checked(n, Nat.is_le(n, 3n))

def add_edge_checked(n: Nat, edges: U32, u: U32, v: U32, ok: Bool) -> GraphResult:
  match ok:
    case False{}: GraphInvalid{}
    case True{}: GraphKey{n, U32.or(edges, U32.shln(1, U32.to_nat(((u * 4 : U32) + v : U32))))}

def add_edge(+n: Nat, +edges: U32, +u: U32, +v: U32) -> GraphResult:
  add_edge_checked(n, edges, u, v, Bool.and(valid(n, edges), Bool.and(U32.is_lt(u, U32.from_nat(n)), U32.is_lt(v, U32.from_nat(n)))))

def edge_between(edges: U32, u: U32, v: U32) -> Bool:
  U32.is_ne(U32.and(U32.shrn(edges, U32.to_nat(((u * 4 : U32) + v : U32))), 1), 0)

def path_matches(+edges: U32, +start: U32, +goal: U32, +code: U32, length: U32) -> Bool:
  match length:
    case 0: U32.is_eq(start, goal)
    case 1: Bool.and(edge_between(edges, start, mapped(code, 0n)), U32.is_eq(mapped(code, 0n), goal))
    case 2: Bool.and(Bool.and(edge_between(edges, start, mapped(code, 0n)), edge_between(edges, mapped(code, 0n), mapped(code, 1n))), U32.is_eq(mapped(code, 1n), goal))
    case 3: Bool.and(Bool.and(edge_between(edges, start, mapped(code, 0n)), Bool.and(edge_between(edges, mapped(code, 0n), mapped(code, 1n)), edge_between(edges, mapped(code, 1n), mapped(code, 2n)))), U32.is_eq(mapped(code, 2n), goal))
    case _: False{}

def path_go(fuel: Nat, +edges: U32, +start: U32, +goal: U32, +length: U32, +code: U32, valid_path: Bool) -> GraphResult:
  match fuel valid_path:
    case _ True{}:
      +bits = U32.or(start, U32.shln(code, 2n))
      +mask = U32.not(U32.shln(4294967295, (2n * U32.to_nat((length + 1 : U32)) : Nat)))
      Path{length, U32.and(bits, mask)}
    case 0n False{}: GraphInvalid{}
    case 1n+rest False{}:
      +next = (code + 1 : U32)
      path_go(rest, edges, start, goal, length, next, path_matches(edges, start, goal, next, length))

def path_from_distance(+edges: U32, +start: U32, +goal: U32, d: GraphResult) -> GraphResult:
  match d:
    case Distance{+length}: path_go(63n, edges, start, goal, length, 0, path_matches(edges, start, goal, 0, length))
    case Unreachable{}: Unreachable{}
    case _: GraphInvalid{}

def shortest_path(n: Nat, +edges: U32, +start: U32, +goal: U32) -> GraphResult:
  path_from_distance(edges, start, goal, shortest(n, edges, start, goal))
