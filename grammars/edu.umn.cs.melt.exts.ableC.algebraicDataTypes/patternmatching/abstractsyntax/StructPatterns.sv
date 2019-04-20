grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- struct/union patterns --
-------------------
abstract production structPattern
top::Pattern ::= ps::StructPatternList
{
  top.pp = braces(ppImplode(text(", "), ps.pps));
  ps.env = top.env;
  top.decls = ps.decls;
  top.patternDefs := ps.patternDefs;
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
  
  top.errors :=
    case top.expectedType, refId, refIdLookup of
    | errorType(), _, _ -> []
    -- Check that expected type for this pattern is some sort of type with fields
    | t, nothing(), _ -> [err(top.location, s"Initializer pattern expected to match a struct or union (got ${showType(t)}).")]
    -- Check that this type has a definition
    | t, just(id), [] -> [err(top.location, s"${showType(t)} does not have a definition.")]
    | _, _, _ -> ps.errors
    end;
  
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

nonterminal StructPatternList with pps, errors, env, returnType, defs, decls, patternDefs, givenTagEnv, givenFieldNames, transform<Expr>, transformIn<Expr>;
flowtype StructPatternList = decorate {env, givenTagEnv, givenFieldNames, returnType, transformIn}, pps {}, decls {decorate}, patternDefs {decorate}, errors {decorate}, defs {decorate}, transform {decorate};

abstract production consStructPattern
top::StructPatternList ::= p::StructPattern rest::StructPatternList
{
  top.pps = p.pp :: rest.pps;
  top.errors := p.errors ++ rest.errors;
  top.defs := p.defs ++ rest.defs;
  top.decls = p.decls ++ rest.decls;
  top.patternDefs := p.patternDefs ++ rest.patternDefs;
  
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
  top.errors := [];
  top.defs := [];
  top.decls = [];
  top.patternDefs := [];
  top.transform = mkIntConst(1, builtin);
}

nonterminal StructPattern with location, pp, errors, defs, decls, patternDefs, givenTagEnv, givenFieldNames, remainingFieldNames, transform<Expr>, transformIn<Expr>, env, returnType;
flowtype StructPattern = decorate {env, givenTagEnv, givenFieldNames, returnType, transformIn}, pp {}, decls {decorate}, patternDefs {decorate}, errors {decorate}, defs {decorate}, transform {decorate};

abstract production positionalStructPattern
top::StructPattern ::= p::Pattern
{
  top.pp = p.pp;
  top.errors := p.errors;
  top.defs := p.defs;
  top.decls = p.decls;
  top.patternDefs := p.patternDefs;
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
  top.errors := p.errors;
  top.errors <-
    if !null(n.valueLookupCheck)
    then [err(n.location, s"Unexpected named field ${n.name}")]
    else [];
  top.defs := p.defs;
  top.decls = p.decls;
  top.patternDefs := p.patternDefs;
  top.remainingFieldNames = top.givenFieldNames;
  
  n.env = top.givenTagEnv;
  p.expectedType = n.valueItem.typerep;
  
  p.transformIn = memberExpr(top.transformIn, false, n, location=builtin);
  top.transform = p.transform;
}
