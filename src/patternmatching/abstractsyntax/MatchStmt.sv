grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:src:patternmatching:abstractsyntax;

abstract production matchStmt
e::Stmt ::= scrutinee::Expr  clauses::StmtClauses
{
  e.globalDecls := [];
  e.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    braces(nestlines(2, clauses.pp)) ]);
                    
  -- TODO: Can't forward to an error prod b/c that adds a circular dependancy on
  -- forward.defs -> forward.env -> forward.errors -> forward.defs
  e.errors :=
    if !null(clauses.errors ++ scrutinee.errors)
    then clauses.errors ++ scrutinee.errors
    else forward.errors;

  clauses.expectedType = scrutinee.typerep;

  -- TODO:
  -- warning: Forward equation exceeds flow type with dependencies on
  -- edu:umn:cs:melt:ableC:abstractsyntax:returnType
  forwards to --if !null(clauses.errors) then warnStmt(clauses.errors) else
    compoundStmt(foldStmt( [
      txtStmt ("/* match (" ++ show(100,scrutinee.pp) ++ ") ... */"),

      mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
              scrutinee.location),
      mkDecl( "_match_scrutinee_ptr", pointerType( [], scrutinee.typerep), 
                unaryOpExpr( addressOfOp(location=scrutinee.location), 
                             declRefExpr(name("_match_scrutinee_val", location=scrutinee.location),
                                         location=scrutinee.location),
                             location=scrutinee.location),
                scrutinee.location),

      clauses.transform 
    ] )) ;
}

