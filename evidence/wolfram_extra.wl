Clear[a,b,c,x]; f=(a||b||c)&&(!a||!b)&&(!b||!c);
g=Graph[{1->2,2->3}]; h=Graph[{3->1,1->2}];
m={{0,1,1},{0,0,1},{0,0,1}};
v1={1,0,0}.MatrixPower[m,2];
ExportString[<|
"satCount"->SatisfiabilityCount[f,{a,b,c}],
"quantifiedExists"->ToString[BooleanMinimize[((a&&b)/.a->False)||((a&&b)/.a->True)],InputForm],
"quantifiedForall"->ToString[BooleanMinimize[((a&&b)/.a->False)&&((a&&b)/.a->True)],InputForm],
"coreSatisfiable"->Map[SatisfiableQ[#,{a,b}]&,{a&&!a,a,!a,b}],
"isomorphicPaths"->IsomorphicGraphQ[g,h],
"cycleCount"->Length[FindCycle[Graph[{1->2,2->3,3->1}]]],
"boundedRoots"->Select[Range[0,10],Mod[#^2,2^32]==9&],
"walksLength2To2"->v1[[3]],
"orbit"->NestList[({1,2,1}[[#+1]])&,0,5],
"experimentAccuracy"->{4/5,3/5}//N,
"causalNumerators"->{1,3},
"causalDenominator"->4,
"allocationBest"->Max[Select[Table[{3 BitGet[i,0]+2 BitGet[i,1]+4 BitGet[i,2]+BitGet[i,3],6 BitGet[i,0]+5 BitGet[i,1]+6 BitGet[i,2]},{i,0,15}],First[#]<=5&][[All,2]]]
|>,"RawJSON","Compact"->True]
