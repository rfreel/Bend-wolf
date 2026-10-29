import Base

type Point is Data:
  Point{cost: U32, risk: U32}

type Item is Data:
  Item{cost: Nat, value: Nat}

type FlowEdge is Data:
  FlowEdge{from: U32, to: U32, capacity: U32, cost: Nat}

type FlowEdges is Data:
  FlowEdges{a: FlowEdge, b: FlowEdge, c: FlowEdge, d: FlowEdge}

type OptimizeResult is Data:
  OptimizeInvalid{}
  Frontier{mask: U32}
  Allocation{mask: U32, cost: Nat, value: Nat}
  Flow{via: Nat, direct: Nat, cost: Nat}
  NoFlow{}
  Flow4{flows: U32, cost: Nat}

def dominates(a: Point, b: Point) -> Bool:
  match a b:
    case Point{+ac, +ar} Point{+bc, +br}:
      Bool.and(Bool.and(U32.is_le(ac, bc), U32.is_le(ar, br)), Bool.or(U32.is_lt(ac, bc), U32.is_lt(ar, br)))

def visible(+p: Point, a: Point, b: Point, c: Point) -> Bool:
  Bool.not(Bool.or(dominates(a, p), Bool.or(dominates(b, p), dominates(c, p))))

def pareto4(+a: Point, +b: Point, +c: Point, +d: Point) -> OptimizeResult:
  +v0 = Bool.to_u32(visible(a, b, c, d))
  +v1 = U32.shln(Bool.to_u32(visible(b, a, c, d)), 1n)
  +v2 = U32.shln(Bool.to_u32(visible(c, a, b, d)), 2n)
  +v3 = U32.shln(Bool.to_u32(visible(d, a, b, c)), 3n)
  Frontier{U32.or(U32.or(v0, v1), U32.or(v2, v3))}

def item_ok(item: Item) -> Bool:
  match item:
    case Item{cost, value}: Bool.and(Nat.is_le(cost, Nat.pow(10n, 6n)), Nat.is_le(value, Nat.pow(10n, 6n)))

def item_cost(item: Item, chosen: Bool) -> Nat:
  match item chosen:
    case Item{cost, value} True{}: cost
    case _ False{}: 0n

def item_value(item: Item, chosen: Bool) -> Nat:
  match item chosen:
    case Item{cost, value} True{}: value
    case _ False{}: 0n

def selected(mask: U32, bit: U32) -> Bool:
  U32.is_ne(U32.and(mask, bit), 0)

def cost4(a: Item, b: Item, c: Item, d: Item, +mask: U32) -> Nat:
  ((item_cost(a, selected(mask, 1)) + item_cost(b, selected(mask, 2)) : Nat) + (item_cost(c, selected(mask, 4)) + item_cost(d, selected(mask, 8)) : Nat) : Nat)

def value4(a: Item, b: Item, c: Item, d: Item, +mask: U32) -> Nat:
  ((item_value(a, selected(mask, 1)) + item_value(b, selected(mask, 2)) : Nat) + (item_value(c, selected(mask, 4)) + item_value(d, selected(mask, 8)) : Nat) : Nat)

def choose_u32(a: U32, b: U32, choose_a: Bool) -> U32:
  match choose_a:
    case True{}: a
    case False{}: b

def choose_nat(a: Nat, b: Nat, choose_a: Bool) -> Nat:
  match choose_a:
    case True{}: a
    case False{}: b

def allocation_go(fuel: Nat, +budget: Nat, +a: Item, +b: Item, +c: Item, +d: Item, +mask: U32, +best_mask: U32, +best_cost: Nat, +best_value: Nat) -> OptimizeResult:
  match fuel:
    case 0n: Allocation{best_mask, best_cost, best_value}
    case 1n+rest:
      +cost = cost4(a, b, c, d, mask)
      +value = value4(a, b, c, d, mask)
      +better = Bool.and(Nat.is_le(cost, budget), Bool.or(Nat.is_gt(value, best_value), Bool.and(Nat.is_eq(value, best_value), Nat.is_lt(cost, best_cost))))
      allocation_go(rest, budget, a, b, c, d, (mask + 1 : U32), choose_u32(mask, best_mask, better), choose_nat(cost, best_cost, better), choose_nat(value, best_value, better))

def allocation_checked(budget: Nat, a: Item, b: Item, c: Item, d: Item, ok: Bool) -> OptimizeResult:
  match ok:
    case False{}: OptimizeInvalid{}
    case True{}: allocation_go(16n, budget, a, b, c, d, 0, 0, 0n, 0n)

