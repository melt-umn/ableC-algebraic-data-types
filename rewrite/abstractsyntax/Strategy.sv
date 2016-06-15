grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
--imports edu:umn:cs:melt:ableC:abstractsyntax:debug;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax hiding transform;

abstract production strategyDecl
top::Decl ::= n::Name extends::Expr visits::VisitList
{
  -- TODO: pp
  
  local localErrors::[Message] = visits.errors ++
    (if top.isTopLevel
     then [err(n.location, "Nonparameterized strategies can't occur at the global scope")]
     else []);

  -- TODO
  top.errors :=
    if !null(localErrors)
    then localErrors
    else forward.errors;
  
  top.errors <- 
    (if !null(lookupValue("strategy", top.env)) then [] else
      [err(n.location, "Rewrite strategies require rewrite.xh to be included.")]);
  
  visits.extendsExpr = extends;
  
  forwards to
    variableDecls(
      [], [],
      typedefTypeExpr([], name("strategy", location=builtIn())),
      consDeclarator( 
        declarator(
          n,
          baseTypeExpr(),
          [], 
          justInitializer(
            exprInitializer(
              directCallExpr(
                name("_rule", location=builtIn()),
                consExpr(
                  visits.transform,
                  consExpr(
                    stringLiteral("\"" ++ n.name ++ "\"", location=builtIn()),
                    nilExpr())),
                location=builtIn())))),
        nilDeclarator()));
}

abstract production strategyDeclParams
top::Decl ::= n::Name params::Parameters extends::Expr visits::VisitList
{
  -- TODO: pp

  -- TODO
  top.errors :=
    if !null(visits.errors)
    then visits.errors
    else forward.errors;
  
  top.errors <- 
    (if !null(lookupValue("strategy", top.env)) then [] else
      [err(n.location, "Rewrite strategies require rewrite.xh to be included.")]);
  
  visits.env = addEnv(params.defs ++ protoDecl.defs, top.env);
  visits.extendsExpr = extends;
  
  -- Decorate this to get the def for the function which then goes in the visits env
  local protoDecl::Decl =
    variableDecls(
      if top.isTopLevel then [staticStorageClass()] else [autoStorageClass()],
      [],
      typedefTypeExpr([], name("strategy", location=builtIn())),
      consDeclarator(
        declarator(
          n,
          functionTypeExprWithArgs(
            baseTypeExpr(),
            params,
            false),
          [],
          nothingInitializer()),
        nilDeclarator()));
  protoDecl.env = top.env;
  protoDecl.isTopLevel = top.isTopLevel;
  protoDecl.returnType = top.returnType;
  
  local fnDecl::Decl =
    functionDeclaration(
      (if top.isTopLevel then functionDecl else nestedFunctionDecl)( -- TODO, this shouldn't be needed to solve scoping problems
        [],
        [],
        typedefTypeExpr([], name("strategy", location=builtIn())),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          params,
          false),
        n,
        [],
        nilDecl(),
        returnStmt(
          justExpr(
            directCallExpr(
              name("_rule", location=builtIn()),
              consExpr(
                visits.transform,
                consExpr(
                  stringLiteral("\"" ++ n.name ++ "\"", location=builtIn()),
                  nilExpr())),
            location=builtIn())))));
  
  forwards to
    decls(
      (if top.isTopLevel then consGlobalDecl else consDecl)(
        protoDecl,
        (if top.isTopLevel then consGlobalDecl else consDecl)(
          fnDecl,
          nilDecl())));
}

global failStrategy::Expr = 
  directCallExpr(
    name("fail", location=builtIn()),
    nilExpr(),
    location=builtIn());

global identityStrategy::Expr = 
  directCallExpr(
    name("identity", location=builtIn()),
    nilExpr(),
    location=builtIn());

nonterminal VisitList with errors, env, transform<Expr>, returnType;
inherited attribute extendsExpr :: Expr occurs on VisitList;
synthesized attribute seqTransform::Expr occurs on VisitList;
synthesized attribute exprsTransform::Exprs occurs on VisitList;

