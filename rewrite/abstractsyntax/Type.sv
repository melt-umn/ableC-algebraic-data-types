grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

-- src name, ref name, index name
synthesized attribute constructProd::(Expr ::= Name Name Name) occurs on Type;
synthesized attribute pointerConstructProd::(Expr ::= Name Name Name) occurs on Type;

-- src name, dest name, index name
synthesized attribute destructProd::(Stmt ::= Name Name Name) occurs on Type;
synthesized attribute pointerDestructProd::(Stmt ::= Name Name Name) occurs on Type;

aspect default production
top::Type ::=
{
  top.constructProd = \src::Name ref::Name index::Name -> declRefExpr(ref, location=builtIn());
  top.pointerConstructProd = \src::Name ref::Name index::Name -> declRefExpr(ref, location=builtIn());
  top.destructProd = \src::Name dst::Name index::Name -> nullStmt();
  top.pointerDestructProd = \src::Name dst::Name index::Name -> nullStmt();
}

aspect production pointerType
top::Type ::= q::[Qualifier]  target::Type
{
  top.constructProd = target.pointerConstructProd;
  top.destructProd = target.pointerDestructProd;
}

aspect production adtTagType
top::Type ::= name::String adtRefId::String structRefId::String
{
  top.pointerConstructProd =
    \src::Name ref::Name index::Name ->
      arraySubscriptExpr(
        declRefExpr(src, location=builtIn()),
        unaryOpExpr(
          postIncOp(location=builtIn()),
          declRefExpr(index, location=builtIn()),
          location=builtIn()),
        location=builtIn());
  top.pointerDestructProd =
    \src::Name dst::Name index::Name ->
      exprStmt(
        binaryOpExpr(
          arraySubscriptExpr(
            declRefExpr(dst, location=builtIn()),
            unaryOpExpr(
              postIncOp(location=builtIn()),
              declRefExpr(index, location=builtIn()),
              location=builtIn()),
            location=builtIn()),
          assignOp(eqOp(location=builtIn()), location=builtIn()),
          declRefExpr(src, location=builtIn()),
          location=builtIn()));
}