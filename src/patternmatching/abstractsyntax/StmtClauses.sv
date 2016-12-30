grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:src:patternmatching:abstractsyntax;

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
cs::StmtClauses ::= c::StmtClause rest::StmtClauses
{ 
  cs.pp = cat( c.pp, rest.pp );

  c.expectedType = cs.expectedType;
  rest.expectedType = cs.expectedType;

  cs.errors := c.errors ++ rest.errors;

  cs.transform = c.transform;
  c.transformIn = rest.transform;
}

abstract production failureStmtClause
cs::StmtClauses ::= 
{
  cs.pp = text("");
  cs.errors := [];

  cs.transform = txtStmt("/* no match, do nothing. */");
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
c::StmtClause ::= p::Pattern s::Stmt
{
  c.pp = concat([ p.pp, text("->"), space(), nestlines(2, s.pp) ]);
  c.errors := p.errors ++ s.errors;

  s.env = addEnv(p.defs,c.env);

  c.transform = 
    foldStmt( [
        txtStmt( "/* matching for pattern " ++ show(80,p.pp) ++ " */"),
        txtStmt( "/* ... declarations of pattern variables */"),
        
        foldStmt( p.decls ),

        mkDecl ("_curr_scrutinee_ptr", pointerType( [], c.expectedType), 
                -- unaryOpExpr( dereferenceOp(location=c.location), 
                             declRefExpr( name("_match_scrutinee_ptr", 
                                               location=c.location),
                                          location=c.location ),
                --             location=c.location),
                c.location),

        ifStmt (
            -- condition: code to match the pattern
            stmtExpr( 
              foldStmt ([
                mkIntDeclInit ("_match", "1", p.location),
                p.transform
              ]),
              -- The stmtExpr result is the value of _match, which would be set
              -- by the translation of the pattern p, above.
              declRefExpr (name("_match", location=p.location), location=p.location),
              location=p.location
            ), 
            -- then part 
            s,
            -- else part 
            c.transformIn
        )
      ] );

  p.expectedType = c.expectedType;

{-

  p.transformIn = mkIntAssign( "_match", "1", p.location );
  p.position = 0;
  p.depth = 0;
  p.parentTag = "NoParent";  
  
  p.parent_id = "NoParent";
  p.parent_idType = "NoParent";
  p.parent_idTypeIndicator = scrutineeTypeInfo.fst;

  local scrutineeTypeInfo :: Pair<String [ Pair<String [Type]> ]> 
    = getExpectedADTTypeInfo ( c.expectedType, c.env );
-}
}

{-
abstract production guardedStmtClause
c::StmtClause ::= p::Pattern g::Stmt s::Stmt
{
  c.pp = concat([ p.pp, space(), text("where"), space(), g.pp,
                  text("->"), space(), nestlines(2, s.pp) ]);
  c.errors := p.errors ++ s.errors;
}

abstract production defaultStmtClause
c::StmtClause ::= e::Stmt
{
  c.pp = e.pp;
  c.errors := e.errors;
--  c.transform = e;
}

-}
