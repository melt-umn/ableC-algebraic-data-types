grammar edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:show;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:overload;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:deriving;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax;

-- Need the concrete syntax for the string extension (string type expression)
--imports edu:umn:cs:melt:exts:ableC:string;
exports edu:umn:cs:melt:exts:ableC:string;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  local showFn::Decl =
    functionDeclaration(
      functionDecl(
        [], [],
        directTypeExpr(stringType()),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          consParameters(
            parameterDecl(
              [],
              typedefTypeExpr([], n),--adtTagReferenceTypeExpr([], n),
              pointerTypeExpr([], baseTypeExpr()),
              justName(name("term", location=builtIn())),
              []),
            nilParameters()),
          false),
        name("show" ++ n.name, location=builtIn()),
        [],
        nilDecl(),
        matchStmt(
          declRefExpr(name("term", location=builtIn()), location=builtIn()),
          cs.showStmtClausesTrans)));
  
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
  local protoDecls::Decls = foldDecl(map(makeShowFnProto, childADTNames));
        
  adtDecls <-
    if null(lookupValue("show" ++ n.name, top.env))
    then appendDecls(protoDecls, consDecl(showFn, nilDecl()))
    else nilDecl();
}

function makeShowFnProto
Decl ::= n::String
{
  return
    variableDecls(
      [], [],
      directTypeExpr(builtinType([], boolType())),
      consDeclarator(
        declarator(
          name("show" ++ n, location=builtIn()),
          functionTypeExprWithArgs(
            baseTypeExpr(),
            consParameters(
              parameterDecl(
                [],
                typedefTypeExpr([], name(n, location=builtIn())),--adtTagReferenceTypeExpr([], name(n, location=builtIn())),
                pointerTypeExpr([], baseTypeExpr()),
                justName(name("term1", location=builtIn())),
                []),
              nilParameters()),
            false),
          [],
          nothingInitializer()),
        nilDeclarator()));
}

synthesized attribute showStmtClausesTrans::StmtClauses occurs on ConstructorList;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.showStmtClausesTrans =
    consStmtClause(c.showStmtClauseTrans, cl.showStmtClausesTrans, location=builtIn());
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.showStmtClausesTrans = failureStmtClause(location=builtIn());
}

synthesized attribute showStmtClauseTrans::StmtClause occurs on Constructor;

aspect production allocConstructor
top::Constructor ::= n::String tms::TypeNames allocExpr::(Expr ::= String)
{
  local patternTrans::Pattern =
    constructorPattern(n, tms.constructorPatternList, location=builtIn());
  
  top.showStmtClauseTrans =
    stmtClause(
      patternTrans,
      returnStmt(
        justExpr(
          appendString(
            stringLiteral(s"\"${n}(\"", location=builtIn()),
            appendString(
              tms.showExprTrans,
              stringLiteral("\")\"", location=builtIn()),
            location=builtIn()),
          location=builtIn()))),
      location=builtIn());
}

synthesized attribute constructorPatternList::PatternList occurs on TypeNames;
synthesized attribute showExprTrans::Expr occurs on TypeNames;

aspect production nilTypeName
ts::TypeNames ::= 
{ 
  ts.constructorPatternList = nilPattern(location=builtIn());
  ts.showExprTrans = stringLiteral("\")\"", location=builtIn());
}

aspect production consTypeName
ts::TypeNames ::= t::TypeName rest::TypeNames
{
  local isChildADT::Boolean =
    case t.typerep of
      | pointerType(_,adtTagType(n, _, _)) -> true
      | _ -> false
    end;
    
  local patternVar::String = "t" ++ toString(ts.position);

  ts.constructorPatternList =
    consPattern(
      patternVariable(
        patternVar,
        location=builtIn()),
      rest.constructorPatternList,
      location=builtIn());
  
  local showT::Expr =
    showExpr(
      declRefExpr(
        name(patternVar, location=builtIn()), -- TODO: Somehow set the location here to t.location
        location=builtIn()),
      location=builtIn());
  
  ts.showExprTrans =
    case rest of
      nilTypeName() -> showT
    | _ ->
      appendString(
        showT,
        appendString(
          stringLiteral("\", \"", location=builtIn()),
          rest.showExprTrans,
          location=builtIn()),
        location=builtIn())
    end;
}
