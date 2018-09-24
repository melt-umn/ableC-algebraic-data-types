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

  c.expectedType = top.expectedType;
  rest.expectedType = top.expectedType;

  top.errors := c.errors ++ rest.errors;

  top.transform = c.transform;
  c.transformIn = rest.transform;
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

   ... declare _curr_scrutinee_ptr with expectedType
       set it to _match_scrutinee_ptr

   if ( ({ int _match = 1;
           ... check if pattern matches, set _match to 0 some part doesn't
           ... also assign values to pattern variables 
           _match; 
         }) )  
     {
       s   ... statement in clause
     }
   else {
     ... translation of remaining clauses, from transformIn
   }

 -}

abstract production stmtClause
top::StmtClause ::= p::Pattern s::Stmt
{
  top.pp = ppConcat([ p.pp, text("->"), space(), nestlines(2, s.pp) ]);
  top.errors := p.errors ++ s.errors;

  s.env = addEnv(p.defs,top.env);
  local l :: Location = builtin;

  top.transform = 
    foldStmt( [
        exprStmt(comment("matching for pattern " ++ show(80,p.pp), location=builtin)),
        exprStmt(comment("... declarations of pattern variables", location=builtin)),
        
        foldStmt( p.decls ),

        mkDecl ("_curr_scrutinee_ptr", pointerType( nilQualifier(), top.expectedType), 
                -- unaryOpExpr( dereferenceOp(location=builtin), 
                             declRefExpr( name("_match_scrutinee_ptr", 
                                               location=builtin),
                                          location=builtin ),
                --             location=builtin),
                builtin),

        ifStmt (
            -- condition: code to match the pattern
            stmtExpr( 
              foldStmt ([
                mkIntDeclInit ("_match", "1", builtin),
                p.transform
              ]),
              -- The stmtExpr result is the value of _match, which would be set
              -- by the translation of the pattern p, above.
              declRefExpr (name("_match", location=builtin), location=builtin),
              location=builtin
            ), 
            -- then part 
            s,
            -- else part 
            top.transformIn
        )
      ] );

  p.expectedType = top.expectedType;
}
