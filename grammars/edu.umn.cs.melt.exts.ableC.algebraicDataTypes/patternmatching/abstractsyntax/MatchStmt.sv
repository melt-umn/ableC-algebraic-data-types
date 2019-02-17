grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
top::Stmt ::= scrutinees::Exprs  clauses::StmtClauses
{
  propagate substituted;
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    braces(nestlines(2, clauses.pp)) ]);
  -- Non-interfering equations required due to flow analysis
  top.functionDefs := [labelDef(clauses.endLabelName, labelItem(builtin))];
  forward.env = addEnv(forward.functionDefs, top.env);
  
  -- Compute defs for clauses env
  local initialTransform::Stmt = scrutinees.transform;
  initialTransform.env = openScopeEnv(top.env);
  initialTransform.returnType = nothing();
  
  scrutinees.argumentPosition = 0;
  clauses.env = addEnv(initialTransform.defs, initialTransform.env);
  clauses.matchLocation = clauses.location; -- Whatever.
  clauses.expectedTypes = scrutinees.typereps;
  clauses.transformIn = scrutinees.scrutineeRefs;
  clauses.endLabelName = s"_end_${toString(genInt())}";
  
  local localErrors::[Message] = clauses.errors ++ scrutinees.errors;
  local fwrd::Stmt =
    ableC_Stmt {
      {
        $Stmt{decStmt(initialTransform)}
        $Stmt{clauses.transform}
        $name{clauses.endLabelName}: ;
      }
    };
  
  forwards to if !null(localErrors) then warnStmt(localErrors) else fwrd;
}

synthesized attribute scrutineeRefs::[Expr];

attribute transform<Stmt>, scrutineeRefs occurs on Exprs;
flowtype Exprs = transform {decorate, argumentPosition}, scrutineeRefs {decorate, argumentPosition};

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