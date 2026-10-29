import Base
import ./Graph.bend as G

# Count the 104 equivalence classes ten thousand times; output keeps every run live.
def count(result: G.GraphResult) -> U32:
  match result:
    case G.ReducedCount{count}: count
    case _: 0

def repeats(fuel: Nat, acc: U32) -> U32:
  match fuel:
    case 0n: acc
    case 1n+rest: repeats(rest, (acc + count(G.reduced_count(3n)) : U32))

def main() -> U32:
  repeats(10000n, 0)
