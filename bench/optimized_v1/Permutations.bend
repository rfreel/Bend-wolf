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
