grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- ADT Patterns --
-------------------
abstract production constructorPattern
top::Pattern ::= n::Name ps::PatternList
{
  top.pp = cat( n.pp, parens( ppImplode(text(","), ps.pps) ) );
  
  -- Type checking
  local adtName::Maybe<String> = top.expectedType.adtName;
  
  local adtLookup::[RefIdItem] =
    case top.expectedType.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local constructors::[Pair<String Decorated Parameters>] =
    case adtLookup of
    | item :: _ -> item.constructors
    | [] -> []
    end;
  
  local constructorParamLookup::Maybe<Decorated Parameters> = lookup(n.name, constructors);
  
  top.errors <-
    case top.expectedType, adtName, adtLookup, constructorParamLookup of
    | errorType(), _, _, _ -> []
    -- Check that expected type for this pattern is an ADT of some sort
    | t, nothing(), _, _ -> [err(top.location, s"Constructor pattern expected to match a datatype (got ${showType(t)}).")]
    -- Check that this ADT has a definition
    | _, just(id), [], _ -> [err(top.location, s"datatype ${id} does not have a definition.")]
    -- Check that this pattern is a constructor for the expected ADT type.
    | t, _, _, nothing() -> [err(top.location, s"${showType(t)} does not have constructor ${n.name}.")]
    | _, _, _, just(params) ->
      -- Check that the number of patterns matches number of parameters for this constructor.
      if ps.count != params.count
      then [err(top.location, s"This pattern has ${toString(ps.count)} arguments, but ${toString(params.count)} were expected.")]
      else []
    end;
  
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
    case constructorParamLookup of
    | just(params) ->
      do (bindList, returnList) {
        fieldName::String <- params.fieldNames;
        return ableC_Expr { $Expr{top.transformIn}.contents.$Name{n}.$name{fieldName} };
      }
    -- An error has occured, don't translate the field access to avoid creating additional errors
    | nothing() -> [errorExpr(top.errors, location=builtin)]
    end;
}
