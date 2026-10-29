import Base

# Generated from a Wolfram result; generator independently verifies every permutation.
def get0(index: U32) -> U32:
  match index:
    case 0: 0
    case _: 0

def get1(index: U32) -> U32:
  match index:
    case 0: 0
    case _: 0

def get2(index: U32) -> U32:
  match index:
    case 0: 4
    case 1: 1
    case _: 0

def get3(index: U32) -> U32:
  match index:
    case 0: 36
    case 1: 24
    case 2: 33
    case 3: 9
    case 4: 18
    case 5: 6
    case _: 0

def get4(index: U32) -> U32:
  match index:
    case 0: 228
    case 1: 180
    case 2: 216
    case 3: 120
    case 4: 156
    case 5: 108
    case 6: 225
    case 7: 177
    case 8: 201
    case 9: 57
    case 10: 141
    case 11: 45
    case 12: 210
    case 13: 114
    case 14: 198
    case 15: 54
    case 16: 78
    case 17: 30
    case 18: 147
    case 19: 99
    case 20: 135
    case 21: 39
    case 22: 75
    case 23: 27
    case _: 0

def get(n: Nat, index: U32) -> U32:
  match n:
    case 0n: get0(index)
    case 1n: get1(index)
    case 2n: get2(index)
    case 3n: get3(index)
    case 4n: get4(index)
    case _: 0

def count(n: Nat) -> Nat:
  match n:
    case 0n: 1n
    case 1n: 1n
    case 2n: 2n
    case 3n: 6n
    case 4n: 24n
    case _: 0n

def relabel3_0(+edges: U32) -> U32:
  U32.and(edges, 1911)

def relabel3_1(+edges: U32) -> U32:
  U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.and(edges, 1), U32.shln(U32.and(edges, 2), 1n)), U32.shrn(U32.and(edges, 4), 1n)), U32.shln(U32.and(edges, 16), 4n)), U32.shln(U32.and(edges, 32), 5n)), U32.shln(U32.and(edges, 64), 3n)), U32.shrn(U32.and(edges, 256), 4n)), U32.shrn(U32.and(edges, 512), 3n)), U32.shrn(U32.and(edges, 1024), 5n))

def relabel3_2(+edges: U32) -> U32:
  U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.shln(U32.and(edges, 1), 5n), U32.shln(U32.and(edges, 2), 3n)), U32.shln(U32.and(edges, 4), 4n)), U32.shrn(U32.and(edges, 16), 3n)), U32.shrn(U32.and(edges, 32), 5n)), U32.shrn(U32.and(edges, 64), 4n)), U32.shln(U32.and(edges, 256), 1n)), U32.shrn(U32.and(edges, 512), 1n)), U32.and(edges, 1024))

def relabel3_3(+edges: U32) -> U32:
  U32.or(U32.or(U32.or(U32.shln(U32.and(edges, 51), 5n), U32.shln(U32.and(edges, 68), 2n)), U32.shrn(U32.and(edges, 768), 7n)), U32.shrn(U32.and(edges, 1024), 10n))

def relabel3_4(+edges: U32) -> U32:
  U32.or(U32.or(U32.or(U32.shln(U32.and(edges, 1), 10n), U32.shln(U32.and(edges, 6), 7n)), U32.shrn(U32.and(edges, 272), 2n)), U32.shrn(U32.and(edges, 1632), 5n))

def relabel3_5(+edges: U32) -> U32:
  U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.or(U32.shln(U32.and(edges, 1), 10n), U32.shln(U32.and(edges, 2), 8n)), U32.shln(U32.and(edges, 4), 6n)), U32.shln(U32.and(edges, 16), 2n)), U32.and(edges, 32)), U32.shrn(U32.and(edges, 64), 2n)), U32.shrn(U32.and(edges, 256), 6n)), U32.shrn(U32.and(edges, 512), 8n)), U32.shrn(U32.and(edges, 1024), 10n))

def canonical3(+edges: U32) -> U32:
  U32.min(U32.min(U32.min(U32.min(U32.min(relabel3_0(edges), relabel3_1(edges)), relabel3_2(edges)), relabel3_3(edges)), relabel3_4(edges)), relabel3_5(edges))
