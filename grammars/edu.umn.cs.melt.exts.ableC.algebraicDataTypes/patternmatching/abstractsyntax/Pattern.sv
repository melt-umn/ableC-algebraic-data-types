grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

{-- Pattern is a closed nonterminal, allowing other extensions to add arbitrary new
    productions, instead of arbitrary new attributes with regular nonterminals, since
    this is generally expected to be more useful.
-}
closed nonterminal Pattern with location, pp, decls, expectedType, errors, defs, patternDefs, env, returnType;
flowtype Pattern = decorate {expectedType, env, returnType, transformIn}, pp {}, decls {decorate}, errors {decorate}, defs {decorate}, patternDefs {decorate}, transform {decorate};

{-- This attribute collects definitions for pattern variables.
    During pattern matching, values are stored in these variables
    and then used when evaluating or executing the right hand side
    of clauses in a match expression or match statement.
-}
monoid attribute patternDefs :: [Def] with [], ++;


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

propagate decls, defs, patternDefs, errors on Pattern;

abstract production patternName
top::Pattern ::= n::Name
{
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
  top.pp = n.pp;
  top.decls <- [decDecl(d)];
  top.patternDefs <- d.defs;
  top.errors <- n.valueRedeclarationCheckNoCompatible;
  
  local d :: Decl =
    variableDecls(nilStorageClass(), nilAttribute(), directTypeExpr(top.expectedType),
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
  top.pp = text("_");
  top.transform = mkIntConst(1, builtin);
}

abstract production patternConst
top::Pattern ::= constExpr::Expr
{
  top.pp = constExpr.pp;
  top.errors <-
    if !typeAssignableTo(constExpr.typerep, top.expectedType) -- TODO: Proper handling for equality type checking
    then [err(constExpr.location, s"Constant pattern expected to match type ${showType(constExpr.typerep)} (got ${showType(top.expectedType)})")]
    else [];
  
  top.transform = equalsExpr(top.transformIn, constExpr, location=builtin);
}

abstract production patternStringLiteral
top::Pattern ::= s::String
{
  top.pp = text(s);
  
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
  top.pp = cat(pp"&", p.pp);
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
  local derefDecl::Decl =
    ableC_Decl {
      $directTypeExpr{p.expectedType} $name{tempName} = *$Expr{top.transformIn};
    };
  derefDecl.env = top.env;
  derefDecl.returnType = top.returnType;
  derefDecl.isTopLevel = false;
  
  p.env = addEnv(derefDecl.defs, top.env);
  
  p.transformIn = declRefExpr(name(tempName, location=builtin), location=builtin);
  top.transform =
    ableC_Expr {
      ({$Decl{decDecl(derefDecl)} $Expr{p.transform};})
    };
}

abstract production patternBoth
top::Pattern ::= p1::Pattern p2::Pattern
{
  top.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  
  p1.env = top.env;
  p2.env = addEnv(p1.defs ++ p1.patternDefs, top.env);
  p1.expectedType = top.expectedType;
  p2.expectedType = top.expectedType;
  p1.transformIn = top.transformIn;
  p2.transformIn = top.transformIn;

  top.transform = andExpr(p1.transform, p2.transform, location=builtin);
}

abstract production patternNot
top::Pattern ::= p::Pattern 
{
  top.pp = cat(text("! "), p.pp);
  -- TODO: Exclude variable patterns
  
  p.env = top.env;
  p.expectedType = top.expectedType;

  p.transformIn = top.transformIn;
  top.transform = notExpr(p.transform, location=builtin);
}

abstract production patternWhen
top::Pattern ::= e::Expr
{
  top.pp = cat( text("when"), parens(e.pp));
  top.errors <-
    if !e.typerep.defaultFunctionArrayLvalueConversion.isScalarType
    then [err(e.location, "when condition must be scalar type, instead it is " ++ showType(e.typerep))]
    else [];
  
  top.transform = decExpr(e, location=builtin);
}

abstract production patternParens
top::Pattern ::= p::Pattern
{
  top.pp = parens(p.pp);
  top.transform = p.transform;
  
  p.expectedType = top.expectedType;
  p.transformIn = top.transformIn;
}

-- PatternList --
-----------------
autocopy attribute appendedPatterns :: PatternList;
synthesized attribute appendedPatternsRes :: PatternList;

nonterminal PatternList with pps, errors, env, returnType, defs, decls, patternDefs, expectedTypes, count, transform<Expr>, transformIn<[Expr]>, appendedPatterns, appendedPatternsRes;
flowtype PatternList = decorate {expectedTypes, env, returnType, transformIn}, pps {}, decls {decorate}, patternDefs {decorate}, errors {decorate}, defs {decorate}, transform {decorate}, count {}, appendedPatternsRes {appendedPatterns};

propagate decls, defs, patternDefs, errors on PatternList;

abstract production consPattern
top::PatternList ::= p::Pattern rest::PatternList
{
  top.pps = p.pp :: rest.pps;
  top.count = 1 + rest.count;
  top.appendedPatternsRes = consPattern(p, rest.appendedPatternsRes);
 
  rest.env = addEnv(p.defs ++ p.patternDefs, top.env);
  
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
  top.pps = [];
  top.count = 0;
  top.transform = mkIntConst(1, builtin);
  top.appendedPatternsRes = top.appendedPatterns;
}

function appendPatternList
PatternList ::= p1::PatternList p2::PatternList
{
  p1.appendedPatterns = p2;
  return p1.appendedPatternsRes;
}
