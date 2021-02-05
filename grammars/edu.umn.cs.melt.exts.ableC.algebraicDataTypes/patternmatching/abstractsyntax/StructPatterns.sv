grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- struct/union patterns --
-- Mirrors initializer syntax, but slightly more sane with nested objects
-------------------
abstract production structPattern
top::Pattern ::= ps::StructPatternList
{
  top.pp = braces(ppImplode(text(", "), ps.pps));
  ps.env = top.env;
  
  -- Type checking
  local refId::Maybe<String> =
    case top.expectedType of
    | extType( _, e) -> e.maybeRefId
    | _ -> nothing()
    end;
  
  local refIdLookup::[RefIdItem] =
    case refId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  top.errors <-
    case top.expectedType, refId, refIdLookup of
    | errorType(), _, _ -> []
    -- Check that expected type for this pattern is some sort of type with fields
    | t, nothing(), _ -> [err(top.location, s"Initializer pattern expected to match a struct or union (got ${showType(t)}).")]
    -- Check that this type has a definition
    | t, just(id), [] -> [err(top.location, s"${showType(t)} does not have a definition.")]
    | _, _, _ -> []
    end;
  
  ps.givenTagEnv =
    case refIdLookup of
    | item :: _ -> item.tagEnv
    | [] -> emptyEnv()
    end;
  
  ps.givenFieldNames =
    case refIdLookup of
    | item :: _ -> flattenFieldNames(item.fieldNames, top.env)
    | [] -> []
    end;
  
  top.transform = ps.transform;
  ps.transformIn = top.transformIn;
}

function flattenFieldNames
[String] ::= fns::[Either<String ExtType>] env::Decorated Env
{
  return
    flatMap(
      \ f::Either<String ExtType> ->
        case f of
        | left(fn) -> [fn]
        | right(e) ->
          case e.maybeRefId of
          | just(refId) when lookupRefId(refId, env) matches r :: _ ->
            flattenFieldNames(r.fieldNames, env)
          | _ -> error("Failed to get anon struct fields")
          end
        end,
      fns);
}

autocopy attribute givenTagEnv::Decorated Env;

inherited attribute givenFieldNames::[String];
synthesized attribute remainingFieldNames::[String];

nonterminal StructPatternList with pps, errors, env, returnType, defs, decls,
  patternDefs, givenTagEnv, givenFieldNames, transform<Expr>, transformIn<Expr>,
  breakValid, continueValid;
flowtype StructPatternList = decorate {env, givenTagEnv, givenFieldNames,
  returnType, transformIn, breakValid, continueValid},
  pps {}, decls {decorate}, patternDefs {decorate}, errors {decorate},
  defs {decorate}, transform {decorate};

propagate errors, defs, decls, patternDefs on StructPatternList;

abstract production consStructPattern
top::StructPatternList ::= p::StructPattern rest::StructPatternList
{
  top.pps = p.pp :: rest.pps;
  
  p.env = top.env;
  rest.env = addEnv(p.defs, top.env);

  p.givenFieldNames = top.givenFieldNames;
  rest.givenFieldNames = p.remainingFieldNames;
  
  top.transform = andExpr(p.transform, rest.transform, location=builtin);
  p.transformIn = top.transformIn;
  rest.transformIn = top.transformIn;
}

abstract production nilStructPattern
top::StructPatternList ::= {-empty-}
{
  top.pps = [];
  top.transform = mkIntConst(1, builtin);
}

nonterminal StructPattern with location, pp, errors, defs, decls, patternDefs,
  givenTagEnv, givenFieldNames, remainingFieldNames, transform<Expr>, transformIn<Expr>,
  env, returnType, breakValid, continueValid;
flowtype StructPattern = decorate {env, givenTagEnv, givenFieldNames, returnType,
  transformIn, breakValid, continueValid},
  pp {}, decls {decorate}, patternDefs {decorate}, errors {decorate}, defs {decorate},
  transform {decorate};

propagate errors, defs, decls, patternDefs on StructPattern;

abstract production positionalStructPattern
top::StructPattern ::= p::Pattern
{
  top.pp = p.pp;
  top.remainingFieldNames =
    case top.givenFieldNames of
    | n :: ns -> ns
    | [] -> []
    end;
  
  production fieldName::String = head(top.givenFieldNames);
  
  top.errors <-
    if null(top.givenFieldNames)
    then [err(top.location, "Too many positional field patterns")]
    else [];
  
  p.expectedType =
    if null(top.givenFieldNames)
    then errorType()
    else case lookupValue(fieldName, top.givenTagEnv) of
    | v :: _-> v.typerep
    | [] -> errorType()
    end;
  
  p.transformIn =
    memberExpr(top.transformIn, false, name(fieldName, location=builtin), location=builtin);
  top.transform = p.transform;
}

abstract production namedStructPattern
top::StructPattern ::= n::Name p::Pattern
{
  top.pp = pp".${n.pp} = ${p.pp}";
  top.errors <-
    if !null(n.valueLookupCheck)
    then [err(n.location, s"Unexpected named field ${n.name}")]
    else [];
  top.remainingFieldNames = top.givenFieldNames;
  
  n.env = top.givenTagEnv;
  p.expectedType = n.valueItem.typerep;
  
  p.transformIn = memberExpr(top.transformIn, false, n, location=builtin);
  top.transform = p.transform;
}
