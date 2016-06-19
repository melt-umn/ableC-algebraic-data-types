grammar edu:umn:cs:melt:exts:ableC:algDataTypes:vectorrewrite;

imports silver:langutil; 
imports silver:langutil:pp with implode as ppImplode;

imports edu:umn:cs:melt:ableC:abstractsyntax hiding vectorType;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:vector:abstractsyntax;

abstract production packVector
top::Expr ::= sub::Type src::Expr ref::Expr index::Name
{
  forwards to
    stmtExpr(
      foldStmt([
        mkDecl(
          "new_vec", vectorType([], sub),
          constructVector(
            typeName(
              directTypeExpr(sub),
              baseTypeExpr()),
            nilExpr(),
            location=builtIn()),
          builtIn()),
        declStmt(makeDeclIntInit("i", "0", builtIn())),
        forStmt(
          nothingExpr(),
          justExpr(
            binaryOpExpr(
              declRefExpr(
                name("i", location=builtIn()),
                location=builtIn()),
              compareOp(ltOp(location=builtIn()), location=builtIn()),
              memberExpr(
                ref,
                true,
                name("length", location=builtIn()),
              location=builtIn()),
            location=builtIn())),
          justExpr(
            unaryOpExpr(
              postIncOp(location=builtIn()),
              declRefExpr(
                name("i", location=builtIn()),
                location=builtIn()),
              location=builtIn())),
          exprStmt(
            subscriptAssignVector(
              declRefExpr(
                name("new_vec", location=builtIn()),
                location=builtIn()),
              declRefExpr(
                name("i", location=builtIn()),
                location=builtIn()),
              eqOp(location=builtIn()),
              sub.packProd(
                src,
                subscriptVector(
                  ref,
                  declRefExpr(
                    name("i", location=builtIn()),
                    location=builtIn()),
                  location=builtIn()),
                index),
              location=builtIn())))]),
      declRefExpr(
        name("new_vec", location=builtIn()),
        location=builtIn()),
      location=builtIn());
}

abstract production unpackVector
top::Stmt ::= sub::Type src::Expr dst::Name index::Name
{
  forwards to
    seqStmt(
      declStmt(makeDeclIntInit("i", "0", builtIn())),
      forStmt(
        nothingExpr(),
        justExpr(
          binaryOpExpr(
            declRefExpr(
              name("i", location=builtIn()),
              location=builtIn()),
            compareOp(ltOp(location=builtIn()), location=builtIn()),
            memberExpr(
              src,
              true,
              name("length", location=builtIn()),
            location=builtIn()),
          location=builtIn())),
        justExpr(
          unaryOpExpr(
            postIncOp(location=builtIn()),
            declRefExpr(
              name("i", location=builtIn()),
              location=builtIn()),
            location=builtIn())),
        sub.unpackProd(
          subscriptVector(
            src,
            declRefExpr(
              name("i", location=builtIn()),
              location=builtIn()),
            location=builtIn()),
          dst,
          index)));
}