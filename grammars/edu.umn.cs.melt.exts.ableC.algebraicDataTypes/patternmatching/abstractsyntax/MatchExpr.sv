grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinees::Exprs  clauses::ExprClauses
{
  propagate substituted;
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    parens(nestlines(2, clauses.pp)) ]);
  
  scrutinees.argumentPosition = 0;
  clauses.matchLocation = top.location;
  clauses.expectedTypes = scrutinees.typereps;
  clauses.scrutineesIn = scrutinees.scrutineeRefs;
  clauses.transformIn =
    ableC_Stmt {
      fprintf(stderr, $stringLiteralExpr{s"Pattern match failure at ${top.location.unparse}\n"});
      exit(1);
    };
  
  local localErrors::[Message] =
    clauses.errors ++ scrutinees.errors ++
    if null(lookupValue("exit", top.env))
    then [err(top.location, "Pattern match requires definition of exit (include <stdlib.h>?)")]
    else if null(lookupValue("fprintf", top.env))
    then [err(top.location, "Pattern match requires definition of fprintf (include <stdio.h>?)")]
    else if null(lookupValue("stderr", top.env))
    then [err(top.location, "Pattern match requires definition of stderr (include <stdio.h>?)")]
    else [];
  local fwrd::Expr =
    ableC_Expr {
      ({$directTypeExpr{clauses.typerep} _match_result;
        $Stmt{scrutinees.transform}
        $Stmt{clauses.transform}
        _match_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
