grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinees::Exprs  clauses::ExprClauses
{
  propagate substituted;
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    parens(nestlines(2, clauses.pp)) ]);
  
  -- Compute defs for clauses env
  local initialTransform::Stmt = scrutinees.transform;
  initialTransform.env = openScopeEnv(top.env);
  initialTransform.returnType = nothing();
  
  scrutinees.argumentPosition = 0;
  clauses.env = addEnv(initialTransform.defs, initialTransform.env);
  clauses.matchLocation = top.location;
  clauses.expectedTypes = scrutinees.typereps;
  clauses.transformIn = scrutinees.scrutineeRefs;
  clauses.endLabelName = s"_end_${toString(genInt())}";
  
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
      ({$BaseTypeExpr{completedTypeExpr(clauses.typerep)} _match_result;
        $Stmt{decStmt(initialTransform)}
        $Stmt{clauses.transform}
        fprintf(stderr, $stringLiteralExpr{s"Pattern match failure at ${top.location.unparse}\n"});
        exit(1);
        $name{clauses.endLabelName}: ;
        _match_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
