grammar edu:umn:cs:melt:exts:ableC:algDataTypes:src:abstractsyntax;

nonterminal Pattern with location, pp, decls, expectedType, errors, 
  defs, env,
  returnType;
--Remove: position, depth, parentTag, decls, parent_id, parent_idType, , parent_idTypeIndicator;


{-- This attribute collects declarations for pattern variables.
    During pattern matching, values are stored in these variables
    and then used when evaluating or executing the right hand side
    of clauses in a match expression or match statement.
-}
synthesized attribute decls :: [ Stmt ];


{-- [Pattern] constructs are checked against an expected type, which
    is initially the type of the scrutinne.  These inherited
    attributes are used to pass these types down the clause and
    pattern ASTs.  -}
inherited attribute expectedType :: Type;
inherited attribute expectedTypes :: [Type];


{-- [Pattern] constructs transform into statements that set the
    ``_match`` to 1 if the pattern matches.

    The invariant that must be maintained is that this code assumes
    that the data it is to match is pointed to by
    ``_curr_scrutinee_ptr`` and that ``_curr_scrutinee_ptr`` is
    declared to have the appropriate type.  -}
attribute transform<Stmt> occurs on Pattern; 


abstract production patternVariable
p::Pattern ::= id::String
{
  p.pp = text(id);

  p.decls = [declStmt(d)];
  local d :: Decl
    = variableDecls( [], [], directTypeExpr(p.expectedType), 
        consDeclarator(
          declarator( name(id, location=p.location), baseTypeExpr(), [], 
            nothingInitializer() ),
          nilDeclarator()) );

  {- This is actually OK, due to the modular well-definedness analysis.
     We know that extensions cannot add new dependencies of inherited 
     attributes on host language synthesized attributes.  So we know 
     that 'defs' depends on 'env' and nothing else.   -}
  d.env = emptyEnv(); 
  d.returnType = p.returnType;
  d.isTopLevel = false;
  p.defs = d.defs;

  p.errors := []; --ToDo: - check for non-linearity

  p.transform = txtStmt(id ++ " = * _curr_scrutinee_ptr;") ;
}


abstract production patternWildcard
p::Pattern ::=
{
  p.pp = text("_");
  p.decls = [];
  p.defs = [];
  p.errors := [];
  p.transform = nullStmt();
}

abstract production patternConst
p::Pattern ::= constExpr::Expr
{
  p.pp = constExpr.pp;
  p.decls = [];
  p.defs = [];
  p.errors := (if compatibleTypes(p.expectedType, constExpr.typerep, false) then [] else
                  [err(p.location, "Unexpected constant in pattern")]);

  p.transform 
    = ifStmt(
        txtExpr("( *_curr_scrutinee_ptr != " ++ show(10, constExpr.pp) ++ ")",
                location=p.location),
        -- then clause
        txtStmt("_match = 0;"),
        -- else clause
        nullStmt()
      );
}

abstract production patternStringLiteral
p::Pattern ::= s::String
{
  p.pp = text(s);
  p.decls = [];
  p.defs = [];
  p.errors := (if compatibleTypes(
                    p.expectedType,
                    pointerType(
                      [],
                      builtinType(
                        [constQualifier()],
                        signedType(charType()))),
                    false) then [] else
                  [err(p.location, "Unexpected string constant in pattern")]) ++
              (if !null(lookupValue("strcmp", p.env)) then [] else
                  [err(p.location, "Pattern string literals require <string.h> to be included")]);

  p.transform =
    ifStmt(
      txtExpr("!strcmp( *_curr_scrutinee_ptr,(" ++ s ++ ")",
              location=p.location),
        -- then clause
        txtStmt("_match = 0;"),
        -- else clause
        nullStmt()
      );
}
