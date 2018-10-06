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
  ps.transformIn =
    do (bindList, returnList) {
      fieldName::String <- constructorParamLookup.fromJust.fieldNames;
      return ableC_Expr { $Expr{top.transformIn}.contents.$name{id}.$name{fieldName} };
    };
}
