grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

{-- Pattern is a closed nonterminal, allowing other extensions to add arbitrary new
    productions, instead of arbitrary new attributes with regular nonterminals, since
    this is generally expected to be more useful.
-}
closed nonterminal Pattern with location, pp, decls, expectedType, errors, defs, env, returnType, substituted<Pattern>, substitutions;
flowtype Pattern = decorate {expectedType, env, returnType}, pp {}, decls {decorate}, errors {decorate}, defs {decorate}, substituted {substitutions};

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
flowtype transform {decorate, transformIn} on Pattern;

abstract production patternName
top::Pattern ::= n::Name
{
  propagate substituted;
  top.pp = n.pp;
  forwards to
    case n.valueItem of
    | enumValueItem(_) -> patternConst(declRefExpr(n, location=builtin), location=top.location)
    | _ -> patternVariable(n, location=top.location)
    end;
}

abstract production patternVariable
top::Pattern ::= n::Name
{
  propagate substituted;
  top.pp = n.pp;
  top.decls = [declStmt(d)];
  top.defs := d.defs;
  top.errors := []; --ToDo: - check for non-linearity
  top.errors <- n.valueRedeclarationCheckNoCompatible;
  
  local d :: Decl =
    variableDecls([], nilAttribute(), directTypeExpr(top.expectedType),
      consDeclarator(
        declarator(n, baseTypeExpr(), nilAttribute(), nothingInitializer()),
        nilDeclarator()));
  d.env = top.env;
  d.returnType = top.returnType;
  d.isTopLevel = false;
  
  top.transform = ableC_Expr { ($Name{n} = $Expr{top.transformIn}, 1) };
}

abstract production patternWildcard
top::Pattern ::=
{
  propagate substituted;
  top.pp = text("_");
  top.decls = [];
  top.defs := [];
  top.errors := [];
  top.transform = mkIntConst(1, builtin);
}

abstract production patternConst
top::Pattern ::= constExpr::Expr
{
  propagate substituted;
  top.pp = constExpr.pp;
  top.decls = [];
  top.defs := [];
  top.errors := [];
  top.errors <-
    if !typeAssignableTo(constExpr.typerep, top.expectedType) -- TODO: Proper handling for equality type checking
    then [err(constExpr.location, s"Constant pattern expected to match type ${showType(constExpr.typerep)} (got ${showType(top.expectedType)})")]
    else [];
  
  top.transform = equalsExpr(top.transformIn, constExpr, location=builtin);
}

abstract production patternStringLiteral
top::Pattern ::= s::String
{
  propagate substituted;
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
    if !compatibleTypes(stringType, top.expectedType, true, true)
    then [err(top.location, s"Constant pattern expected to match type ${showType(stringType)} (got ${showType(top.expectedType)})")]
    else [];
  top.errors <-
    if null(lookupValue("strcmp", top.env))
    then [err(top.location, "Pattern string literals require definition of strcmp (include <string.h>?)")]
    else [];

  top.transform = ableC_Expr { !strcmp($Expr{top.transformIn}, $Expr{stringLiteral(s, location=builtin)}) };
}

abstract production patternPointer
top::Pattern ::= p::Pattern
{
  propagate substituted;
  top.pp = cat(pp"&", p.pp);
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors;
  top.errors <-
    case top.expectedType.withoutAttributes of
    | pointerType(_, _) -> []
    | errorType() -> []
    | _ -> [err(p.location, s"Pointer pattern expected to match pointer type (got ${showType(top.expectedType)})")]
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

abstract production patternBoth
top::Pattern ::= p1::Pattern p2::Pattern
{
  propagate substituted;
  top.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  top.decls = p1.decls ++ p2.decls;
  top.defs := p1.defs ++ p2.defs;
  top.errors := p1.errors ++ p2.errors;
  
  p1.env = top.env;
  p2.env = addEnv(p1.defs, top.env);
  p1.expectedType = top.expectedType;
  p2.expectedType = top.expectedType;
  p1.transformIn = top.transformIn;
  p2.transformIn = top.transformIn;

  top.transform = andExpr(p1.transform, p2.transform, location=builtin);
}

abstract production patternNot
top::Pattern ::= p::Pattern 
{
  propagate substituted;
  top.pp = cat(text("! "), p.pp);
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors; -- TODO: Exclude variable patterns
  
  p.env = top.env;
  p.expectedType = top.expectedType;

  p.transformIn = top.transformIn;
  top.transform = notExpr(p.transform, location=builtin);
}

abstract production patternWhen
top::Pattern ::= e::Expr
{
  propagate substituted;
  top.pp = cat( text("when"), parens(e.pp));
  top.decls = [];
  top.defs := [];
  top.errors := e.errors;
  top.errors <-
    if !e.typerep.defaultFunctionArrayLvalueConversion.isScalarType
    then [err(e.location, "when condition must be scalar type, instead it is " ++ showType(e.typerep))]
    else [];
  
  top.transform = e;
}

abstract production patternParens
top::Pattern ::= p::Pattern
{
  propagate substituted;
  top.pp = parens(p.pp);
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors;
  top.transform = p.transform;
  
  p.expectedType = top.expectedType;
  p.transformIn = top.transformIn;
}

-- PatternList --
-----------------
nonterminal PatternList with pps, errors, env, returnType, defs, decls, expectedTypes, count, transform<Expr>, transformIn<[Expr]>, substituted<PatternList>, substitutions;
flowtype PatternList = decorate {expectedTypes, env, returnType}, pps {}, decls {decorate}, errors {decorate}, defs {decorate}, count {}, substituted {substitutions};

abstract production consPattern
top::PatternList ::= p::Pattern rest::PatternList
{
  propagate substituted;
  top.pps = p.pp :: rest.pps;
  top.errors := p.errors ++ rest.errors;
  top.defs := p.defs ++ rest.defs;
  top.decls = p.decls ++ rest.decls;
  top.count = 1 + rest.count;
  
  p.env = top.env;
  rest.env = addEnv(p.defs, top.env);
  
  local splitTypes :: Pair<Type [Type]> =
    case top.expectedTypes of
    | t::ts -> pair(t, ts)
    | [] -> pair(errorType(), [])
    end;
  p.expectedType = splitTypes.fst;
  rest.expectedTypes = splitTypes.snd;
  
  top.transform = andExpr(p.transform, rest.transform, location=builtin);
  p.transformIn = head(top.transformIn);
  rest.transformIn = tail(top.transformIn);
}

abstract production nilPattern
top::PatternList ::= {-empty-}
{
  propagate substituted;
  top.pps = [];
  top.errors := [];
  top.count = 0;
  top.defs := [];
  top.decls = [];
  top.transform = mkIntConst(1, builtin);
}

