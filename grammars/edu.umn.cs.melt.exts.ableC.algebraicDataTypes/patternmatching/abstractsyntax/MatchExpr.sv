grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinees::ScrutineeExprs  clauses::ExprClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    parens(nestlines(2, clauses.pp)) ]);
  attachNote extensionGenerated("ableC-algebraic-data-types");

  scrutinees.argumentPosition = 0;
  clauses.expectedTypes = scrutinees.typereps;
  clauses.transformIn = scrutinees.scrutineeRefs;
  clauses.endLabelName = s"_end_${toString(genInt())}";
  clauses.initialEnv = top.env;
  
  local localErrors::[Message] =
    clauses.errors ++ scrutinees.errors ++
    if null(lookupValue("abort", top.env))
    then [errFromOrigin(top, "Pattern match requires definition of abort (include <stdlib.h>?)")]
    else if null(lookupValue("fprintf", top.env))
    then [errFromOrigin(top, "Pattern match requires definition of fprintf (include <stdio.h>?)")]
    else if null(lookupValue("stderr", top.env))
    then [errFromOrigin(top, "Pattern match requires definition of stderr (include <stdio.h>?)")]
    else [];
  
  forward fwrd =
    ableC_Expr {
      ({$Decl{preDecl(clauses.typerep, name("_match_result"))}
        $Stmt{@scrutinees.transform}
        $Stmt{@clauses.transform}
        fprintf(stderr, $stringLiteralExpr{s"Pattern match failure at ${getParsedOriginLocationOrFallback(top).unparse}\n"});
        abort();
        $name{clauses.endLabelName}: ;
        _match_result;})
    };
  
  forwards to if !null(localErrors) then errorExpr(localErrors) else @fwrd;
}