abstract production consVisitList
top::VisitList ::= visit::Visit rest::VisitList
{
  top.errors := visit.errors ++ rest.errors;
  
  rest.extendsExpr = top.extendsExpr;
  
  top.transform =
    directCallExpr(
      name("choice", location=builtIn()),
      consExpr(
        visit.transform,
        consExpr(
          rest.transform,
          nilExpr())),
      location=builtIn());
  
  top.seqTransform =
    directCallExpr(
      name("sequence", location=builtIn()),
      consExpr(
        visit.transform,
        consExpr(
          rest.seqTransform,
          nilExpr())),
      location=builtIn());
  
  top.exprsTransform = consExpr(visit.transform, rest.exprsTransform);
}

abstract production nilVisitList
top::VisitList ::=
{
  top.errors := [];
  top.transform = top.extendsExpr;
  top.seqTransform = identityStrategy;
  top.exprsTransform = nilExpr();
}

nonterminal Visit with location, errors, env, transform<Expr>, returnType;

abstract production strategyVisit
top::Visit ::= e::Expr
{
  top.errors := e.errors;
  top.errors <-
    case e.typerep of
    | noncanonicalType(typedefType(_, "strategy", _)) -> []
    | errorType() -> []
    | _ -> [err(e.location,
                "Strategy visit expression does not have strategy type (got " ++
                showType(e.typerep) ++ ")")]
    end;
  
  top.transform = e;
}

abstract production strategyVisitParams
top::Visit ::= e::Expr params::VisitList
{
  top.errors := transform.errors;
  top.transform = callExpr(e, params.exprsTransform, location=top.location);
  
  local transform::Expr = top.transform;
  transform.env = top.env;
  transform.returnType = top.returnType;
  
  top.errors <-
    case transform.typerep of
    | functionType(noncanonicalType(typedefType(_, "strategy", _)), _) -> []
    | errorType() -> []
    | _ -> [err(e.location,
                "Strategy visit expression result does not have strategy type (got " ++
                showType(e.typerep) ++ ")")]
    end;
  
}

abstract production ruleVisit
top::Visit ::= type::TypeName cs::ExprClauses
{
  top.errors := type.errors ++ cs.errors;
  
  cs.expectedType = type.typerep;
  
  top.transform =
    strategyExpr(
      type,
      failStrategy,
      cs,
      location=loc("Built In", 0, 0, 0, 0, top.location.index, 0));--TODO
}

abstract production choiceVisit
top::Visit ::= visits::VisitList
{
  top.errors := visits.errors;
  top.transform = visits.transform;
  visits.extendsExpr = failStrategy;
}

abstract production sequenceVisit
top::Visit ::= visits::VisitList
{
  top.errors := visits.errors;
  top.transform = visits.seqTransform;
}

abstract production idVisit
top::Visit ::= n::Name
{
  forwards to
    case n.name of
      "fail" -> strategyVisit(failStrategy, location=builtIn())
    | "identity" -> strategyVisit(identityStrategy, location=builtIn())
    | _ -> strategyVisit(declRefExpr(n, location=builtIn()), location=top.location)
    end;
}

abstract production idVisitParams
top::Visit ::= n::Name args::VisitList
{
  forwards to
    case n.name of
      "choice" -> choiceVisit(args, location=top.location)
    | "sequence" -> sequenceVisit(args, location=top.location)
    | _ -> strategyVisit(directCallExpr(n, args.exprsTransform, location=builtIn()), location=top.location)
    end;
}

abstract production printVisit
top::Visit ::= args::Exprs
{
  top.errors := args.errors;
  top.transform =
    lambdaExpr(
      exprFreeVariables(),
      consParameters(
        parameterDecl(
          [],
          directTypeExpr(builtinType([], voidType())),
          pointerTypeExpr([], baseTypeExpr()),
          justName(name("term", location=builtIn())),
          []),
        nilParameters()),
      stmtExpr(
        exprStmt(
          directCallExpr(name("printf", location=builtIn()), args, location=builtIn())),
        declRefExpr(name("term", location=builtIn()), location=builtIn()),
        location=builtIn()),
      location=top.location);
}

