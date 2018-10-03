grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinee::Expr  clauses::ExprClauses
{
  top.globalDecls := [];
  top.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    parens(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;
  
  local localErrors::[Message] = clauses.errors ++ scrutinee.errors;
  local fwrd::Expr =
    ableC_Expr {
      ({$directTypeExpr{clauses.typerep} _result;
        $directTypeExpr{scrutinee.typerep} _match_scrutinee_val = $Expr{scrutinee};
        $Stmt{clauses.transform}
        _result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
