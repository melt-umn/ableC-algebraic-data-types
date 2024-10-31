grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:abstractsyntax;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:allocation:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:constructor:abstractsyntax as ctor;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  adtDecls <- foldDecl([defsDecl(
    map(\ c::(String, Decorated Parameters) ->
      ctor:constructorDef(c.1, adtConstructorReference(^n, name(c.1))),
      cs.constructors))
  ]);
}

production adtConstructorReference implements ctor:Constructor
top::Expr ::= args::Exprs adtName::Name constructorName::Name
{
  top.pp = pp"new ${constructorName}(${ppImplode(pp", ", args.pps)})";

  nondecorated local resName::Name = freshName("res");
  forwards to ctor:bindConstructor(@args, ableC_Expr {
    ({$BaseTypeExpr{adtTagReferenceTypeExpr(nilQualifier(), @adtName)} *$Name{resName} =
        allocate(sizeof($BaseTypeExpr{adtTagReferenceTypeExpr(nilQualifier(), ^adtName)}));
      *$Name{resName} = $Name{@constructorName}($Exprs{foldExpr(args.bindRefExprs)});
      $Name{resName};})
  });
}

