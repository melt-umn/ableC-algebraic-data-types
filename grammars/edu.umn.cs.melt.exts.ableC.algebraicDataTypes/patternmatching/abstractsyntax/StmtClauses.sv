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

nonterminal StmtClauses with location, pp, errors, env, returnType,
  expectedType, transform<Stmt>; 

abstract production consStmtClause
top::StmtClauses ::= c::StmtClause rest::StmtClauses
{ 
  top.pp = cat( c.pp, rest.pp );
  top.errors := c.errors ++ rest.errors;

  top.transform = c.transform;
  c.transformIn = rest.transform;

  c.expectedType = top.expectedType;
  rest.expectedType = top.expectedType;
}

abstract production failureStmtClause
top::StmtClauses ::= 
{
  top.pp = text("");
  top.errors := [];

  top.transform = exprStmt(comment("no match, do nothing.", location=builtin));
}
  

nonterminal StmtClause with location, pp, errors, env, 
  expectedType, returnType,
  transform<Stmt>, transformIn<Stmt>;

{- A statement clause becomes a Stmt, in the form:

   ... declarations of pattern variables

   if ( ... check if pattern matches, also assign values to pattern variables ){
     s   ... statement in clause
   } else {
     ... translation of remaining clauses, from transformIn
   }

 -}

abstract production stmtClause
top::StmtClause ::= p::Pattern s::Stmt
{
  top.pp = ppConcat([ p.pp, text("->"), space(), nestlines(2, s.pp) ]);
  top.errors := p.errors ++ s.errors;
  
  top.transform =
    ableC_Stmt {
      $Stmt{foldStmt(p.decls)}
      if ($Expr{p.transform}) {
        $Stmt{s}
      } else {
        $Stmt{top.transformIn}
      }
    };
  
  p.expectedType = top.expectedType;
  p.transformIn = ableC_Expr { _match_scrutinee_val };
  s.env = addEnv(p.defs, top.env);
}
