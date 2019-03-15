grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- Clauses --
-------------

{-  A sequence of Clauses

     p1 -> s1 
     p2 -> s2
     ...
     pn -> sn

    becomes

    {
      {
        ... p1 pattern variable declarations ...
        if ( ... p1 matches ... ) {
          s1
          goto _end;
        }
      }
      {
        ... p2 pattern variable declarations ...
        if ( ... p2 matches ... ) {
          s2
          goto _end;
        }
      }
      ...
      {
        ... p3 pattern variable declarations ...
        if ( ... pn matches ... ) {
          sn
          goto _end;
        }
      }
      _end: ;
    }
 
    The use of goto is required because having subsiquent patterns as
    else clauses would mean that (unused) pattern variables from
    preceding patterns could potentially shadow other variables with the
    same name.
-}

synthesized attribute transform<a> :: a;
inherited attribute transformIn<a> :: a;
autocopy attribute endLabelName::String;
autocopy attribute matchLocation::Location;

autocopy attribute appendedStmtClauses :: StmtClauses;
synthesized attribute appendedStmtClausesRes :: StmtClauses;

nonterminal StmtClauses with location, matchLocation, pp, errors, env, returnType,
  expectedTypes, transform<Stmt>, transformIn<[Expr]>, endLabelName,
  substituted<StmtClauses>, substitutions,
  appendedStmtClauses, appendedStmtClausesRes;
flowtype StmtClauses = decorate {env, returnType, matchLocation, expectedTypes, transformIn}, errors {decorate}, transform {decorate, endLabelName}, substituted {substitutions}, appendedStmtClausesRes {appendedStmtClauses};

abstract production consStmtClause
top::StmtClauses ::= c::StmtClause rest::StmtClauses
{
  propagate substituted;
  top.pp = cat( c.pp, rest.pp );
  top.errors := c.errors ++ rest.errors;
  top.appendedStmtClausesRes = consStmtClause(c, rest.appendedStmtClausesRes, location=top.location);
  
  rest.env = addEnv(c.defs, c.env);

  top.transform = seqStmt(c.transform, rest.transform);
  c.transformIn = top.transformIn;
  rest.transformIn = top.transformIn;

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


nonterminal StmtClause with location, matchLocation, pp, errors, defs, env,
  expectedTypes, returnType,
  transform<Stmt>, transformIn<[Expr]>, endLabelName,
  substituted<StmtClause>, substitutions;
flowtype StmtClause = decorate {env, returnType, matchLocation, expectedTypes, transformIn}, errors {decorate}, defs {decorate}, transform {decorate, endLabelName}, substituted {substitutions};

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
  top.pp = ppConcat([ ppImplode(comma(), ps.pps), text("->"), space(), braces(nestlines(2, s.pp)) ]);
  top.errors := ps.errors ++ s.errors;
  top.errors <-
    if ps.count != length(top.expectedTypes)
    then [err(top.location, s"This clause has ${toString(ps.count)} patterns, but ${toString(length(top.expectedTypes))} were expected.")]
    else [];
  top.defs := ps.defs ++ s.defs;
  
  top.transform =
    ableC_Stmt {
      {
        $Stmt{foldStmt(ps.decls)}
        if ($Expr{ps.transform}) {
          $Stmt{decStmt(s)}
          goto $name{top.endLabelName};
        }
      }
    };
  
  ps.expectedTypes = top.expectedTypes;
  ps.transformIn = top.transformIn;
  s.env = addEnv(ps.defs ++ ps.patternDefs, top.env);
}
