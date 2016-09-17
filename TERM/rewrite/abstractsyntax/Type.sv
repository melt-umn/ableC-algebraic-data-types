grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

-- src expr, ref expr, index name
synthesized attribute packProd::(Expr ::= Expr Expr Name) occurs on Type;
synthesized attribute pointerPackProd::(Expr ::= Expr Expr Name) occurs on Type;

-- src expr, dest name, index name
synthesized attribute unpackProd::(Stmt ::= Expr Name Name) occurs on Type;
synthesized attribute pointerUnpackProd::(Stmt ::= Expr Name Name) occurs on Type;

aspect default production
top::Type ::=
{
  top.packProd = \src::Expr ref::Expr index::Name -> ref;
  top.pointerPackProd = \src::Expr ref::Expr index::Name -> ref;
  top.unpackProd = \src::Expr dst::Name index::Name -> nullStmt();
  top.pointerUnpackProd = \src::Expr dst::Name index::Name -> nullStmt();
}

aspect production pointerType
top::Type ::= q::[Qualifier]  target::Type
{
  top.packProd = target.pointerPackProd;
  top.unpackProd = target.pointerUnpackProd;
}

aspect production adtTagType
top::Type ::= name::String adtRefId::String structRefId::String
{
  top.pointerPackProd =
    \src::Expr ref::Expr index::Name ->
      arraySubscriptExpr(
        src,
        unaryOpExpr(
          postIncOp(location=builtIn()),
          declRefExpr(index, location=builtIn()),
          location=builtIn()),
        location=builtIn());
  top.pointerUnpackProd =
    \src::Expr dst::Name index::Name ->
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
          src,
          location=builtIn()));
}