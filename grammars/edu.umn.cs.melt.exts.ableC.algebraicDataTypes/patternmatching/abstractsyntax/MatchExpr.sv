grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinees::Exprs  clauses::ExprClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    parens(nestlines(2, clauses.pp)) ]);

  scrutinees.argumentPosition = 0;
  clauses.expectedTypes = scrutinees.typereps;
  clauses.scrutineesIn = scrutinees.scrutineeRefs;
  
  local localErrors::[Message] = clauses.errors ++ scrutinees.errors;
  local fwrd::Expr =
    ableC_Expr {
      ({$directTypeExpr{clauses.typerep} _result;
        $Stmt{scrutinees.transform}
        $Stmt{clauses.transform}
        _result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
