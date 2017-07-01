grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:src:patternmatching:abstractsyntax;

abstract production matchExpr
e::Expr ::= scrutinee::Expr  clauses::ExprClauses
{
  e.globalDecls := [];
  e.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    parens(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;

  local fwrd::Expr =
    stmtExpr (
      foldStmt( [
        txtStmt ("/* match (" ++ show(100,scrutinee.pp) ++ ") ... */"),

        declStmt(
          variableDecls( [], nilAttribute(), directTypeExpr(clauses.typerep),
             consDeclarator(
               declarator( name("__result", location=bogus_loc()), 
                 baseTypeExpr(), nilAttribute(), 
                 nothingInitializer () ),
               nilDeclarator() ) ) ),

        mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
                scrutinee.location),

        mkDecl( "_match_scrutinee_ptr", pointerType( nilQualifier(), scrutinee.typerep), 
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
  forwards to mkErrorCheck(clauses.errors ++ scrutinee.errors, fwrd);
}
