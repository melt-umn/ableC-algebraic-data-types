grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  adtProtos <- consDecl(constructProto, consDecl(destructProto, nilDecl()));
  
  adtDecls <- consDecl(constructDecl, consDecl(destructDecl, nilDecl()));
  
  local constructProto::Decl =
    variableDecls(
      [], [],
      directTypeExpr(builtinType([], voidType())),
      consDeclarator(
        declarator(
          name("_construct" ++ n.name, location=builtIn()),
          functionTypeExprWithArgs(
            pointerTypeExpr([], baseTypeExpr()),
            consParameters(
              parameterDecl(
                [],
                directTypeExpr(builtinType([], voidType())),
                pointerTypeExpr([], pointerTypeExpr([], baseTypeExpr())),
                justName(name("_contents", location=builtIn())),
                []),
              consParameters(
                parameterDecl(
                  [],
                  directTypeExpr(builtinType([], voidType())),
                  pointerTypeExpr([], baseTypeExpr()),
                  justName(name("_expr", location=builtIn())),
                  []),
                nilParameters())),
            false),
          [],
          nothingInitializer()),
        nilDeclarator()));
  
  local constructDecl::Decl =
    functionDeclaration(
      functionDecl(
        [], [],
        directTypeExpr(builtinType([], voidType())),
        functionTypeExprWithArgs(
          pointerTypeExpr([], baseTypeExpr()),
          consParameters(
            parameterDecl(
              [],
              directTypeExpr(builtinType([], voidType())),
              pointerTypeExpr([], pointerTypeExpr([], baseTypeExpr())),
              justName(name("_contents", location=builtIn())),
              []),
            consParameters(
              parameterDecl(
                [],
                directTypeExpr(builtinType([], voidType())),
                pointerTypeExpr([], baseTypeExpr()),
                justName(name("_expr", location=builtIn())),
                []),
              nilParameters())),
          false),
        name("_construct" ++ n.name, location=builtIn()),
        [],
        nilDecl(),
        matchStmt(
          explicitCastExpr(
            typeName(
              typedefTypeExpr([], n),
              pointerTypeExpr([], baseTypeExpr())),
            declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
            location=builtIn()),
          cs.constructStmtClausesTrans)));
  
  local destructProto::Decl =
    variableDecls(
      [], [],
      directTypeExpr(builtinType([], signedType(intType()))),
      consDeclarator(
        declarator(
          name("_destruct" ++ n.name, location=builtIn()),
          functionTypeExprWithArgs(
            baseTypeExpr(),
            consParameters(
              parameterDecl(
                [],
                directTypeExpr(builtinType([], voidType())),
                pointerTypeExpr([], pointerTypeExpr([], baseTypeExpr())),
                justName(name("_contents", location=builtIn())),
                []),
              consParameters(
                parameterDecl(
                  [],
                  directTypeExpr(builtinType([], voidType())),
                  pointerTypeExpr([], baseTypeExpr()),
                  justName(name("_expr", location=builtIn())),
                  []),
                nilParameters())),
            false),
          [],
          nothingInitializer()),
        nilDeclarator()));
  
  local destructDecl::Decl =
    functionDeclaration(
      functionDecl(
        [], [],
        directTypeExpr(builtinType([], signedType(intType()))),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          consParameters(
            parameterDecl(
              [],
              directTypeExpr(builtinType([], voidType())),
              pointerTypeExpr([], pointerTypeExpr([], baseTypeExpr())),
              justName(name("_contents", location=builtIn())),
              []),
            consParameters(
              parameterDecl(
                [],
                directTypeExpr(builtinType([], voidType())),
                pointerTypeExpr([], baseTypeExpr()),
                justName(name("_expr", location=builtIn())),
                []),
              nilParameters())),
          false),
        name("_destruct" ++ n.name, location=builtIn()),
        [],
        nilDecl(),
        matchStmt(
          explicitCastExpr(
            typeName(
              typedefTypeExpr([], n),
              pointerTypeExpr([], baseTypeExpr())),
            declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
            location=builtIn()),
          cs.destructStmtClausesTrans)));
  
  structItems <-
    consStructItem(
      structItem(
        [],
        typedefTypeExpr(
          [],
          name("ConstructFun", location=builtIn())),
        consStructDeclarator(
          structField(
            name("constructFun", location=builtIn()),
            baseTypeExpr(),
            []),
          nilStructDeclarator())),
      consStructItem(
        structItem(
          [],
          typedefTypeExpr(
            [],
            name("DestructFun", location=builtIn())),
          consStructDeclarator(
            structField(
              name("destructFun", location=builtIn()),
              baseTypeExpr(),
              []),
            nilStructDeclarator())),
      nilStructItem()));
}

