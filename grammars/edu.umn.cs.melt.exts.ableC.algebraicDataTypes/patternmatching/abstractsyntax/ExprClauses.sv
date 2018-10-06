grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- Clauses --
-------------

{-  A sequence of Expr Clauses

     p1 -> e1 
     p2 -> e2
     ...
     pn -> en

    becomes

     {(
       type-of-scrutinee  _result; 
       if ( ... p1 matches ... ) {    
         _result = e1;
       } else if ( ... p2 matches ... ) {
         _result = e2;
       } else ... if ( ... pn matches ... ) {
         _result = en;
       }
       _result;
     })

    Thus, the translation of later clauses are children of the
    translation of earlier clauses.  To achieve this, a pair of
    (backward) threaded attribute, transform and tranformIn, are used.
 -}

{-  Patterns are checked against an expected type, which is initially
    the type of the scrutinee.  The following inherited attribute are
    used to pass these types down the clause and pattern ASTs.
 -}

nonterminal ExprClauses with location, matchLocation, pp, errors, env, expectedTypes, scrutineesIn, transform<Stmt>, returnType, typerep;

abstract production consExprClause
top::ExprClauses ::= c::ExprClause rest::ExprClauses
{ 
  top.pp = cat( c.pp, rest.pp );

  c.expectedTypes = top.expectedTypes;
  rest.expectedTypes = top.expectedTypes;

  top.errors := c.errors ++ rest.errors;
  top.errors <-
    if typeAssignableTo(c.typerep, rest.typerep)
    then []
    else [err(c.location,
              s"Incompatible types in rhs of pattern, expected ${showType(rest.typerep)} but found ${showType(c.typerep)}")];

  top.transform = c.transform;
  c.transformIn = rest.transform;

  top.typerep =
    if typeAssignableTo(c.typerep, rest.typerep)
    then c.typerep
    else errorType();
}

abstract production oneExprClause
top::ExprClauses ::= c::ExprClause
{
  top.pp = c.pp;
  c.expectedTypes = top.expectedTypes;
  top.errors := c.errors;
  top.errors <-
    if null(lookupValue("exit", top.env))
    then [err(top.matchLocation, "Pattern match requires definition of exit (include <stdlib.h>?)")]
    else [];
  top.errors <-
    if null(lookupValue("fprintf", top.env))
    then [err(top.matchLocation, "Pattern match requires definition of fprintf (include <stdio.h>?)")]
    else [];
  top.errors <-
    if null(lookupValue("stderr", top.env))
    then [err(top.matchLocation, "Pattern match requires definition of stderr (include <stdio.h>?)")]
    else [];

  top.transform = c.transform;
  c.transformIn =
    ableC_Stmt {
      fprintf(stderr, $stringLiteralExpr{s"Pattern match failure at ${top.matchLocation.unparse}\n"});
      exit(1);
    };
  top.typerep = c.typerep;
}

nonterminal ExprClause with location, matchLocation, pp, errors, env, returnType, expectedTypes, scrutineesIn, transform<Stmt>, transformIn<Stmt>, typerep;

abstract production exprClause
top::ExprClause ::= ps::PatternList e::Expr
{
  top.pp = ppConcat([ ppImplode(comma(), ps.pps), text("->"), space(), nestlines(2, e.pp), text(";")]);
  top.errors := ps.errors ++ e.errors;
  top.errors <-
    if ps.count != length(top.expectedTypes)
    then [err(top.location, s"This clause has ${toString(ps.count)} patterns, but ${toString(length(top.expectedTypes))} were expected.")]
    else [];

  e.env = addEnv(ps.defs, top.env);
  ps.expectedTypes = top.expectedTypes;

  top.typerep = e.typerep;

  top.transform =
    ableC_Stmt {
      $Stmt{foldStmt(ps.decls)}
      if ($Expr{ps.transform}) {
        _result = $Expr{e};
      } else {
        $Stmt{top.transformIn}
      }
    };
  ps.transformIn = top.scrutineesIn;
}
