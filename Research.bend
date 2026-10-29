import Base
import ./Logic.bend as L
import ./Rewrite.bend as R
import ./Proof.bend as P
import ./Synthesis.bend as S
import ./Graph.bend as G

type CacheSlot is Data:
  EmptySlot{}
  CacheEntry{domain: Nat, bits: U32, context: U32, value: U32}

type CacheSlots is Data:
  CacheSlots{a: CacheSlot, b: CacheSlot, c: CacheSlot, d: CacheSlot}

# Node IDs identify external records; kinds and statuses are caller-defined codes 0..3.
type EvidenceNode is Data:
  EvidenceNode{id: U32, kind: U32, status: U32}

type EvidenceGraph is Data:
  EvidenceGraph{n: Nat, n0: EvidenceNode, n1: EvidenceNode, n2: EvidenceNode, n3: EvidenceNode, supports: U32, contradicts: U32}

type ResearchResult is Data:
  ResearchInvalid{}
  CacheHit{value: U32}
  CacheMiss{}
  Improved{index: U32, cost: Nat}
  NoImprovement{}
  CertifiedImprovement{index: U32, cost: Nat, expr: L.Expr, certificate: P.TruthCertificate}
  EvidenceValid{}
  EvidencePath{length: U32, nodes: U32}
  NoEvidencePath{}
  EvidenceLinked{}
  EvidenceUnlinked{}

def decide_hit(value: U32, fallback: ResearchResult, matches: Bool) -> ResearchResult:
  match matches:
    case True{}: CacheHit{value}
    case False{}: fallback

def slot_lookup(domain: Nat, bits: U32, context: U32, slot: CacheSlot, fallback: ResearchResult) -> ResearchResult:
  match slot:
    case EmptySlot{}: fallback
    case CacheEntry{d, k, c, value}:
      decide_hit(value, fallback, Bool.and(Nat.is_eq(domain, d), Bool.and(U32.is_eq(bits, k), U32.is_eq(context, c))))

def cache_lookup(+domain: Nat, +bits: U32, +context: U32, slots: CacheSlots) -> ResearchResult:
  match slots:
    case CacheSlots{a, b, c, d}:
      slot_lookup(domain, bits, context, a, slot_lookup(domain, bits, context, b, slot_lookup(domain, bits, context, c, slot_lookup(domain, bits, context, d, CacheMiss{}))))

def lookup_key(domain: Nat, context: U32, slots: CacheSlots, key: R.KeyResult) -> ResearchResult:
  match key:
    case R.KeyInvalid{}: ResearchInvalid{}
    case R.TruthKey{bits}: cache_lookup(domain, bits, context, slots)

def lookup(+domain: Nat, expr: L.Expr, context: U32, slots: CacheSlots) -> ResearchResult:
  lookup_key(domain, context, slots, R.truth_table(domain, expr))

def size(expr: L.Expr) -> Nat:
  match expr:
    case L.ETrue{}: 1n
    case L.EFalse{}: 1n
    case L.EVar{id}: 1n
    case L.ENot{inner}: (1n + size(inner) : Nat)
    case L.EAnd{left, right}: ((1n + size(left) : Nat) + size(right) : Nat)
    case L.EOr{left, right}: ((1n + size(left) : Nat) + size(right) : Nat)
    case L.EXor{left, right}: ((1n + size(left) : Nat) + size(right) : Nat)

def accepted(outcome: L.Outcome) -> Bool:
  match outcome:
    case L.Equivalent{}: True{}
    case _: False{}

def choose_cost(a: Nat, b: Nat, yes: Bool) -> Nat:
  match yes:
    case True{}: a
    case False{}: b

def choose_index(a: U32, b: U32, yes: Bool) -> U32:
  match yes:
    case True{}: a
    case False{}: b

def improved_result(index: U32, cost: Nat, found: Bool) -> ResearchResult:
  match found:
    case False{}: NoImprovement{}
    case True{}: Improved{index, cost}

def improve_go(fuel: Nat, +n: Nat, +baseline: L.Expr, +choices: S.Choices, +index: U32, +best_index: U32, +best_cost: Nat, +found: Bool) -> ResearchResult:
  match fuel:
    case 0n: improved_result(best_index, best_cost, found)
    case 1n+rest:
      +candidate = S.pick(choices, index)
      +cost = size(candidate)
      +better = Bool.and(Nat.is_lt(cost, best_cost), accepted(P.check(n, baseline, candidate)))
      improve_go(rest, n, baseline, choices, (index + 1 : U32), choose_index(index, best_index, better), choose_cost(cost, best_cost, better), Bool.or(found, better))

def choices_valid(+n: Nat, choices: S.Choices) -> Bool:
  match choices:
    case S.Choices{a, b, c, d}: Bool.and(Bool.and(L.valid(a, n), L.valid(b, n)), Bool.and(L.valid(c, n), L.valid(d, n)))

def improve_checked(+n: Nat, +baseline: L.Expr, choices: S.Choices, ok: Bool) -> ResearchResult:
  match ok:
    case False{}: ResearchInvalid{}
    case True{}: improve_go(4n, n, baseline, choices, 0, 0, size(baseline), False{})

