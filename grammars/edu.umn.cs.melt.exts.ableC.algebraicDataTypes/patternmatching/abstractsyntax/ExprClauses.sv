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
       {
         ... p1 pattern variable declarations ...
         if ( ... p1 matches ... ) {
           _match_result = e1;
           goto _end;
         }
       }
       {
         ... p2 pattern variable declarations ...
         if ( ... p2 matches ... ) {
           _match_result = e2;
           goto _end;
         }
       }
       ...
       {
         ... pn pattern variable declarations ...
         if ( ... pn matches ... ) {
           _match_result = en;
           goto _end;
         }
       }
       _end:
       _match_result;
     })

    The use of goto is required because having subsiquent patterns as
    else clauses would mean that (unused) pattern variables from
    preceding patterns could potentially shadow other variables with the
    same name.
 -}

{-  Patterns are checked against an expected type, which is initially
    the type of the scrutinee.  The following inherited attribute are
    used to pass these types down the clause and pattern ASTs.
 -}

inherited attribute appendedExprClauses :: ExprClauses;
synthesized attribute appendedExprClausesRes :: ExprClauses;

nonterminal ExprClauses with location, matchLocation, pp, errors,
  expectedTypes, transform<Stmt>, transformIn<[Expr]>, endLabelName,
  typerep, appendedExprClauses, appendedExprClausesRes, controlStmtContext;
flowtype ExprClauses =
  decorate {matchLocation, expectedTypes, transform.env, transform.controlStmtContext, transformIn},
  errors {decorate}, transform {decorate, endLabelName}, typerep {decorate},
  appendedExprClausesRes {appendedExprClauses};

propagate matchLocation, endLabelName, errors, appendedExprClauses on ExprClauses;

abstract production consExprClause
top::ExprClauses ::= c::ExprClause rest::ExprClauses
{
  top.pp = cat( c.pp, rest.pp );
  top.errors <-
    if typeAssignableTo(c.typerep, rest.typerep) || typeAssignableTo(rest.typerep, c.typerep)
    then []
    else [err(c.location,
              s"Incompatible types in rhs of pattern, expected ${showType(rest.typerep)} but found ${showType(c.typerep)}")];

  top.typerep =
    if typeAssignableTo(c.typerep, rest.typerep)
    then c.typerep
    else if typeAssignableTo(rest.typerep, c.typerep)
    then rest.typerep
    else errorType();
  top.appendedExprClausesRes = consExprClause(c, rest.appendedExprClausesRes, location=top.location);

  c.expectedTypes = top.expectedTypes;
  rest.expectedTypes = top.expectedTypes;

  top.transform = seqStmt(@c.transform, @rest.transform);
  c.transformIn = top.transformIn;
  rest.transformIn = top.transformIn;
}

abstract production failureExprClause
top::ExprClauses ::= 
{
  top.pp = text("");
  top.typerep = errorType();
  top.appendedExprClausesRes = top.appendedExprClauses;

  top.transform = nullStmt();
}

function appendExprClauses
ExprClauses ::= p1::ExprClauses p2::ExprClauses
{
  p1.appendedExprClauses = p2;
  return p1.appendedExprClausesRes;
}

nonterminal ExprClause with location, matchLocation, pp, errors,
  expectedTypes, transform<Stmt>, transformIn<[Expr]>, endLabelName,
  typerep;
flowtype ExprClause =
  decorate {matchLocation, expectedTypes, transform.env, transform.controlStmtContext, transformIn},
  errors {decorate}, transform {decorate, endLabelName}, typerep {decorate};

propagate matchLocation, endLabelName, errors on ExprClause;

abstract production exprClause
top::ExprClause ::= ps::PatternList e::Expr
{
  top.pp = ppConcat([ ppImplode(comma(), ps.pps), text("->"), space(), nestlines(2, e.pp), text(";")]);
  top.errors <-
    if ps.count != length(top.expectedTypes)
    then [err(top.location, s"This clause has ${toString(ps.count)} patterns, but ${toString(length(top.expectedTypes))} were expected.")]
    else [];

  ps.expectedTypes = top.expectedTypes;

  top.typerep = e.typerep;

  top.transform =
    ableC_Stmt {
      {
        $Decl{decls(foldDecl(ps.decls))}
        if ($Expr{@ps.transform}) {
          _match_result = $Expr{@e};
          goto $name{top.endLabelName};
        }
      }
    };
  ps.transformIn = top.transformIn;
}