synthesized attribute constructStmtClausesTrans::StmtClauses occurs on ConstructorList;
synthesized attribute destructStmtClausesTrans::StmtClauses occurs on ConstructorList;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.constructStmtClausesTrans =
    consStmtClause(c.constructStmtClauseTrans, cl.constructStmtClausesTrans, location=builtIn());
  top.destructStmtClausesTrans =
    consStmtClause(c.destructStmtClauseTrans, cl.destructStmtClausesTrans, location=builtIn());
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.constructStmtClausesTrans = failureStmtClause(location=builtIn());
  top.destructStmtClausesTrans = failureStmtClause(location=builtIn());
}

synthesized attribute constructStmtClauseTrans::StmtClause occurs on Constructor;
synthesized attribute destructStmtClauseTrans::StmtClause occurs on Constructor;

aspect production allocConstructor
top::Constructor ::= n::String tms::TypeNames allocExpr::(Expr ::= String)
{
  initStmts <- 
    exprStmt(
      binaryOpExpr(
        memberExpr(
          declRefExpr(
            name("temp",location=builtIn()), location=builtIn()),
          true,
          name("constructFun", location=builtIn()), location=builtIn()),
        assignOp(
          eqOp(location=builtIn()), location=builtIn()),
        declRefExpr(
          name("_construct" ++ top.topTypeName, location=builtIn()),
        location=builtIn()),
      location=builtIn())) :: 
    exprStmt(
      binaryOpExpr(
        memberExpr(
          declRefExpr(
            name("temp", location=builtIn()), location=builtIn()),
          true,
          name("destructFun", location=builtIn()), location=builtIn()),
        assignOp(
          eqOp(location=builtIn()), location=builtIn()), 
        declRefExpr(
          name("_destruct" ++ top.topTypeName, location=builtIn()),
        location=builtIn()),
      location=builtIn())) :: [];

  local patternTrans::Pattern =
    constructorPattern(n, tms.constructorPatternList, location=builtIn());
  
  top.constructStmtClauseTrans =
    stmtClause(
      patternTrans,
      seqStmt(
        mkIntDeclInit("_index", "0", builtIn()),
        returnStmt(
          justExpr(
            directCallExpr(
              name(n, location=builtIn()),
              tms.constructorArgList,
              location=builtIn())))),
      location=builtIn());
  top.destructStmtClauseTrans =
    stmtClause(
      patternTrans,
      foldStmt([
        mkIntDeclInit("_index", "0", builtIn()),
        tms.destructCopyTrans,
        returnStmt(
          justExpr(
            declRefExpr(
              name("_index", location=builtIn()),
              location=builtIn())))]),
      location=builtIn());
}

synthesized attribute constructorPatternList::PatternList occurs on TypeNames;
synthesized attribute constructorArgList::Exprs occurs on TypeNames;
synthesized attribute destructCopyTrans::Stmt occurs on TypeNames;

--attribute topTypeName occurs on TypeNameList;

aspect production nilTypeName
ts::TypeNames ::= 
{
  ts.constructorPatternList = nilPattern(location=builtIn());
  ts.constructorArgList = nilExpr();
  ts.destructCopyTrans = nullStmt();
}

aspect production consTypeName
ts::TypeNames ::= t::TypeName rest::TypeNames
{
  ts.constructorPatternList =
    consPattern(
      patternVariable(
        "f" ++ toString(ts.position),
        location=builtIn()),
      rest.constructorPatternList,
      location=builtIn());
  
  ts.constructorArgList =
    consExpr(
      t.typerep.packProd(
        declRefExpr(
          name("_contents", location=builtIn()),
          location=builtIn()),
        declRefExpr(
          name("f" ++ toString(ts.position), location=builtIn()),
          location=builtIn()),
        name("_index", location=builtIn())),
      rest.constructorArgList);
  
  ts.destructCopyTrans =
    seqStmt(
      t.typerep.unpackProd(
        declRefExpr(
          name("f" ++ toString(ts.position),
          location=builtIn()),
        location=builtIn()), name("_contents", location=builtIn()),
        name("_index", location=builtIn())),
      rest.destructCopyTrans);
}
