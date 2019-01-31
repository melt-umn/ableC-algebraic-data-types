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
       type-of-scrutinee  _match_result; 
       if ( ... p1 matches ... ) {    
         _match_result = e1;
       } else if ( ... p2 matches ... ) {
         _match_result = e2;
       } else ... if ( ... pn matches ... ) {
         _match_result = en;
       }
       _match_result;
     })

    Thus, the translation of later clauses are children of the
    translation of earlier clauses.  To achieve this, a pair of
    (backward) threaded attribute, transform and tranformIn, are used.
 -}

{-  Patterns are checked against an expected type, which is initially
    the type of the scrutinee.  The following inherited attribute are
    used to pass these types down the clause and pattern ASTs.
 -}

autocopy attribute appendedExprClauses :: ExprClauses;
synthesized attribute appendedExprClausesRes :: ExprClauses;

nonterminal ExprClauses with location, matchLocation, pp, errors, env, expectedTypes, scrutineesIn, transform<Stmt>, transformIn<Stmt>, returnType, typerep, substituted<ExprClauses>, substitutions, appendedExprClauses, appendedExprClausesRes;
flowtype ExprClauses = decorate {env, returnType, matchLocation, expectedTypes}, errors {decorate}, transform {decorate, scrutineesIn, transformIn}, typerep {decorate}, substituted {substitutions}, appendedExprClausesRes {appendedExprClauses};

abstract production consExprClause
top::ExprClauses ::= c::ExprClause rest::ExprClauses
{
  propagate substituted;
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
  rest.transformIn = top.transformIn;

  top.typerep =
    if typeAssignableTo(c.typerep, rest.typerep)
    then c.typerep
    else errorType();
  top.appendedExprClausesRes = consExprClause(c, rest.appendedExprClausesRes, location=top.location);
}

abstract production failureExprClause
top::ExprClauses ::= 
{
  propagate substituted;
  top.pp = text("");
  top.errors := [];
  top.typerep = errorType();
  top.appendedExprClausesRes = top.appendedExprClauses;

  top.transform = top.transformIn;
}

function appendExprClauses
ExprClauses ::= p1::ExprClauses p2::ExprClauses
{
  p1.appendedExprClauses = p2;
  return p1.appendedExprClausesRes;
}

nonterminal ExprClause with location, matchLocation, pp, errors, env, returnType, expectedTypes, scrutineesIn, transform<Stmt>, transformIn<Stmt>, typerep, substituted<ExprClause>, substitutions;
flowtype ExprClause = decorate {env, returnType, matchLocation, expectedTypes}, errors {decorate}, transform {decorate, scrutineesIn, transformIn}, typerep {decorate}, substituted {substitutions};

abstract production exprClause
top::ExprClause ::= ps::PatternList e::Expr
{
  propagate substituted;
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
        _match_result = $Expr{e};
      } else {
        $Stmt{top.transformIn}
      }
    };
  ps.transformIn = top.scrutineesIn;
}
