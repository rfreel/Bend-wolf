# Secondary-kernel numeric-literal diagnostic

On the recorded Bend 2.0.39/Lean 4.34.0 setup, a minimal function `Nat.is_le(n, 64n)` passed both the ordinary checker and `--verdict`. The same function with `1000n` or `1000000n` passed the ordinary checker but `--verdict` failed with `Error: the machine stack overflowed (a deep recursion, or a literal too large to expand)`.

The equivalent bound `Nat.is_le(n, Nat.pow(10n, 6n))` passed `--verdict`. Replacing large literal bounds with expressions using small literals preserved the intended numerical bounds. Dynamics, Inference and Optimize subsequently passed `--verdict`, as did every other core module. Boundary tests check the affected limits.

This isolates an observed interaction with large literals in the secondary-check path. It does not establish the exact internal cause, and a stack overflow is neither a proof that the program is false nor a successful proof.