abstract production condVisit
top::Visit ::= c::Expr th::Visit el::Visit
{
  top.errors := c.errors ++ th.errors ++ el.errors;
  top.transform = conditionalExpr(c, th.transform, el.transform, location=top.location);
  
  top.errors <-
    if c.typerep.defaultFunctionArrayLvalueConversion.isScalarType then []
    else [err(c.location, "Conditional visit condition must be scalar type, instead it is " ++ showType(c.typerep))];
}

abstract production recStrategyVisit
top::Visit ::= n::Name body::Visit
{
  forwards to
    strategyVisit(
      recStrategy(
        n,
        body.transform,
        location=loc("Built In", 0, 0, 0, 0, top.location.index, 0)),--TODO
      location=builtIn());
}

abstract production strategyExpr
e::Expr ::= type::TypeName base::Expr cs::ExprClauses
{
  local localErrors::[Message] = 
    (if !null(lookupValue("strategy", e.env)) then [] else
      [err(e.location, "Rewrite strategies require rewrite.xh to be included.")]) ++
    case base.typerep of
      noncanonicalType(typedefType([], "strategy", _)) -> []
    | errorType() -> []
    | _ -> [err(base.location,
                "Extended strategy does not have strategy type (got " ++
                showType(base.typerep) ++ ")")]
    end;
  
  cs.expectedType = type.typerep;
  
  local fwrd::Expr =
    lambdaExpr(
      exprFreeVariables(),
      consParameters(
        parameterDecl(
          [],
          directTypeExpr(builtinType([], voidType())),
          pointerTypeExpr([], baseTypeExpr()),
          justName(name("_expr", location=builtIn())),
          []),
        nilParameters()),
      conditionalExpr(
        binaryOpExpr(
          memberExpr(
            explicitCastExpr(
              typeName(
                tagReferenceTypeExpr(
                  [],
                  structSEU(),
                  name("_GenericDatatype", location=builtIn())),
                pointerTypeExpr([], baseTypeExpr())),
              declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
              location=builtIn()),
            true,
            name("refId", location=builtIn()),
            location=builtIn()),
          compareOp(equalsOp(location=builtIn()), location=builtIn()),
          realConstant(
            integerConstant(
              case type.typerep of
                tagType([], refIdTagType(_, _, id)) -> id
              | pointerType([], tagType([], refIdTagType(_, _, id))) -> id
              | _ -> error("struct ref id not found")
              end,
              false,
              noIntSuffix(),
              location=builtIn()),
            location=builtIn()),
          location=builtIn()),
        matchExpr(
          explicitCastExpr(
            type,
            declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
            location=builtIn()),
          addDefaultCaseExpr(
            applyStrategy(
              explicitCastExpr(
                type,
                declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
                location=builtIn()),
              base,
              location=builtIn()),
            cs),
          location=builtIn()),
        applyStrategy(
          explicitCastExpr(
            type,
            declRefExpr(name("_expr", location=builtIn()), location=builtIn()),
            location=builtIn()),
          base,
          location=builtIn()),
        location=builtIn()),
      location=builtIn());
  forwards to mkErrorCheck(localErrors, fwrd);
}

function addDefaultCaseExpr
ExprClauses ::= base::Expr cs::ExprClauses
{
  return case cs of
           consExprClause(c, cs1) ->
           consExprClause(c, addDefaultCaseExpr(base, cs1), location=cs.location)
         | oneExprClause(c) ->
           consExprClause(
             c,
             oneExprClause(
               exprClause(patternWildcard(location=builtIn()), base, location=builtIn()),
               location=cs.location),
             location=builtIn())
         end;
}

-- Not used anywhere?  
{-
function addDefaultCase
StmtClauses ::= base::Stmt cs::StmtClauses
{
  return case cs of
           consStmtClause(c, cs1) ->
           consStmtClause(c, addDefaultCase(base, cs1), location=cs.location)
         | failureStmtClause() ->
           consStmtClause(
             stmtClause(patternWildcard(location=builtIn()), base, location=builtIn()),
             failureStmtClause(location=cs.location), location=builtIn())
         end;
}
-}