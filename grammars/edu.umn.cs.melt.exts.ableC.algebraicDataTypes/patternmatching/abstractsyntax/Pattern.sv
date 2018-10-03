grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

{-- Pattern is a closed nonterminal, allowing other extensions to add arbitrary new
    productions, instead of arbitrary new attributes with regular nonterminals, since
    this is generally expected to be more useful.
-}
closed nonterminal Pattern with location, pp, decls, expectedType, errors, defs, env, returnType;

{-- This attribute collects declarations for pattern variables.
    During pattern matching, values are stored in these variables
    and then used when evaluating or executing the right hand side
    of clauses in a match expression or match statement.
-}
synthesized attribute decls :: [Stmt];


{-- [Pattern] constructs are checked against an expected type, which
    is initially the type of the scrutinne.  These inherited
    attributes are used to pass these types down the clause and
    pattern ASTs.  -}
inherited attribute expectedType :: Type;
inherited attribute expectedTypes :: [Type];

{-- [Pattern] constructs transform into expressions that evaluate to non-zero
    if there is a match.  Note that transformIn, the value to match against, may
    be used more than once in transform.  -}
attribute transformIn<Expr> occurs on Pattern; 
attribute transform<Expr> occurs on Pattern;

abstract production patternVariable
top::Pattern ::= id::String
{
  top.pp = text(id);
  top.decls = [declStmt(d)];
  top.defs := d.defs;
  top.errors := []; --ToDo: - check for non-linearity
  
  local d :: Decl =
    variableDecls([], nilAttribute(), directTypeExpr(top.expectedType), 
      consDeclarator(
        declarator(
          name(id, location=builtin), baseTypeExpr(), nilAttribute(), nothingInitializer()),
        nilDeclarator()) );
  d.env = top.env; 
  d.returnType = top.returnType;
  d.isTopLevel = false;

  top.transform = ableC_Expr { ($name{id} = $Expr{top.transformIn}, 1) };
}

abstract production patternWildcard
top::Pattern ::=
{
  top.pp = text("_");
  top.decls = [];
  top.defs := [];
  top.errors := [];
  top.transform = mkIntConst(1, builtin);
}

abstract production patternConst
top::Pattern ::= constExpr::Expr
{
  top.pp = constExpr.pp;
  top.decls = [];
  top.defs := [];
  top.errors := [];
  top.errors <-
    if !compatibleTypes(top.expectedType, constExpr.typerep, false, false)
    then [err(builtin, s"Constant pattern expected type ${showType(constExpr.typerep)} (got ${showType(top.expectedType)})")]
    else [];
  
  top.transform = equalsExpr(top.transformIn, constExpr, location=builtin);
}

abstract production patternStringLiteral
top::Pattern ::= s::String
{
  top.pp = text(s);
  top.decls = [];
  top.defs := [];
  top.errors := [];
  
  local stringType::Type =
    pointerType(
      nilQualifier(),
      builtinType(
        consQualifier(constQualifier(location=builtin), nilQualifier()),
        signedType(charType())));
  top.errors <-
    if !compatibleTypes(top.expectedType, stringType, false, false)
    then [err(builtin, s"Constant pattern expected type ${showType(stringType)} (got ${showType(top.expectedType)})")]
    else [];
  top.errors <-
    if null(lookupValue("strcmp", top.env))
    then [err(builtin, "Pattern string literals require definition of strcmp (include <string.h>?)")]
    else [];

  top.transform = ableC_Expr { !strcmp(*_curr_scrutinee_ptr, $stringLiteralExpr{s}) };
}

abstract production patternPointer
top::Pattern ::= p::Pattern
{
  top.pp = cat(pp"&", p.pp);
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors;
  top.errors <-
    case top.expectedType.withoutAttributes of
    | pointerType(_, _) -> []
    | errorType() -> []
    | _ -> [err(builtin, s"Pointer pattern expected pointer type (got ${showType(top.expectedType)})")]
    end;
  
  p.expectedType =
    case top.expectedType.withoutAttributes of
    | pointerType(_, sub) -> sub
    | _ -> errorType()
    end;
  
  -- Store the result of the dereference in a temporary variable
  -- since p.transformIn may be used more than once.
  local tempName::String = "_match_pointer_" ++ toString(genInt());
  p.transformIn = declRefExpr(name(tempName, location=builtin), location=builtin);
  top.transform =
    ableC_Expr {
      ({$directTypeExpr{p.expectedType} $name{tempName} = *$Expr{top.transformIn};
        $Expr{p.transform};})
    };
}
