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
  
  local constructorResult::Expr =
    directCallExpr(name(n, location=builtIn()), tms.constructorArgList, location=builtIn());
  
  top.constructStmtClauseTrans =
    stmtClause(patternTrans, returnStmt(justExpr(constructorResult)), location=builtIn());
  top.destructStmtClauseTrans =
    stmtClause(
      patternTrans,
      seqStmt(
        tms.destructCopyTrans,
        returnStmt(
          justExpr(
            realConstant(
              integerConstant(
                toString(tms.numChildADTs),
                false,
                noIntSuffix(),
                location=builtIn()),
              location=builtIn())))),
      location=builtIn());
--  tms.topTypeName = top.topTypeName;
  tms.childADTPosition = 0;
}

synthesized attribute constructorPatternList::PatternList occurs on TypeNames;
synthesized attribute constructorArgList::Exprs occurs on TypeNames;
synthesized attribute destructCopyTrans::Stmt occurs on TypeNames;
synthesized attribute numChildADTs::Integer occurs on TypeNames;

inherited attribute childADTPosition::Integer occurs on TypeNames;

--attribute topTypeName occurs on TypeNameList;

aspect production nilTypeName
ts::TypeNames ::= 
{ 
  ts.constructorPatternList = nilPattern(location=builtIn());
  ts.constructorArgList = nilExpr();
  ts.destructCopyTrans = nullStmt();
  ts.numChildADTs = 0;
}

aspect production consTypeName
ts::TypeNames ::= t::TypeName rest::TypeNames
{
  local isChildADT::Boolean =
    case t.typerep of
      | pointerType(_,adtTagType(n, _, _)) -> true
      | _ -> false
    end;

  ts.constructorPatternList =
    consPattern(
      patternVariable(
        "f" ++ toString(ts.position),
        location=builtIn()),
      rest.constructorPatternList,
      location=builtIn());
  
  ts.constructorArgList =
    consExpr(
      if isChildADT
      then arraySubscriptExpr(
             declRefExpr(
               name("_contents", location=builtIn()),
               location=builtIn()),
             realConstant(
               integerConstant(
                 toString(ts.childADTPosition),
                 false,
                 noIntSuffix(),
                 location=builtIn()),
               location=builtIn()),
             location=builtIn())
     else declRefExpr(
            name("f" ++ toString(ts.position), location=builtIn()),
            location=builtIn()),
      rest.constructorArgList);
  
  ts.destructCopyTrans =
    if isChildADT
    then seqStmt(
           exprStmt(
             binaryOpExpr(
               arraySubscriptExpr(
                 declRefExpr(
                   name("_contents", location=builtIn()),
                   location=builtIn()),
                 realConstant(
                   integerConstant(
                     toString(ts.childADTPosition),
                     false,
                     noIntSuffix(),
                     location=builtIn()),
                   location=builtIn()),
                 location=builtIn()),
             assignOp(eqOp(location=builtIn()), location=builtIn()),
             declRefExpr(
               name("f" ++ toString(ts.position), location=builtIn()),
               location=builtIn()),
             location=builtIn())),
           rest.destructCopyTrans)
    else rest.destructCopyTrans;
  
  ts.numChildADTs =
    if isChildADT
    then rest.numChildADTs + 1
    else rest.numChildADTs;
  
  --rest.topTypeName = ts.topTypeName;
  rest.childADTPosition =
    if isChildADT
    then ts.childADTPosition + 1
    else ts.childADTPosition;
}
