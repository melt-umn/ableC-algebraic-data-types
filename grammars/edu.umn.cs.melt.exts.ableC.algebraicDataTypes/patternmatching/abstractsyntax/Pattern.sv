grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

{-- Pattern is a closed nonterminal, allowing other extensions to add arbitrary new
    productions, instead of arbitrary new attributes with regular nonterminals, since
    this is generally expected to be more useful.
-}
closed tracked nonterminal Pattern with pp, expectedType, initialEnv, errors;
flowtype Pattern =
  decorate {
    expectedType, initialEnv, transformIn,
    patternDecls.env, patternDecls.isTopLevel, patternDecls.controlStmtContext,
    transform.env, transform.controlStmtContext
  },
  pp {}, errors {decorate},
  patternDecls {expectedType, initialEnv}, transform {expectedType, initialEnv, transformIn};


{-- [Pattern] constructs are checked against an expected type, which
    is initially the type of the scrutinne.  These inherited
    attributes are used to pass these types down the clause and
    pattern ASTs.  -}
inherited attribute expectedType :: Type;
inherited attribute expectedTypes :: [Type];

-- The env for the overall match construct, used to resolve forwarding in patterns.
inherited attribute initialEnv::Decorated Env;

-- Pattern variable declarations for the pattern.
translation attribute patternDecls::Decls occurs on Pattern;

{-- [Pattern] constructs transform into expressions that evaluate to non-zero
    if there is a match.  Note that transformIn, the value to match against, may
    be used more than once in transform.  -}
attribute transformIn<Expr> occurs on Pattern; 
attribute transform<Expr> occurs on Pattern;

propagate errors, initialEnv on Pattern;

aspect default production
top::Pattern ::=
{
  top.patternDecls = nilDecl();
}

abstract production patternName
top::Pattern ::= n::Name
{
  top.pp = n.pp;
  n.env = top.initialEnv;
  forwards to
    case n.valueItem of
    | enumValueItem(_) -> patternConst(declRefExpr(n))
    | _ -> patternVariable(n)
    end;
}

abstract production patternVariable
top::Pattern ::= n::Name
{
  top.pp = n.pp;
  top.errors <- n.valueRedeclarationCheckNoCompatible;
  
  top.patternDecls = ableC_Decls { $directTypeExpr{top.expectedType} $Name{@n}; };
  top.transform = ableC_Expr { ($Name{n} = $Expr{top.transformIn}, 1) };
}

abstract production patternWildcard
top::Pattern ::=
{
  top.pp = text("_");
  top.transform = mkIntConst(1);
}

abstract production patternConst
top::Pattern ::= constExpr::Expr
{
  top.pp = constExpr.pp;
  top.errors <-  -- TODO: Proper handling for equality type checking
    if !typeAssignableTo(constExpr.typerep, top.expectedType.defaultFunctionArrayLvalueConversion)
    then [errFromOrigin(constExpr, s"Constant pattern expected to match type ${showType(constExpr.typerep)} (got ${showType(top.expectedType)})")]
    else [];
  
  top.transform = equalsExpr(top.transformIn, @constExpr);
}

abstract production patternStringLiteral
top::Pattern ::= s::String
{
  top.pp = text(s);
  
  local stringType::Type =
    pointerType(nilQualifier(),
      builtinType(
        consQualifier(constQualifier(), nilQualifier()),
        signedType(charType())));
  top.errors <-
    if !typeAssignableTo(stringType.defaultFunctionArrayLvalueConversion, top.expectedType.defaultFunctionArrayLvalueConversion)
    then [errFromOrigin(top, s"String constant pattern expected to match type ${showType(stringType)} (got ${showType(top.expectedType)})")]
    else [];
  top.errors <-
    if null(lookupValue("strcmp", top.transform.env))
    then [errFromOrigin(top, "Pattern string literals require definition of strcmp (include <string.h>?)")]
    else [];

  top.transform = ableC_Expr { !strcmp($Expr{top.transformIn}, $Expr{stringLiteral(s)}) };
}

