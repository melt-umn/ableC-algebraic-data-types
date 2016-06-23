grammar edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:eq;

imports silver:langutil;

aspect production adtTagType
top::Type ::= name::String adtRefId::String structRefId::String
{
  top.lPointerBinaryEqProd = just(adtEq(name, _, _, location=_));
  top.rPointerBinaryEqProd = top.lBinaryEqProd;
}

abstract production adtEq
top::Expr ::= n::String l::Expr r::Expr
{
  local fnName::String = "eq" ++ n;
  
  local localErrors::[Message] =
    case l.typerep, r.typerep of
      pointerType(_, adtTagType(name1, refId1, _)), pointerType(_, adtTagType(name2, refId2, _)) ->
        if refId1 == refId2
        then []
        else [err(top.location, s"Incompatable adt types in equality check: ${name1} and ${name2}")]
    | t1, t2 -> [err(top.location, s"Incompatable types in adt equality check: ${showType(t1)} and ${showType(t2)}")]
    end ++
    if null(lookupValue(fnName, top.env))
    then [err(top.location, "Cannot check equality for datatypes lacking a definition")]
    else [];
  
  local fwrd::Expr =
    directCallExpr(
      name(fnName, location=top.location),
      consExpr(
        l,
        consExpr(
          r,
          nilExpr())),
      location=top.location);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}