grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- ADT Patterns --
-------------------
abstract production constructorPattern
top::Pattern ::= n::Name ps::PatternList
{
  propagate substituted;
  top.pp = cat( n.pp, parens( ppImplode(text(","), ps.pps) ) );
  ps.env = top.env;
  top.decls = ps.decls;
  top.defs := ps.defs;
  
  -- Type checking
  local adtName::Maybe<String> =
    case top.expectedType of
    | extType( _, e) -> e.adtName
    | _ -> nothing()
    end;
  
  local adtLookup::[RefIdItem] =
    case top.expectedType of
    | extType( _, e) ->
      case e.maybeRefId of
      | just(rid) -> lookupRefId(rid, top.env)
      | nothing() -> []
      end
    | _ -> []
    end;
  
  local constructors::[Pair<String Decorated Parameters>] =
    case adtLookup of
    | item :: _ -> item.constructors
    | [] -> []
    end;
  
  local constructorParamLookup::Maybe<Decorated Parameters> = lookupBy(stringEq, n.name, constructors);
  
  local localErrors::[Message] =
    case top.expectedType, adtName, adtLookup, constructorParamLookup of
    | errorType(), _, _, _ -> []
    -- Check that expected type for this pattern is an ADT of some sort
    | t, nothing(), _, _ -> [err(top.location, s"Constructor pattern expected to match a datatype (got ${showType(t)}).")]
    -- Check that this ADT has a definition
    | _, just(id), [], _ -> [err(top.location, s"datatype ${id} does not have a definition.")]
    -- Check that this pattern is a constructor for the expected ADT type.
    | t, _, _, nothing() -> [err(top.location, s"${showType(t)} does not have constructor ${n.name}.")]
    | _, _, _, just(params) ->
      -- Check that the number of patterns matches number of arguments for this constructor.
      if ps.count != params.count
      then [err(top.location, s"This pattern has ${toString(ps.count)} arguments, but ${toString(params.count)} were expected.")]
      else []
    end;
  top.errors := localErrors ++ ps.errors;
  
  ps.expectedTypes =
    case constructorParamLookup of
    | just(params) -> params.typereps
    | nothing() -> []
    end;
  
  top.transform =
    if adtName.isJust && constructorParamLookup.isJust
    then
      -- adtName ++ "_" ++ n.name is the tag name to match against
      ableC_Expr {
        $Expr{top.transformIn}.tag == $name{adtName.fromJust ++ "_" ++ n.name} && $Expr{ps.transform}
      }
    -- An error has occured, don't generate the tag check to avoid creating additional errors
    else errorExpr(top.errors, location=builtin);
  ps.transformIn =
    do (bindList, returnList) {
      fieldName::String <- constructorParamLookup.fromJust.fieldNames;
      return ableC_Expr { $Expr{top.transformIn}.contents.$Name{n}.$name{fieldName} };
    };
}
