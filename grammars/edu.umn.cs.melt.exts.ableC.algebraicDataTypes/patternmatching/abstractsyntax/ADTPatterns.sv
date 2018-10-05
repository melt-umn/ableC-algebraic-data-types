grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- ADT Patterns --
-------------------
abstract production constructorPattern
top::Pattern ::= id::String ps::PatternList
{
  top.pp = cat( text(id), parens( ppImplode(text(","), ps.pps) ) );
  ps.env = top.env;
  top.decls = ps.decls;
  top.defs := ps.defs;
  
  -- Type checking
  local adtLookup::[RefIdItem] =
    case top.expectedType of
    | extType( _, e) ->
      case e.maybeRefId of
      | just(rid) -> lookupRefId(rid, top.env)
      | nothing() -> []
      end
    | _ -> []
    end;
  
  local adtName::Maybe<String> =
    case adtLookup of
    | item :: _ -> item.adtName
    | _ -> nothing()
    end;
  
  local constructors::[Pair<String Decorated Parameters>] =
    case adtLookup of
    | item :: _ -> item.constructors
    | [] -> []
    end;
  
  local constructorParamLookup::Maybe<Decorated Parameters> = lookupBy(stringEq, id, constructors);
  
  top.errors :=
    case top.expectedType, adtName, constructorParamLookup of
    -- Check that expected type for this pattern is an ADT type of some sort, with a definition.
    | errorType(), _, _ -> []
    | t, nothing(), _ -> [err(top.location, s"Constructor pattern expected to match a defined datatype (got ${showType(t)}).")]
    -- Check that this pattern is a constructor for the expected ADT type.
    | _, _, just(params) ->
      -- Check that the number of patterns matches number of arguments for this constructor.
      if ps.count != params.count
      then [err(top.location, s"This pattern has ${toString(ps.count)} arguments, but ${toString(params.count)} were expected.")]
      else []
    | _, _, nothing() -> [err(top.location, s"${showType(top.expectedType)} does not have constructor ${id}.")]
    end;
  
  ps.expectedTypes =
    case constructorParamLookup of
    | just(params) -> params.typereps
    | nothing() -> []
    end;
  
  ps.fieldNamesIn = constructorParamLookup.fromJust.fieldNames;
  
  top.transform =
    case adtName of
    | just(adtName) ->
      -- adtName ++ "_" ++ id is the tag name to match against
      ableC_Expr {
        $Expr{top.transformIn}.tag == $name{adtName ++ "_" ++ id} && $Expr{ps.transform}
      }
    -- An error has occured, don't generate the tag check to avoid creating additional errors
    | nothing() -> ps.transform
    end;
  ps.transformIn = ableC_Expr { $Expr{top.transformIn}.contents.$name{id} };
}

-- PatternList --
-----------------
inherited attribute fieldNamesIn::[String];
nonterminal PatternList with location, pps, errors, env, returnType, defs, decls, expectedTypes, fieldNamesIn, count, transform<Expr>, transformIn<Expr>;

abstract production consPattern
top::PatternList ::= p::Pattern rest::PatternList
{
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
  rest.fieldNamesIn = tail(top.fieldNamesIn);
  
  top.transform = andExpr(p.transform, rest.transform, location=builtin);
  p.transformIn =
    ableC_Expr { $Expr{top.transformIn}.$name{head(top.fieldNamesIn)} };
  rest.transformIn = top.transformIn;
}

abstract production nilPattern
top::PatternList ::= {-empty-}
{
  top.pps = [];
  top.errors := [];
  top.count = 0;
  top.defs := [];
  top.decls = [];
  top.transform = mkIntConst(1, builtin);
}


