enc[p_]:=Sum[(p[[k]]-1)*4^(k-1),{k,Length[p]}];
groups[p_]:=With[{pairs=Flatten[Table[{4*u+v,4*(p[[u+1]]-1)+(p[[v+1]]-1)},{u,0,2},{v,0,2}],1]},Map[Function[group,{group[[1,2]]-group[[1,1]],Total[2^group[[All,1]]]}],GatherBy[pairs,#[[2]]-#[[1]]&]]];
ExportString[Map[Function[p,<|"code"->enc[p],"groups"->groups[p]|>],Permutations[Range[3]]],"RawJSON","Compact"->True]
