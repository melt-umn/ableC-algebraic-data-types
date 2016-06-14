grammar edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax;

-- Clauses --
-------------

{-  A sequence of Expr Clauses

     p1 -> e1 
     p2 -> e2
     ...
     pn -> en

    becomes

     {(
       type-of-scrutinee  __result; 
       if ( ... p1 matches ... ) {    
         __result = e1;
       } else {
       if ( ... p2 matches ... ) {
         __result = e2;
       } else {
       ...
       } else {
       if ( ... pn matches ... ) {
         __result = en;
       } ;
       __result;
     })

    Thus, the translation of later clauses are children of the
    translation of earlier clauses.  To achieve this, a pair of
    (backward) threaded attribute, transform and tranformIn, are used.
 -}

{-  Patterns are checked against an expected type, which is initially
    the type of the scrutinne.  The following inherited attribute are
    used to pass these types down the clause and pattern ASTs.
 -}

nonterminal ExprClauses with location, pp, errors, env,
  expectedType, transform<Stmt>, returnType, typerep;

abstract production consExprClause
cs::ExprClauses ::= c::ExprClause rest::ExprClauses
{ 
  cs.pp = cat( c.pp, rest.pp );

  c.expectedType = cs.expectedType;
  rest.expectedType = cs.expectedType;

  cs.errors := c.errors ++ rest.errors;
  cs.errors <-
    if typeAssignableTo(c.typerep, rest.typerep)
    then []
    else [err(c.location,
              "Incompatible types in rhs of pattern, expected " ++ showType(rest.typerep) ++
              " but found " ++ showType(c.typerep))];

  cs.transform = c.transform;
  c.transformIn = rest.transform;

  cs.typerep =
    if typeAssignableTo(c.typerep, rest.typerep)
    then c.typerep
    else errorType();
}

abstract production oneExprClause
cs::ExprClauses ::= c::ExprClause
{
  cs.pp = c.pp;
  c.expectedType = cs.expectedType;
  cs.errors := c.errors;

  cs.transform = c.transform;
  c.transformIn = txtStmt("printf(\"Failed to match any patterns in match expression.\\n\"); exit(1);\n");
  cs.typerep = c.typerep;
}

nonterminal ExprClause with location, pp, errors, env, returnType, 
  expectedType, transform<Stmt>, transformIn<Stmt>, typerep;

abstract production exprClause
c::ExprClause ::= p::Pattern e::Expr
{
  c.pp = concat([ p.pp, text("->"), space(), nestlines(2, e.pp), text(";")]);
  c.errors := p.errors ++ e.errors;

  e.env = addEnv(p.defs,c.env);
  p.expectedType = c.expectedType;

  c.typerep = e.typerep;

  c.transform
    = foldStmt( [
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
            mkAssign ("__result", e, e.location),
            -- else part 
            c.transformIn 
        )
      ] );
}
{-
  p.expectedType = c.expectedType;
  s.env = addEnv(p.defs,c.env);


  c.transform 
    = stmtExpr(
        -- Declarations of pattern variables.
        foldStmt(p.decls),

        conditionalExpr (
          stmtExpr(
              foldStmt ([
                mkIntDeclInit ("_match", "0", p.location),
                -- If-stmt to set _match and values to pattern variables.
                p.transform 
               ]),

              -- The stmtExpr result is the value of _match, which would be set
              -- by the translation of the pattern p, above.
              declRefExpr (name("_match", location=p.location), location=p.location),

              location=p.location
          ),

          -- The expression to evaluation on a successful match
          s,

          -- The expression to evaluation for following clauses
          c.transformIn,

          location=c.location
        ),

        location=c.location
      );      

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



{-
abstract production guardedExprClause
c::ExprClause ::= p::Pattern g::Expr s::Expr
{
  c.pp = concat([ p.pp, space(), text("where"), space(), g.pp,
                  text("->"), space(), nestlines(2, s.pp) ]);
  c.errors := p.errors ++ s.errors;
}

abstract production defaultClause
c::ExprClause ::= e::Expr
{
  c.pp = e.pp;
  c.errors := e.errors;
--  c.transform = e;
}

-}
