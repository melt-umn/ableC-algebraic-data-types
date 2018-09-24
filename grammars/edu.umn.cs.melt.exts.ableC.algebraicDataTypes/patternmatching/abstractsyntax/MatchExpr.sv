grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production matchExpr
top::Expr ::= scrutinee::Expr  clauses::ExprClauses
{
  top.globalDecls := [];
  top.pp = ppConcat([ text("match"), space(), parens(scrutinee.pp), line(), 
                    parens(nestlines(2, clauses.pp)) ]);

  clauses.expectedType = scrutinee.typerep;

  local fwrd::Expr =
    stmtExpr (
      foldStmt( [
        exprStmt(comment("match (" ++ show(100,scrutinee.pp) ++ ") ...", location=builtin)),

        declStmt(
          variableDecls( [], nilAttribute(), directTypeExpr(clauses.typerep),
             consDeclarator(
               declarator( name("__result", location=builtin), 
                 baseTypeExpr(), nilAttribute(), 
                 nothingInitializer () ),
               nilDeclarator() ) ) ),

        mkDecl( "_match_scrutinee_val", scrutinee.typerep, scrutinee, 
                builtin),

        mkDecl( "_match_scrutinee_ptr", pointerType( nilQualifier(), scrutinee.typerep), 
                addressOfExpr( declRefExpr(name("_match_scrutinee_val", location=builtin),
                                           location=builtin),
                               location=builtin),
                builtin),

        clauses.transform 
      ] ),

      declRefExpr(name("__result", location=builtin), location=builtin),

      location = builtin 
    ) ;
  forwards to mkErrorCheck(clauses.errors ++ scrutinee.errors, fwrd);
}
