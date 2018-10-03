grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
top::Stmt ::= scrutinee::Expr  clauses::StmtClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    braces(nestlines(2, clauses.pp)) ]);
  top.functionDefs := [];

  clauses.expectedType = scrutinee.typerep;

  local localErrors::[Message] = clauses.errors ++ scrutinee.errors;
  local fwrd::Stmt =
    ableC_Stmt {
      $directTypeExpr{scrutinee.typerep} _match_scrutinee_val = $Expr{scrutinee};
      $Stmt{clauses.transform}
    };
  
  forwards to if !null(localErrors) then warnStmt(localErrors) else fwrd;
}
