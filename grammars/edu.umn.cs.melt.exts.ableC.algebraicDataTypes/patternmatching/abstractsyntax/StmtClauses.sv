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
inherited attribute endLabelName::String;
inherited attribute matchLocation::Location;

inherited attribute appendedStmtClauses :: StmtClauses;
synthesized attribute appendedStmtClausesRes :: StmtClauses;

nonterminal StmtClauses with location, matchLocation, pp, errors, functionDefs,
  env, controlStmtContext,
  expectedTypes, transform<Stmt>, transformIn<[Expr]>, endLabelName,
  appendedStmtClauses, appendedStmtClausesRes, labelDefs;
flowtype StmtClauses = decorate {env, matchLocation, expectedTypes,
  transformIn, controlStmtContext},
  errors {decorate}, functionDefs {}, labelDefs {}, transform {decorate, endLabelName},
  appendedStmtClausesRes {appendedStmtClauses};

propagate controlStmtContext, endLabelName, matchLocation, errors, functionDefs, labelDefs, appendedStmtClauses on StmtClauses;

abstract production consStmtClause
top::StmtClauses ::= c::StmtClause rest::StmtClauses
{
  top.pp = cat( c.pp, rest.pp );
  top.appendedStmtClausesRes = consStmtClause(c, rest.appendedStmtClausesRes, location=top.location);
  
  c.env = top.env;
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
  top.pp = text("");
  top.appendedStmtClausesRes = top.appendedStmtClauses;

  top.transform = exprStmt(comment("no match, do nothing.", location=builtin));
}

function appendStmtClauses
StmtClauses ::= p1::StmtClauses p2::StmtClauses
{
  p1.appendedStmtClauses = p2;
  return p1.appendedStmtClausesRes;
}


nonterminal StmtClause with location, matchLocation, pp, errors, defs, functionDefs, env,
  expectedTypes, controlStmtContext,
  transform<Stmt>, transformIn<[Expr]>, endLabelName, labelDefs;
flowtype StmtClause = decorate {env, matchLocation, expectedTypes,
  transformIn, controlStmtContext},
  errors {decorate}, defs {decorate}, functionDefs {}, labelDefs {}, transform {decorate, endLabelName};

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
  propagate controlStmtContext, matchLocation, errors, functionDefs, labelDefs;
  top.pp = ppConcat([ ppImplode(comma(), ps.pps), text("->"), space(), braces(nestlines(2, s.pp)) ]);
  top.errors <-
    if ps.count != length(top.expectedTypes)
    then [err(top.location, s"This clause has ${toString(ps.count)} patterns, but ${toString(length(top.expectedTypes))} were expected.")]
    else [];
  top.defs := ps.defs ++ globalDeclsDefs(s.globalDecls);
  
  top.transform =
    ableC_Stmt {
      {
        $Decl{decls(foldDecl(ps.decls))}
        if ($Expr{ps.transform}) {
          $Stmt{decStmt(s)}
          goto $name{top.endLabelName};
        }
      }
    };
  
  ps.env = top.env;
  ps.expectedTypes = top.expectedTypes;
  ps.transformIn = top.transformIn;
  s.env = addEnv(ps.defs ++ ps.patternDefs, openScopeEnv(top.env));
}
