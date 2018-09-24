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
top::ExprClauses ::= c::ExprClause rest::ExprClauses
{ 
  top.pp = cat( c.pp, rest.pp );

  c.expectedType = top.expectedType;
  rest.expectedType = top.expectedType;

  top.errors := c.errors ++ rest.errors;
  top.errors <-
    if typeAssignableTo(c.typerep, rest.typerep)
    then []
    else [err(c.location,
              "Incompatible types in rhs of pattern, expected " ++ showType(rest.typerep) ++
              " but found " ++ showType(c.typerep))];

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
  c.expectedType = top.expectedType;
  top.errors := c.errors;

  top.transform = c.transform;
  c.transformIn = parseStmt("printf(\"Failed to match any patterns in match expression.\\n\"); exit(1);\n");
  top.typerep = c.typerep;
}

nonterminal ExprClause with location, pp, errors, env, returnType, 
  expectedType, transform<Stmt>, transformIn<Stmt>, typerep;

abstract production exprClause
top::ExprClause ::= p::Pattern e::Expr
{
  top.pp = ppConcat([ p.pp, text("->"), space(), nestlines(2, e.pp), text(";")]);
  top.errors := p.errors ++ e.errors;

  e.env = addEnv(p.defs,top.env);
  p.expectedType = top.expectedType;

  top.typerep = e.typerep;

  top.transform
    = foldStmt( [
        exprStmt(comment("matching for pattern " ++ show(80,p.pp), location=builtin)),

        exprStmt(comment("... declarations of pattern variables", location=builtin)),
	foldStmt( p.decls ),

        mkDecl ("_curr_scrutinee_ptr", pointerType( nilQualifier(), top.expectedType), 
                             declRefExpr( name("_match_scrutinee_ptr", 
                                               location=builtin),
                                          location=builtin ),
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
            mkAssign ("__result", e, builtin),
            -- else part 
            top.transformIn 
        )
      ] );
}
