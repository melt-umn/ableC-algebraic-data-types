grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- struct/union patterns --
-------------------
abstract production structPattern
top::Pattern ::= ps::StructPatternList
{
  propagate substituted;
  top.pp = braces(ppImplode(text(", "), ps.pps));
  ps.env = top.env;
  top.decls = ps.decls;
  top.defs := ps.defs;
  
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
  
  local localErrors::[Message] =
    case top.expectedType, refId, refIdLookup of
    | errorType(), _, _ -> []
    -- Check that expected type for this pattern is some sort of type with fields
    | t, nothing(), _ -> [err(top.location, s"Initializer pattern expected to match a struct or union (got ${showType(t)}).")]
    -- Check that this type has a definition
    | t, just(id), [] -> [err(top.location, s"${showType(t)} does not have a definition.")]
    | _, _, _ -> []
    end;
  top.errors := localErrors ++ ps.errors;
  
  ps.givenTagEnv =
    case refIdLookup of
    | item :: _ -> item.tagEnv
    | [] -> emptyEnv()
    end;
  
  ps.givenFieldNames =
    -- TODO: Ugly hack to get ordered list of field names from the tag environment
    case ps.givenTagEnv of
    | addEnv_i(d, _) -> map(fst, d.valueContribs)
    | _ -> []
    end;
  
  top.transform = ps.transform;
  ps.transformIn = top.transformIn;
}

autocopy attribute givenTagEnv::Decorated Env;

inherited attribute givenFieldNames::[String];
synthesized attribute remainingFieldNames::[String];

nonterminal StructPatternList with pps, errors, env, returnType, defs, decls, givenTagEnv, givenFieldNames, transform<Expr>, transformIn<Expr>, substituted<StructPatternList>, substitutions;
flowtype StructPatternList = decorate {env, givenTagEnv, givenFieldNames, returnType}, pps {}, decls {decorate}, errors {decorate}, defs {decorate}, substituted {substitutions};

abstract production consStructPattern
top::StructPatternList ::= p::StructPattern rest::StructPatternList
{
  propagate substituted;
  top.pps = p.pp :: rest.pps;
  top.errors := p.errors ++ rest.errors;
  top.defs := p.defs ++ rest.defs;
  top.decls = p.decls ++ rest.decls;
  
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
  propagate substituted;
  top.pps = [];
  top.errors := [];
  top.defs := [];
  top.decls = [];
  top.transform = mkIntConst(1, builtin);
}

nonterminal StructPattern with location, pp, errors, defs, decls, givenTagEnv, givenFieldNames, remainingFieldNames, transform<Expr>, transformIn<Expr>, env, returnType, substituted<StructPattern>, substitutions;
flowtype StructPattern = decorate {env, givenTagEnv, givenFieldNames, returnType}, pp {}, decls {decorate}, errors {decorate}, defs {decorate}, substituted {substitutions};

abstract production positionalStructPattern
top::StructPattern ::= p::Pattern
{
  propagate substituted;
  top.pp = p.pp;
  -- TODO: Interfering, fix this
  top.remainingFieldNames =
    case top.givenFieldNames of
    | t :: ts -> ts
    | [] -> []
    end;
  top.errors := 
    if null(top.givenFieldNames)
    then [err(top.location, "Too many positional field patterns")]
    else forward.errors;
  forwards to namedStructPattern(name(head(top.givenFieldNames), location=builtin), p, location=top.location);
}

abstract production namedStructPattern
top::StructPattern ::= n::Name p::Pattern
{
  propagate substituted;
  top.pp = pp".${n.pp} = ${p.pp}";
  local valueItems :: [ValueItem] = lookupValue(n.name, top.givenTagEnv);
  top.errors := p.errors;
  top.errors <-
    if !null(n.valueLookupCheck)
    then [err(n.location, s"Unexpected named field ${n.name}")]
    else [];
  top.defs := p.defs;
  top.decls = p.decls;
  top.remainingFieldNames = top.givenFieldNames;
  
  n.env = top.givenTagEnv;
  p.expectedType = n.valueItem.typerep;
  
  p.transformIn = memberExpr(top.transformIn, false, n, location=builtin);
  top.transform = p.transform;
}