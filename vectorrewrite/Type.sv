grammar edu:umn:cs:melt:exts:ableC:algDataTypes:vectorrewrite;

aspect production vectorType
top::Type ::= qs::[Qualifier] sub::Type
{
  top.packProd = packVector(sub, _, _, _, location=builtIn());
  top.unpackProd = unpackVector(sub, _, _, _);
}