def allocate4(+budget: Nat, +a: Item, +b: Item, +c: Item, +d: Item) -> OptimizeResult:
  allocation_checked(budget, a, b, c, d, Bool.and(Nat.is_le(budget, (4n * Nat.pow(10n, 6n) : Nat)), Bool.and(Bool.and(item_ok(a), item_ok(b)), Bool.and(item_ok(c), item_ok(d)))))

# Three-edge network 0->1->2 and 0->2. Integral, nonnegative flow and costs.
def flow_result(via: Nat, direct: Nat, cost: Nat, found: Bool) -> OptimizeResult:
  match found:
    case False{}: NoFlow{}
    case True{}: Flow{via, direct, cost}

def flow_go(fuel: Nat, +demand: Nat, +cap01: Nat, +cap02: Nat, +cap12: Nat, +cost01: Nat, +cost02: Nat, +cost12: Nat, +via: Nat, +best_via: Nat, +best_direct: Nat, +best_cost: Nat, +found: Bool) -> OptimizeResult:
  match fuel:
    case 0n: flow_result(best_via, best_direct, best_cost, found)
    case 1n+rest:
      +direct = (demand - via : Nat)
      +cost = (((via * cost01 : Nat) + (direct * cost02 : Nat) : Nat) + (via * cost12 : Nat) : Nat)
      +feasible = Bool.and(Nat.is_le(via, cap01), Bool.and(Nat.is_le(via, cap12), Nat.is_le(direct, cap02)))
      +better = Bool.and(feasible, Nat.is_lt(cost, best_cost))
      flow_go(rest, demand, cap01, cap02, cap12, cost01, cost02, cost12, (via + 1n : Nat), choose_nat(via, best_via, better), choose_nat(direct, best_direct, better), choose_nat(cost, best_cost, better), Bool.or(found, better))

def flow_checked(+demand: Nat, cap01: Nat, cap02: Nat, cap12: Nat, cost01: Nat, cost02: Nat, cost12: Nat, ok: Bool) -> OptimizeResult:
  match ok:
    case False{}: OptimizeInvalid{}
    case True{}: flow_go((demand + 1n : Nat), demand, cap01, cap02, cap12, cost01, cost02, cost12, 0n, 0n, 0n, (Nat.pow(10n, 6n) + 1n : Nat), False{})

def min_cost_flow(+demand: Nat, +cap01: Nat, +cap02: Nat, +cap12: Nat, +cost01: Nat, +cost02: Nat, +cost12: Nat) -> OptimizeResult:
  +capacities = Bool.and(Nat.is_le(demand, 100n), Bool.and(Nat.is_le(cap01, 100n), Bool.and(Nat.is_le(cap02, 100n), Nat.is_le(cap12, 100n))))
  +costs = Bool.and(Nat.is_le(cost01, Nat.pow(10n, 3n)), Bool.and(Nat.is_le(cost02, Nat.pow(10n, 3n)), Nat.is_le(cost12, Nat.pow(10n, 3n))))
  flow_checked(demand, cap01, cap02, cap12, cost01, cost02, cost12, Bool.and(capacities, costs))

# General integral four-edge network; each edge has capacity <=3 and cost <=1000.
def edge_ok(+n: Nat, edge: FlowEdge) -> Bool:
  match edge:
    case FlowEdge{from, to, capacity, cost}:
      Bool.and(U32.is_lt(from, U32.from_nat(n)), Bool.and(U32.is_lt(to, U32.from_nat(n)), Bool.and(U32.is_le(capacity, 3), Nat.is_le(cost, Nat.pow(10n, 3n)))))

def edges_ok(+n: Nat, edges: FlowEdges) -> Bool:
  match edges:
    case FlowEdges{a, b, c, d}: Bool.and(Bool.and(edge_ok(n, a), edge_ok(n, b)), Bool.and(edge_ok(n, c), edge_ok(n, d)))

def flow_digit(code: U32, index: Nat) -> U32:
  U32.and(U32.shrn(code, (2n * index : Nat)), 3)

def capacity_ok(edge: FlowEdge, value: U32) -> Bool:
  match edge:
    case FlowEdge{from, to, capacity, cost}: U32.is_le(value, capacity)

def flow_capacities(edges: FlowEdges, +code: U32) -> Bool:
  match edges:
    case FlowEdges{a, b, c, d}:
      Bool.and(Bool.and(capacity_ok(a, flow_digit(code, 0n)), capacity_ok(b, flow_digit(code, 1n))), Bool.and(capacity_ok(c, flow_digit(code, 2n)), capacity_ok(d, flow_digit(code, 3n))))

def edge_in(node: U32, edge: FlowEdge, amount: U32) -> Nat:
  match edge:
    case FlowEdge{from, to, capacity, cost}: U32.to_nat((Bool.to_u32(U32.is_eq(node, to)) * amount : U32))

