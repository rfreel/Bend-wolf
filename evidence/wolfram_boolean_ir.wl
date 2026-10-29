Clear[a,b,emit];
f=(a&&b)||(a&&!b);
m=BooleanMinimize[f];
emit[e_] := Which[
  e===True,<|"op"->"true"|>,
  e===False,<|"op"->"false"|>,
  Head[e]===Symbol&&MemberQ[{a,b},e],<|"op"->"var","name"->SymbolName[e]|>,
  Head[e]===Not,<|"op"->"not","arg"->emit[e[[1]]]|>,
  Head[e]===And||Head[e]===Or,
    With[{tag=If[Head[e]===And,"and","or"],xs=List@@e},
      Fold[Function[{acc,cur},<|"op"->tag,"left"->acc,"right"->emit[cur]|>],emit[First[xs]],Rest[xs]]],
  True,<|"error"->ToString[e,InputForm]|>];
ExportString[<|"schema"->"bend-boolean-ir/v1","variables"->{"a","b"},
  "specification"->emit[f],"candidate"->emit[m],
  "provenance"-><|"engine"->"Wolfram Language","version"->$Version,"operation"->"BooleanMinimize"|>|>,"RawJSON","Compact"->True]
