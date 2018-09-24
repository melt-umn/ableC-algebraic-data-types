grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
top::Stmt ::= scrutinee::Expr  clauses::StmtClauses
{
  --e.globalDecls := [];
  top.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    braces(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;

  production attribute lerrors :: [Message] with ++;
  lerrors := clauses.errors ++ scrutinee.errors;
  
  top.functionDefs := [];
  
  forwards to
    if !null(lerrors)
    then warnStmt(lerrors)
    else
      compoundStmt(foldStmt( [
        exprStmt(comment("match (" ++ show(100,scrutinee.pp) ++ ") ...", location=builtin)),

        mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
                builtin),
        mkDecl( "_match_scrutinee_ptr", pointerType( nilQualifier(), scrutinee.typerep), 
                  addressOfExpr( declRefExpr(name("_match_scrutinee_val", location=builtin),
                                             location=builtin),
                                 location=builtin),
                  builtin),

        clauses.transform 
      ] )) ;
}
