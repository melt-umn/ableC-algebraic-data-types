grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
top::Stmt ::= scrutinees::Exprs  clauses::StmtClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    braces(nestlines(2, clauses.pp)) ]);
  top.functionDefs := [];
  
  scrutinees.argumentPosition = 0;
  clauses.matchLocation = clauses.location; -- Whatever.
  clauses.expectedTypes = scrutinees.typereps;
  clauses.scrutineesIn = scrutinees.scrutineeRefs;
  
  local localErrors::[Message] = clauses.errors ++ scrutinees.errors;
  local fwrd::Stmt = seqStmt(scrutinees.transform, clauses.transform);
  
  forwards to if !null(localErrors) then warnStmt(localErrors) else fwrd;
}

synthesized attribute scrutineeRefs::[Expr];

attribute transform<Stmt>, scrutineeRefs occurs on Exprs;

aspect production consExpr
top::Exprs ::= h::Expr  t::Exprs
{
  top.transform =
    ableC_Stmt {
      $directTypeExpr{h.typerep} $name{"_match_scrutinee_val_" ++ toString(top.argumentPosition)} = $Expr{h};
      $Stmt{t.transform}
    };
  top.scrutineeRefs =
    ableC_Expr { $name{"_match_scrutinee_val_" ++ toString(top.argumentPosition)} } ::
    t.scrutineeRefs;
}

aspect production nilExpr
top::Exprs ::=
{
  top.transform = nullStmt();
  top.scrutineeRefs = [];
}