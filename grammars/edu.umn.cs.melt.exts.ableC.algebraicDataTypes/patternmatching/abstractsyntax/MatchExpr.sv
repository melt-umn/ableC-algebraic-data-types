grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinees::Exprs  clauses::ExprClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    parens(nestlines(2, clauses.pp)) ]);
  
  -- Compute defs for clauses env
  local initialTransform::Stmt = scrutinees.transform;
  initialTransform.env = openScopeEnv(top.env);
  initialTransform.returnType = nothing();
  initialTransform.breakValid = false;
  initialTransform.continueValid = false;
  
  scrutinees.argumentPosition = 0;
  clauses.env = addEnv(initialTransform.defs, initialTransform.env);
  clauses.matchLocation = top.location;
  clauses.expectedTypes = scrutinees.typereps;
  clauses.transformIn = scrutinees.scrutineeRefs;
  clauses.endLabelName = s"_end_${toString(genInt())}";
  
  -- Workaround since clauses lack defs from _match_result type expr in env
  local resultDecl::Decl =
    ableC_Decl {
      $directTypeExpr{clauses.typerep} _match_result;
    };
  resultDecl.env = addEnv(clauses.defs, clauses.env);
  resultDecl.isTopLevel = false;
  resultDecl.returnType = nothing();
  resultDecl.breakValid = false;
  resultDecl.continueValid = false;
  
  local localErrors::[Message] =
    clauses.errors ++ scrutinees.errors ++
    if null(lookupValue("abort", top.env))
    then [err(top.location, "Pattern match requires definition of abort (include <stdlib.h>?)")]
    else if null(lookupValue("fprintf", top.env))
    then [err(top.location, "Pattern match requires definition of fprintf (include <stdio.h>?)")]
    else if null(lookupValue("stderr", top.env))
    then [err(top.location, "Pattern match requires definition of stderr (include <stdio.h>?)")]
    else [];
  
  local fwrd::Expr =
    ableC_Expr {
      ({$Decl{decDecl(resultDecl)}
        $Stmt{decStmt(initialTransform)}
        $Stmt{clauses.transform}
        fprintf(stderr, $stringLiteralExpr{s"Pattern match failure at ${top.location.unparse}\n"});
        abort();
        $name{clauses.endLabelName}: ;
        _match_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
