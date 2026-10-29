Clear[a,b,c,x,y,z];
vars={a,b,c};
fs={(a||b||c)&&(!a||!b)&&(!b||!c), Xor[a,b], (a&&b)||(a&&!b), !(a&&b)||c, (a||b)&&(!a||c), Equivalent[a,b], Xor[a,b,c], (a&&b)||(b&&c)||(a&&c)};
truths=Map[Function[f,Table[Boole[f/.Thread[vars->Table[BitGet[m,k]==1,{k,0,2}]]],{m,0,7}]],fs];
g=Graph[{1->2,1->3,2->3},EdgeCapacity->{2,2,2},EdgeCost->{3,1,2}];
ExportString[<|"version"->$Version,"truths"->truths,"polyCoefficients"->CoefficientList[Expand[(x+1)^3],x],"polyAt0to5"->Table[Mod[(x+1)^3,2^32],{x,0,5}],"fibonacciRecurrence"->FindLinearRecurrence[{0,1,1,2,3,5,8,13}],"bayesNumerator"->Numerator[((1/3)*(4/5))/((1/3)*(4/5)+(2/3)*(1/10))],"bayesDenominator"->Denominator[((1/3)*(4/5))/((1/3)*(4/5)+(2/3)*(1/10))],"shortest"->GraphDistance[Graph[{1->2,2->3}],1,3],"triangleCut"->First[FindMinimumCut[Graph[{1<->2,2<->3,3<->1}]]],"flowCost"->FindMinimumCostFlow[g,1,3,3],"flowMatrix"->Normal[FindMinimumCostFlow[g,1,3,3,"FlowMatrix"]],"unlabeledDirectedWithLoops"->{2^0,2^1,(2^4+2^2)/2,(2^9+3*2^5+2*2^3)/6}|>,"RawJSON","Compact"->True]
