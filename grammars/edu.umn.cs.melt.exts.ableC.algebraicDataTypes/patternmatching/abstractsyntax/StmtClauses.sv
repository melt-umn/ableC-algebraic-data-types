grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- Clauses --
-------------

{-  A sequence of Clauses

     p1 -> s1 
     p2 -> s2
     ...
     pn -> sn

    becomes

     if ( ... p1 matches ... ) {
       s1
     } else {
     if ( ... p2 matches ... ) {
       s2
     } else {
     ...
     } else {
     if ( ... pn matches ... ) {
       sn
     }
 
    The translation of the last clause is the body of the last
    innermonst else.  The translation of later clauses are children of
    the translation of earlier clauses.  To achieve this, a pair of
    (backward) threaded attributes, transform and tranformIn, are used.
    -}

synthesized attribute transform<a> :: a;
inherited attribute transformIn<a> :: a;
autocopy attribute scrutineesIn::[Expr];
autocopy attribute matchLocation::Location;

autocopy attribute appendedStmtClauses :: StmtClauses;
synthesized attribute appendedStmtClausesRes :: StmtClauses;

nonterminal StmtClauses with location, matchLocation, pp, errors, env, returnType,
  expectedTypes, scrutineesIn, transform<Stmt>,
  substituted<StmtClauses>, substitutions,
  appendedStmtClauses, appendedStmtClausesRes;
flowtype StmtClauses = decorate {env, returnType, matchLocation, expectedTypes}, errors {decorate}, transform {decorate, scrutineesIn}, substituted {substitutions}, appendedStmtClausesRes {appendedStmtClauses};

abstract production consStmtClause
top::StmtClauses ::= c::StmtClause rest::StmtClauses
{
  propagate substituted;
  top.pp = cat( c.pp, rest.pp );
  top.errors := c.errors ++ rest.errors;
  top.appendedStmtClausesRes = consStmtClause(c, rest.appendedStmtClausesRes, location=top.location);

  top.transform = c.transform;
  c.transformIn = rest.transform;

  c.expectedTypes = top.expectedTypes;
  rest.expectedTypes = top.expectedTypes;
}

abstract production failureStmtClause
top::StmtClauses ::= 
{
  propagate substituted;
  top.pp = text("");
  top.errors := [];
  top.appendedStmtClausesRes = top.appendedStmtClauses;

  top.transform = exprStmt(comment("no match, do nothing.", location=builtin));
}

function appendStmtClauses
StmtClauses ::= p1::StmtClauses p2::StmtClauses
{
  p1.appendedStmtClauses = p2;
  return p1.appendedStmtClausesRes;
}


nonterminal StmtClause with location, matchLocation, pp, errors, env, 
  expectedTypes, returnType, scrutineesIn,
  transform<Stmt>, transformIn<Stmt>,
  substituted<StmtClause>, substitutions;
flowtype StmtClause = decorate {env, returnType, matchLocation, expectedTypes}, errors {decorate}, transform {decorate, scrutineesIn, transformIn}, substituted {substitutions};

{- A statement clause becomes a Stmt, in the form:

   ... declarations of pattern variables

   if ( ... check if pattern matches, also assign values to pattern variables ){
     s   ... statement in clause
   } else {
     ... translation of remaining clauses, from transformIn
   }

 -}

abstract production stmtClause
top::StmtClause ::= ps::PatternList s::Stmt
{
  propagate substituted;
  top.pp = ppConcat([ ppImplode(comma(), ps.pps), text("->"), space(), nestlines(2, s.pp) ]);
  top.errors := ps.errors ++ s.errors;
  top.errors <-
    if ps.count != length(top.expectedTypes)
    then [err(top.location, s"This clause has ${toString(ps.count)} patterns, but ${toString(length(top.expectedTypes))} were expected.")]
    else [];
  
  top.transform =
    ableC_Stmt {
      $Stmt{foldStmt(ps.decls)}
      if ($Expr{ps.transform}) {
        $Stmt{s}
      } else {
        $Stmt{top.transformIn}
      }
    };
  
  ps.expectedTypes = top.expectedTypes;
  ps.transformIn = top.scrutineesIn;
  s.env = addEnv(ps.defs, top.env);
}
