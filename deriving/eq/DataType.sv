grammar edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:eq;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:overload;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:deriving;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  local eqFn::Decl =
    functionDeclaration(
      functionDecl(
        [], [],
        directTypeExpr(builtinType([], boolType())),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          consParameters(
            parameterDecl(
              [],
              typedefTypeExpr([], n),--adtTagReferenceTypeExpr([], n),
              pointerTypeExpr([], baseTypeExpr()),
              justName(name("term1", location=builtIn())),
              []),
            consParameters(
              parameterDecl(
                [],
                typedefTypeExpr([], n),--adtTagReferenceTypeExpr([], n),
                pointerTypeExpr([], baseTypeExpr()),
                justName(name("term2", location=builtIn())),
                []),
              nilParameters())),
          false),
        name("eq" ++ n.name, location=builtIn()),
        [],
        nilDecl(),
        matchStmt(
          declRefExpr(name("term1", location=builtIn()), location=builtIn()),
          cs.eqStmtClausesTrans)));
  
  local childADTNames::[String] =
    nubBy(
      stringEq,
      foldr(
        append, [],
        map(
          \c::Pair<String [Type]> ->
            foldr(
              append, [],
              map(
                \t::Type ->
                  case t of
                    adtTagType(n, _, _) -> [n]
                  | _ -> []
                end,
                c.snd)),
          cs.constructors)));
  local protoDecls::Decls = foldDecl(map(makeEqFnProto, childADTNames));
        
  adtDecls <-
    if null(lookupValue("eq" ++ n.name, top.env))
    then appendDecls(protoDecls, consDecl(eqFn, nilDecl()))
    else nilDecl();
}

function makeEqFnProto
Decl ::= n::String
{
  return
    variableDecls(
      [], [],
      directTypeExpr(builtinType([], boolType())),
      consDeclarator(
        declarator(
          name("eq" ++ n, location=builtIn()),
          functionTypeExprWithArgs(
            baseTypeExpr(),
            consParameters(
              parameterDecl(
                [],
                typedefTypeExpr([], name(n, location=builtIn())),--adtTagReferenceTypeExpr([], name(n, location=builtIn())),
                pointerTypeExpr([], baseTypeExpr()),
                justName(name("term1", location=builtIn())),
                []),
              consParameters(
                parameterDecl(
                  [],
                  typedefTypeExpr([], name(n, location=builtIn())),--adtTagReferenceTypeExpr([], name(n, location=builtIn())),
                  pointerTypeExpr([], baseTypeExpr()),
                  justName(name("term2", location=builtIn())),
                  []),
                nilParameters())),
            false),
          [],
          nothingInitializer()),
        nilDeclarator()));
}

synthesized attribute eqStmtClausesTrans::StmtClauses occurs on ConstructorList;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.eqStmtClausesTrans =
    consStmtClause(c.eqStmtClauseTrans, cl.eqStmtClausesTrans, location=builtIn());
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.eqStmtClausesTrans = failureStmtClause(location=builtIn());
}

synthesized attribute eqStmtClauseTrans::StmtClause occurs on Constructor;

aspect production allocConstructor
top::Constructor ::= n::String tms::TypeNames allocExpr::(Expr ::= String)
{
  local patternTrans1::Pattern =
    constructorPattern(n, tms.constructorPatternList1, location=builtIn());
  local patternTrans2::Pattern =
    constructorPattern(n, tms.constructorPatternList2, location=builtIn());
  
  top.eqStmtClauseTrans =
    stmtClause(
      patternTrans1,
      matchStmt(
        declRefExpr(name("term2", location=builtIn()), location=builtIn()),
        consStmtClause(
          stmtClause(
            patternTrans2,
            tms.eqStmtTrans,
            location=builtIn()),
          consStmtClause(
            stmtClause(
              patternWildcard(location=builtIn()),
              txtStmt("return 0;"), -- TODO
              location=builtIn()),
            failureStmtClause(location=builtIn()),
            location=builtIn()),
          location=builtIn())),
      location=builtIn());
}

synthesized attribute constructorPatternList1::PatternList occurs on TypeNames;
synthesized attribute constructorPatternList2::PatternList occurs on TypeNames;
synthesized attribute eqStmtTrans::Stmt occurs on TypeNames;

aspect production nilTypeName
ts::TypeNames ::= 
{ 
  ts.constructorPatternList1 = nilPattern(location=builtIn());
  ts.constructorPatternList2 = nilPattern(location=builtIn());
  ts.eqStmtTrans = txtStmt("return 1;"); -- TODO
}

aspect production consTypeName
ts::TypeNames ::= t::TypeName rest::TypeNames
{
  local isChildADT::Boolean =
    case t.typerep of
      | pointerType(_,adtTagType(n, _, _)) -> true
      | _ -> false
    end;
    
  local patternVar1::String = "a" ++ toString(ts.position);
  local patternVar2::String = "b" ++ toString(ts.position);

  ts.constructorPatternList1 =
    consPattern(
      patternVariable(
        patternVar1,
        location=builtIn()),
      rest.constructorPatternList1,
      location=builtIn());

  ts.constructorPatternList2 =
    consPattern(
      patternVariable(
        patternVar2,
        location=builtIn()),
      rest.constructorPatternList2,
      location=builtIn());
  
  ts.eqStmtTrans =
    ifStmt(
      binaryOpExpr(
        declRefExpr(name(patternVar1, location=builtIn()), location=builtIn()),
        compareOp(equalsOp(location=builtIn()), location=builtIn()),
        declRefExpr(name(patternVar2, location=builtIn()), location=builtIn()),
        location=builtIn()),
      rest.eqStmtTrans,
      txtStmt("return 0;")); -- TODO
}