(* The k-th permutation value is encoded in its k-th base-4 digit. *)
ExportString[Table[(Function[p,Sum[(p[[k]]-1)*4^(k-1),{k,Length[p]}]] /@ Permutations[Range[n]]),{n,0,4}],"RawJSON","Compact"->True]