abstract production patternPointer
top::Pattern ::= p::Pattern
{
  top.pp = cat(pp"&", p.pp);
  top.errors <-
    case top.expectedType.withoutAttributes of
    | pointerType(_, _) -> []
    | errorType() -> []
    | _ -> [errFromOrigin(p, s"Pointer pattern expected to match pointer type (got ${showType(top.expectedType)})")]
    end;
  
  p.expectedType =
    case top.expectedType.withoutAttributes of
    | pointerType(_, sub) -> sub
    | _ -> errorType()
    end;

  top.patternDecls = @p.patternDecls;
  
  -- Store the result of the dereference in a temporary variable
  -- since p.transformIn may be used more than once.
  local tempName::String = "_match_pointer_" ++ toString(genInt());
  p.transformIn = declRefExpr(name(tempName));
  top.transform =
    ableC_Expr {
      ({$directTypeExpr{p.expectedType} $name{tempName} = *$Expr{top.transformIn};
        $Expr{@p.transform};})
    };
}

abstract production patternBoth
top::Pattern ::= p1::Pattern p2::Pattern
{
  top.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  
  p1.expectedType = top.expectedType;
  p2.expectedType = top.expectedType;
  p1.transformIn = top.transformIn;
  p2.transformIn = top.transformIn;

  top.patternDecls = consDecl(decls(@p1.patternDecls), @p2.patternDecls);
  top.transform = andExpr(@p1.transform, @p2.transform);
}

abstract production patternNot
top::Pattern ::= p::Pattern 
{
  top.pp = cat(text("! "), p.pp);
  -- TODO: Exclude variable patterns

  p.expectedType = top.expectedType;

  top.patternDecls = @p.patternDecls;

  p.transformIn = top.transformIn;
  top.transform = notExpr(@p.transform);
}

abstract production patternWhen
top::Pattern ::= e::Expr
{
  top.pp = cat( text("when"), parens(e.pp));
  top.errors <-
    if !e.typerep.defaultFunctionArrayLvalueConversion.isScalarType
    then [errFromOrigin(e, "when condition must be scalar type, instead it is " ++ showType(e.typerep))]
    else [];
  
  top.transform = @e;
}

abstract production patternParens
top::Pattern ::= p::Pattern
{
  top.pp = parens(p.pp);
  top.patternDecls = @p.patternDecls;
  top.transform = @p.transform;
  
  p.expectedType = top.expectedType;
  p.transformIn = top.transformIn;
}

-- PatternList --
-----------------
inherited attribute appendedPatterns :: PatternList;
synthesized attribute appendedPatternsRes :: PatternList;

tracked nonterminal PatternList with pps, errors, patternDecls,
  expectedTypes, initialEnv, count, transform<Expr>, transformIn<[Expr]>,
  appendedPatterns, appendedPatternsRes, controlStmtContext;
flowtype PatternList =
  decorate {expectedTypes, initialEnv, patternDecls.env, patternDecls.isTopLevel, patternDecls.controlStmtContext, transform.env, transform.controlStmtContext, transformIn},
  pps {}, errors {decorate}, patternDecls {expectedTypes, initialEnv}, transform {expectedTypes, initialEnv, transformIn}, count {},
  appendedPatternsRes {appendedPatterns};

propagate errors, initialEnv, appendedPatterns on PatternList;

abstract production consPattern
top::PatternList ::= p::Pattern rest::PatternList
{
  top.pps = p.pp :: rest.pps;
  top.count = 1 + rest.count;
  top.appendedPatternsRes = consPattern(p, rest.appendedPatternsRes);
  
  local splitTypes :: Pair<Type [Type]> =
    case top.expectedTypes of
    | t::ts -> (t, ts)
    | [] -> (errorType(), [])
    end;
  p.expectedType = splitTypes.fst;
  rest.expectedTypes = splitTypes.snd;

  top.patternDecls = consDecl(decls(@p.patternDecls), @rest.patternDecls);
  
  top.transform = andExpr(@p.transform, @rest.transform);
  p.transformIn = if null(top.transformIn) then errorExpr([]) else head(top.transformIn);
  rest.transformIn = if null(top.transformIn) then [] else tail(top.transformIn);
}

abstract production nilPattern
top::PatternList ::= {-empty-}
{
  top.pps = [];
  top.count = 0;
  top.patternDecls = nilDecl();
  top.transform = mkIntConst(1);
  top.appendedPatternsRes = top.appendedPatterns;
}

function appendPatternList
PatternList ::= p1::PatternList p2::PatternList
{
  p1.appendedPatterns = p2;
  return p1.appendedPatternsRes;
}
