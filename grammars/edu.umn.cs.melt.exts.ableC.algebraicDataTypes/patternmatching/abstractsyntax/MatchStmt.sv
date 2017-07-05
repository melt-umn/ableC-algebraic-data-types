grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchStmt
e::Stmt ::= scrutinee::Expr  clauses::StmtClauses
{
  --e.globalDecls := [];
  e.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    braces(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;

  production attribute lerrors :: [Message] with ++;
  lerrors := clauses.errors ++ scrutinee.errors;
  
  e.functiondefs := []; -- TODO: Hack to avoid cyclic dependancy on env when forwarding
  
  forwards to
    if !null(lerrors)
    then warnStmt(lerrors)
    else
      compoundStmt(foldStmt( [
        txtStmt ("/* match (" ++ show(100,scrutinee.pp) ++ ") ... */"),

        mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
                scrutinee.location),
        mkDecl( "_match_scrutinee_ptr", pointerType( nilQualifier(), scrutinee.typerep), 
                  unaryOpExpr( addressOfOp(location=scrutinee.location), 
                               declRefExpr(name("_match_scrutinee_val", location=scrutinee.location),
                                           location=scrutinee.location),
                               location=scrutinee.location),
                  scrutinee.location),

        clauses.transform 
      ] )) ;
}