def improve(+n: Nat, +baseline: L.Expr, +choices: S.Choices) -> ResearchResult:
  improve_checked(n, baseline, choices, Bool.and(Nat.is_le(n, 16n), Bool.and(L.valid(baseline, n), choices_valid(n, choices))))

def node_id(node: EvidenceNode) -> U32:
  match node:
    case EvidenceNode{id, kind, status}: id

def node_valid(node: EvidenceNode) -> Bool:
  match node:
    case EvidenceNode{id, kind, status}: Bool.and(U32.is_le(kind, 3), U32.is_le(status, 3))

def active_node(n: Nat, index: Nat, node: EvidenceNode) -> Bool:
  Bool.or(Nat.is_le(n, index), node_valid(node))

def unique_if_active(n: Nat, last: Nat, a: EvidenceNode, b: EvidenceNode) -> Bool:
  Bool.or(Nat.is_le(n, last), U32.is_ne(node_id(a), node_id(b)))

def validation_result(ok: Bool) -> ResearchResult:
  match ok:
    case True{}: EvidenceValid{}
    case False{}: ResearchInvalid{}

def evidence_validate(graph: EvidenceGraph) -> ResearchResult:
  match graph:
    case EvidenceGraph{+n, +a, +b, +c, +d, +support, +contradict}:
      +graphs = Bool.and(G.valid(n, support), G.valid(n, contradict))
      +nodes = Bool.and(Bool.and(active_node(n, 0n, a), active_node(n, 1n, b)), Bool.and(active_node(n, 2n, c), active_node(n, 3n, d)))
      +pairs = Bool.and(Bool.and(unique_if_active(n, 1n, a, b), unique_if_active(n, 2n, a, c)), Bool.and(unique_if_active(n, 3n, a, d), Bool.and(unique_if_active(n, 2n, b, c), Bool.and(unique_if_active(n, 3n, b, d), unique_if_active(n, 3n, c, d)))))
      validation_result(Bool.and(graphs, Bool.and(nodes, pairs)))

def evidence_path_result(path: G.GraphResult) -> ResearchResult:
  match path:
    case G.Path{length, nodes}: EvidencePath{length, nodes}
    case G.Unreachable{}: NoEvidencePath{}
    case _: ResearchInvalid{}

def support_checked(graph: EvidenceGraph, from: U32, to: U32, valid: ResearchResult) -> ResearchResult:
  match graph valid:
    case EvidenceGraph{n, a, b, c, d, supports, contradicts} EvidenceValid{}: evidence_path_result(G.shortest_path(n, supports, from, to))
    case _ _: ResearchInvalid{}

def support_path(+graph: EvidenceGraph, from: U32, to: U32) -> ResearchResult:
  support_checked(graph, from, to, evidence_validate(graph))

def link_result(yes: Bool) -> ResearchResult:
  match yes:
    case True{}: EvidenceLinked{}
    case False{}: EvidenceUnlinked{}

def contradiction_result(edges: U32, from: U32, to: U32, ok: Bool) -> ResearchResult:
  match ok:
    case False{}: ResearchInvalid{}
    case True{}: link_result(G.edge_between(edges, from, to))

def contradicts_checked(graph: EvidenceGraph, +from: U32, +to: U32, valid: ResearchResult) -> ResearchResult:
  match graph valid:
    case EvidenceGraph{+n, a, b, c, d, supports, contradicts} EvidenceValid{}:
      +bounds = Bool.and(U32.is_lt(from, U32.from_nat(n)), U32.is_lt(to, U32.from_nat(n)))
      contradiction_result(contradicts, from, to, bounds)
    case _ _: ResearchInvalid{}


def contradicts(+graph: EvidenceGraph, from: U32, to: U32) -> ResearchResult:
  contradicts_checked(graph, from, to, evidence_validate(graph))

# Attach and verify an explicit finite truth-table certificate to an improvement.
def certified_decision(index: U32, cost: Nat, expr: L.Expr, certificate: P.TruthCertificate, result: P.CertificateResult) -> ResearchResult:
  match result:
    case P.CertificateAccepted{}: CertifiedImprovement{index, cost, expr, certificate}
    case _: ResearchInvalid{}

def certificate_key(+n: Nat, +before: L.Expr, +after: L.Expr, index: U32, cost: Nat, key: R.KeyResult) -> ResearchResult:
  match key:
    case R.KeyInvalid{}: ResearchInvalid{}
    case R.TruthKey{bits}:
      +certificate = {P.TruthCertificate{n, bits} : P.TruthCertificate}
      certified_decision(index, cost, after, certificate, P.verify_certificate(n, before, after, certificate))

def certified_result(+n: Nat, +before: L.Expr, choices: S.Choices, result: ResearchResult) -> ResearchResult:
  match result:
    case Improved{+index, cost}: certificate_key(n, before, S.pick(choices, index), index, cost, R.truth_table(n, before))
    case NoImprovement{}: NoImprovement{}
    case _: ResearchInvalid{}

def certified_checked(+n: Nat, +before: L.Expr, +choices: S.Choices, ok: Bool) -> ResearchResult:
  match ok:
    case False{}: ResearchInvalid{}
    case True{}: certified_result(n, before, choices, improve(n, before, choices))

def certified_improve(+n: Nat, before: L.Expr, choices: S.Choices) -> ResearchResult:
  certified_checked(n, before, choices, Nat.is_le(n, 5n))
