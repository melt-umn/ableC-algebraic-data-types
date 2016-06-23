grammar edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:show;

imports silver:langutil;

aspect production adtTagType
top::Type ::= name::String adtRefId::String structRefId::String
{
  top.pointerShowProd = just(showAdt(name, _, location=_));
}

abstract production showAdt
top::Expr ::= n::String e::Expr
{
  local fnName::String = "show" ++ n;
  
  local localErrors::[Message] =
    if null(lookupValue(fnName, top.env))
    then [err(top.location, "Cannot check equality for datatypes lacking a definition")]
    else [];
  
  local fwrd::Expr =
    directCallExpr(
      name(fnName, location=top.location),
      consExpr(e, nilExpr()),
      location=top.location);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}