def edge_out(node: U32, edge: FlowEdge, amount: U32) -> Nat:
  match edge:
    case FlowEdge{from, to, capacity, cost}: U32.to_nat((Bool.to_u32(U32.is_eq(node, from)) * amount : U32))

def incoming(+node: U32, edges: FlowEdges, +code: U32) -> Nat:
  match edges:
    case FlowEdges{a, b, c, d}:
      ((edge_in(node, a, flow_digit(code, 0n)) + edge_in(node, b, flow_digit(code, 1n)) : Nat) + (edge_in(node, c, flow_digit(code, 2n)) + edge_in(node, d, flow_digit(code, 3n)) : Nat) : Nat)

def outgoing(+node: U32, edges: FlowEdges, +code: U32) -> Nat:
  match edges:
    case FlowEdges{a, b, c, d}:
      ((edge_out(node, a, flow_digit(code, 0n)) + edge_out(node, b, flow_digit(code, 1n)) : Nat) + (edge_out(node, c, flow_digit(code, 2n)) + edge_out(node, d, flow_digit(code, 3n)) : Nat) : Nat)

def balance(inflow: Nat, outflow: Nat, demand: Nat, source: Bool, sink: Bool) -> Bool:
  match source sink:
    case True{} False{}: Nat.is_eq(outflow, (inflow + demand : Nat))
    case False{} True{}: Nat.is_eq(inflow, (outflow + demand : Nat))
    case False{} False{}: Nat.is_eq(inflow, outflow)
    case True{} True{}: False{}

def balances(fuel: Nat, +edges: FlowEdges, +code: U32, +source: U32, +sink: U32, +demand: Nat, +vertex: U32) -> Bool:
  match fuel:
    case 0n: True{}
    case 1n+rest:
      +ok = balance(incoming(vertex, edges, code), outgoing(vertex, edges, code), demand, U32.is_eq(vertex, source), U32.is_eq(vertex, sink))
      Bool.and(ok, balances(rest, edges, code, source, sink, demand, (vertex + 1 : U32)))

def edge_cost(edge: FlowEdge, amount: U32) -> Nat:
  match edge:
    case FlowEdge{from, to, capacity, cost}: (cost * U32.to_nat(amount) : Nat)

def flow_cost(edges: FlowEdges, +code: U32) -> Nat:
  match edges:
    case FlowEdges{a, b, c, d}:
      ((edge_cost(a, flow_digit(code, 0n)) + edge_cost(b, flow_digit(code, 1n)) : Nat) + (edge_cost(c, flow_digit(code, 2n)) + edge_cost(d, flow_digit(code, 3n)) : Nat) : Nat)

def flow4_result(flows: U32, cost: Nat, found: Bool) -> OptimizeResult:
  match found:
    case True{}: Flow4{flows, cost}
    case False{}: NoFlow{}

def flow4_go(fuel: Nat, +n: Nat, +edges: FlowEdges, +source: U32, +sink: U32, +demand: Nat, +code: U32, +best_flows: U32, +best_cost: Nat, +found: Bool) -> OptimizeResult:
  match fuel:
    case 0n: flow4_result(best_flows, best_cost, found)
    case 1n+rest:
      +cost = flow_cost(edges, code)
      +valid = Bool.and(flow_capacities(edges, code), balances(n, edges, code, source, sink, demand, 0))
      +better = Bool.and(valid, Nat.is_lt(cost, best_cost))
      flow4_go(rest, n, edges, source, sink, demand, (code + 1 : U32), choose_u32(code, best_flows, better), choose_nat(cost, best_cost, better), Bool.or(found, better))

def flow4_checked(n: Nat, edges: FlowEdges, source: U32, sink: U32, demand: Nat, valid: Bool) -> OptimizeResult:
  match valid:
    case False{}: OptimizeInvalid{}
    case True{}: flow4_go(256n, n, edges, source, sink, demand, 0, 0, ((12n * Nat.pow(10n, 3n) : Nat) + 1n : Nat), False{})

def min_cost_flow4(+n: Nat, +edges: FlowEdges, +source: U32, +sink: U32, +demand: Nat) -> OptimizeResult:
  +bounds = Bool.and(Bool.and(Nat.is_ge(n, 2n), Nat.is_le(n, 4n)), Bool.and(U32.is_lt(source, U32.from_nat(n)), Bool.and(U32.is_lt(sink, U32.from_nat(n)), U32.is_ne(source, sink))))
  flow4_checked(n, edges, source, sink, demand, Bool.and(bounds, Bool.and(Nat.is_le(demand, 12n), edges_ok(n, edges))))
