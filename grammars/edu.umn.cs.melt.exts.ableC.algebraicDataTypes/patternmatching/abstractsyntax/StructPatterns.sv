grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- struct/union patterns --
-- Mirrors initializer syntax, but slightly more sane with nested objects
-------------------
abstract production structPattern
top::Pattern ::= ps::StructPatternList
{
  top.pp = braces(ppImplode(text(", "), ps.pps));
  
  -- Type checking
  local refId::Maybe<String> =
    case top.expectedType of
    | extType( _, e) -> e.maybeRefId
    | _ -> nothing()
    end;
  
  local refIdLookup::[RefIdItem] =
    case refId of
    | just(rid) -> lookupRefId(rid, top.initialEnv)
    | nothing() -> []
    end;
  
  top.errors <-
    case top.expectedType, refId, refIdLookup of
    | errorType(), _, _ -> []
    -- Check that expected type for this pattern is some sort of type with fields
    | t, nothing(), _ -> [errFromOrigin(top, s"Initializer pattern expected to match a struct or union (got ${showType(t)}).")]
    -- Check that this type has a definition
    | t, just(id), [] -> [errFromOrigin(top, s"${showType(t)} does not have a definition.")]
    | _, _, _ -> []
    end;
  
  ps.givenTagEnv =
    case refIdLookup of
    | item :: _ -> item.tagEnv
    | [] -> emptyEnv()
    end;
  
  ps.givenFieldNames =
    case refIdLookup of
    | item :: _ -> flattenFieldNames(item.fieldNames, top.initialEnv)
    | [] -> []
    end;
  
  top.patternDecls = @ps.patternDecls;
  top.transform = @ps.transform;
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

inherited attribute givenTagEnv::Decorated Env;

inherited attribute givenFieldNames::[String];
synthesized attribute remainingFieldNames::[String];

tracked nonterminal StructPatternList with pps, errors, patternDecls,
  givenTagEnv, givenFieldNames, initialEnv, transform<Expr>, transformIn<Expr>;
flowtype StructPatternList =
  decorate {givenTagEnv, givenFieldNames, initialEnv, patternDecls.env, patternDecls.isTopLevel, patternDecls.controlStmtContext, transform.env, transform.controlStmtContext, transformIn},
  pps {}, errors {decorate}, patternDecls {givenFieldNames, givenTagEnv, initialEnv}, transform {givenFieldNames, givenTagEnv, initialEnv, transformIn};

propagate givenTagEnv, initialEnv, errors on StructPatternList;

abstract production consStructPattern
top::StructPatternList ::= p::StructPattern rest::StructPatternList
{
  top.pps = p.pp :: rest.pps;
  attachNote extensionGenerated("ableC-algebraic-data-types");

  p.givenFieldNames = top.givenFieldNames;
  rest.givenFieldNames = p.remainingFieldNames;
  
  top.patternDecls = consDecl(decls(@p.patternDecls), @rest.patternDecls);
  top.transform = andExpr(@p.transform, @rest.transform);
  p.transformIn = top.transformIn;
  rest.transformIn = top.transformIn;
}

abstract production nilStructPattern
top::StructPatternList ::= {-empty-}
{
  top.pps = [];
  top.patternDecls = nilDecl();
  top.transform = mkIntConst(1);
}

tracked nonterminal StructPattern with pp, errors, patternDecls,
  givenTagEnv, givenFieldNames, remainingFieldNames, initialEnv, transform<Expr>, transformIn<Expr>;
flowtype StructPattern =
  decorate {givenTagEnv, givenFieldNames, initialEnv, patternDecls.env, patternDecls.isTopLevel, patternDecls.controlStmtContext, transform.env, transform.controlStmtContext, transformIn},
  pp {}, errors {decorate}, patternDecls {givenFieldNames, givenTagEnv, initialEnv}, transform {givenFieldNames, givenTagEnv, initialEnv, transformIn};

propagate givenTagEnv, initialEnv, errors on StructPattern;

abstract production positionalStructPattern
top::StructPattern ::= p::Pattern
{
  top.pp = p.pp;
  attachNote extensionGenerated("ableC-algebraic-data-types");
  propagate env;
  top.remainingFieldNames =
    case top.givenFieldNames of
    | n :: ns -> ns
    | [] -> []
    end;
  
  production fieldName::String = head(top.givenFieldNames);
  
  top.errors <-
    if null(top.givenFieldNames)
    then [errFromOrigin(top, "Too many positional field patterns")]
    else [];
  
  p.expectedType =
    if null(top.givenFieldNames)
    then errorType()
    else case lookupValue(fieldName, top.givenTagEnv) of
    | v :: _-> v.typerep
    | [] -> errorType()
    end;
  
  top.patternDecls = @p.patternDecls;

  p.transformIn =
    memberExpr(top.transformIn, false, name(fieldName));
  top.transform = @p.transform;
}

abstract production namedStructPattern
top::StructPattern ::= n::Name p::Pattern
{
  top.pp = pp".${n.pp} = ${p.pp}";
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.errors <-
    if !null(n.valueLookupCheck)
    then [errFromOrigin(n, s"Unexpected named field ${n.name}")]
    else [];
  top.remainingFieldNames = top.givenFieldNames;
  
  n.env = top.givenTagEnv;
  p.expectedType = n.valueItem.typerep;
  
  top.patternDecls = @p.patternDecls;
  
  p.transformIn = memberExpr(top.transformIn, false, n);
  top.transform = @p.transform;
}
