grammar edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
e::Expr ::= scrutinee::Expr  clauses::ExprClauses
{
  e.globalDecls := [];
  e.pp = concat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    parens(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;

  forwards to if !null(clauses.errors) then errorExpr(clauses.errors, location=e.location) else
    stmtExpr (
      foldStmt( [
        txtStmt ("/* match (" ++ show(100,scrutinee.pp) ++ ") ... */"),

        declStmt(
          variableDecls( [], [], directTypeExpr(clauses.typerep),
             consDeclarator(
               declarator( name("__result", location=bogus_loc()), 
                 baseTypeExpr(), [], 
                 nothingInitializer () ),
               nilDeclarator() ) ) ),

        mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
                scrutinee.location),

        mkDecl( "_match_scrutinee_ptr", pointerType( [], scrutinee.typerep), 
                unaryOpExpr( addressOfOp(location=scrutinee.location), 
                             declRefExpr(name("_match_scrutinee_val", location=scrutinee.location),
                                         location=scrutinee.location),
                             location=scrutinee.location),
                scrutinee.location),

        clauses.transform 
      ] ),

      declRefExpr(name("__result", location=e.location), location=e.location),

      location = e.location 
    ) ;
}
