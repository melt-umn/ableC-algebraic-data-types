grammar edu:umn:cs:melt:exts:ableC:algDataTypes:vectorrewrite;

aspect production vectorType
top::Type ::= qs::[Qualifier] sub::Type
{
  top.constructProd =
    \src::Name ref::Name index::Name ->
      stmtExpr(
        foldStmt([
          mkDecl(
            "new_vec", top,
            constructVector(
              typeName(
                directTypeExpr(top),
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
                  declRefExpr(
                    name("new_vec", location=builtIn()),
                    location=builtIn()),
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
                arraySubscriptExpr(
                  declRefExpr(src, location=builtIn()),
                  unaryOpExpr(
                    postIncOp(location=builtIn()),
                    declRefExpr(index, location=builtIn()),
                    location=builtIn()),
                  location=builtIn()),
                location=builtIn())))]),
        declRefExpr(
          name("new_vec", location=builtIn()),
          location=builtIn()),
        location=builtIn());
  top.destructProd =
    \src::Name dst::Name index::Name ->
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
                  declRefExpr(src, location=builtIn()),
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
              binaryOpExpr(
                arraySubscriptExpr(
                  declRefExpr(dst, location=builtIn()),
                  unaryOpExpr(
                    postIncOp(location=builtIn()),
                    declRefExpr(index, location=builtIn()),
                    location=builtIn()),
                  location=builtIn()),
                assignOp(eqOp(location=builtIn()), location=builtIn()),
                subscriptVector(
                  declRefExpr(src, location=builtIn()),
                  declRefExpr(
                    name("i", location=builtIn()),
                    location=builtIn()),
                  location=builtIn()),
                location=builtIn()))));
}