grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
top::Stmt ::= scrutinees::ScrutineeExprs  clauses::StmtClauses
{
  top.pp = ppConcat([ text("match"), space(), parens(ppImplode(comma(), scrutinees.pps)), line(), 
                    braces(nestlines(2, clauses.pp)) ]);
  -- Non-interfering equations required due to flow analysis
  propagate functionDefs, labelDefs;
  top.labelDefs <- [(clauses.endLabelName, labelItem(builtin))];

  scrutinees.argumentPosition = 0;
  clauses.matchLocation = clauses.location; -- Whatever.
  clauses.expectedTypes = scrutinees.typereps;
  clauses.transformIn = scrutinees.scrutineeRefs;
  clauses.endLabelName = s"_end_${toString(genInt())}";
  clauses.initialEnv = top.env;
  
  local localErrors::[Message] = clauses.errors ++ scrutinees.errors;
  forward fwrd =
    ableC_Stmt {
      {
        $Stmt{@scrutinees.transform}
        $Stmt{@clauses.transform}
        $name{clauses.endLabelName}: ;
      }
    };
  
  forwards to if !null(localErrors) then warnStmt(localErrors) else @fwrd;
}

synthesized attribute scrutineeRefs::[Expr];

nonterminal ScrutineeExprs with pps, transform<Stmt>, scrutineeRefs, typereps, errors, argumentPosition;
flowtype ScrutineeExprs = decorate {transform.env, transform.controlStmtContext},
  pps {}, transform {argumentPosition}, scrutineeRefs {argumentPosition},
  typereps {decorate}, errors {decorate};

propagate errors, initialEnv on ScrutineeExprs;

abstract production consScrutineeExpr
top::ScrutineeExprs ::= h::Expr  t::ScrutineeExprs
{
  top.pps = h.pp :: t.pps;

  local matchVarName::Name = name("_match_scrutinee_val_" ++ toString(top.argumentPosition), location=builtin);
  top.transform =
    ableC_Stmt {
      $Decl{autoDecl(matchVarName, @h)}
      $Stmt{@t.transform}
    };
  top.scrutineeRefs =
    ableC_Expr { $Name{matchVarName} } ::
    t.scrutineeRefs;
  top.typereps = h.typerep :: t.typereps;

  t.argumentPosition = top.argumentPosition + 1;
}

abstract production nilScrutineeExpr
top::ScrutineeExprs ::=
{
  top.pps = [];
  top.transform = nullStmt();
  top.scrutineeRefs = [];
  top.typereps = [];
}
