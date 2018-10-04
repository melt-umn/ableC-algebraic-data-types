grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production patternBoth
top::Pattern ::= p1::Pattern p2::Pattern
{
  top.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  top.decls = p1.decls ++ p2.decls;
  top.defs := p1.defs ++ p2.defs;
  top.errors := p1.errors ++ p2.errors;
  
  p1.env = top.env;
  p2.env = addEnv(p1.defs, top.env);
  p1.expectedType = top.expectedType;
  p2.expectedType = top.expectedType;
  p1.transformIn = top.transformIn;
  p2.transformIn = top.transformIn;

  top.transform = andExpr(p1.transform, p2.transform, location=builtin);
}

abstract production patternNot
top::Pattern ::= p::Pattern 
{
  top.pp = cat(text("! "), p.pp);
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors; -- TODO: Exclude variable patterns
  
  p.env = top.env;
  p.expectedType = top.expectedType;

  p.transformIn = top.transformIn;
  top.transform = notExpr(p.transform, location=builtin);
}

abstract production patternWhen
top::Pattern ::= e::Expr
{
  top.pp = cat( text("when"), parens(e.pp));
  top.decls = [];
  top.defs := [];
  top.errors := e.errors;
  top.errors <-
    if !e.typerep.defaultFunctionArrayLvalueConversion.isScalarType
    then [err(e.location, "when condition must be scalar type, instead it is " ++ showType(e.typerep))]
    else [];
  
  top.transform = e;
}
