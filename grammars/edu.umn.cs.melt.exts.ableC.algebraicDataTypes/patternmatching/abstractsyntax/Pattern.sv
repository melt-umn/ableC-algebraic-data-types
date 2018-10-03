grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

nonterminal Pattern with location, pp, decls, expectedType, errors, 
  defs, env,
  returnType;


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


-- * e
function mkDereferenceOf
Expr ::= e::Expr l::Location
{ return dereferenceExpr( e, location=l );
}


abstract production patternVariable
top::Pattern ::= id::String
{
  top.pp = text(id);

  top.decls = [declStmt(d)];
  local d :: Decl =
    variableDecls( [], nilAttribute(), directTypeExpr(top.expectedType), 
      consDeclarator(
        declarator( name(id, location=builtin), baseTypeExpr(), nilAttribute(), 
          nothingInitializer() ),
        nilDeclarator()) );

  d.env = top.env; 
  d.returnType = top.returnType;
  d.isTopLevel = false;
  top.defs := d.defs;

  top.errors := []; --ToDo: - check for non-linearity

  top.transform =
    mkAssign(
      id,
      mkDereferenceOf (
        declRefExpr (name("_curr_scrutinee_ptr",location=builtin), location=builtin),
	builtin),
      builtin);
    -- parseStmt(id ++ " = * _curr_scrutinee_ptr;") ;
}

abstract production patternWildcard
top::Pattern ::=
{
  top.pp = text("_");
  top.decls = [];
  top.defs := [];
  top.errors := [];
  top.transform = nullStmt();
}

abstract production patternConst
top::Pattern ::= constExpr::Expr
{
  top.pp = constExpr.pp;
  top.decls = [];
  top.defs := [];
  top.errors := (if compatibleTypes(top.expectedType, constExpr.typerep, false, false) then [] else
                  [err(builtin, "Unexpected constant in pattern")]);

  top.transform 
    = ifStmt(
        parseExpr("( *_curr_scrutinee_ptr != " ++ show(10, constExpr.pp) ++ ")"),
        -- then clause
        parseStmt("_match = 0;"),
        -- else clause
        nullStmt()
      );
}

abstract production patternStringLiteral
top::Pattern ::= s::String
{
  top.pp = text(s);
  top.decls = [];
  top.defs := [];
  top.errors := (if compatibleTypes(
                    top.expectedType,
                    pointerType(
                      nilQualifier(),
                      builtinType(
                        consQualifier(constQualifier(location=builtin),nilQualifier()),
                        signedType(charType()))),
                    false, false) then [] else
                  [err(builtin, "Unexpected string constant in pattern")]) ++
              (if !null(lookupValue("strcmp", top.env)) then [] else
                  [err(builtin, "Pattern string literals require <string.h> to be included")]);

  top.transform =
    ifStmt(
      parseExpr("strcmp( *_curr_scrutinee_ptr,(" ++ s ++ "))"),
        -- then clause
        parseStmt("_match = 0;"),
        -- else clause
        nullStmt()
      );
}
