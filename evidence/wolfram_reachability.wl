perms=Permutations[Range[0,2]];
relabel[x_,p_]:=Sum[BitGet[x,3*u+v]*2^(3*p[[u+1]]+p[[v+1]]),{u,0,2},{v,0,2}];
canon[x_]:=Min[relabel[x,#]& /@ perms];
ExportString[Table[Length[Union[canon /@ Select[Range[0,511], BitGet[#,1]==1 && DigitCount[#,2,1]-1<=k&]]],{k,0,3}],"RawJSON","Compact"->True]
