grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:closure:abstractsyntax;

abstract production recStrategy
e::Expr ::= id::Name body::Expr
{
  e.errors <-
    (if !null(lookupValue("_rec", e.env)) then [] else
      [err(e.location, "Rewrite strategies require rewrite.xh to be included.")]);
  
  forwards to
    directCallExpr(
      name("_rec", location=builtIn()),
      consExpr(
        lambdaExpr(
          exprFreeVariables(),
          consParameters(
            parameterDecl(
              [],
              typedefTypeExpr(
                [],
                name("strategy", location=builtIn())),
              baseTypeExpr(),
              justName(id),
              []),
            nilParameters()),
          body,
          location=builtIn()),
        nilExpr()),
      location=e.location);
}