grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:string:abstractsyntax;

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  top.showErrors := \ env ->
    checkStringHeaderDef(env) ++
    case lookupRefId(refId, globalEnv(env)) of
    | adtRefIdItem(adt) :: _ -> adt.showErrors(env)
    | _ -> [errFromOrigin(ambientOrigin(), s"datatype ${adtName} does not have a (global) definition.")]
    end;
  top.showMaxLenProd = showADTMaxLen;
  top.showProd = showADT;
}

abstract production showADTMaxLen
top::Expr ::= e::Expr
{
  top.pp = pp"showAdtMaxLen(${e})";
  attachNote extensionGenerated("ableC-algebraic-data-types");
  propagate env, controlStmtContext;
  
  local adtLookup::[RefIdItem] =
    case e.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local decl::Decorated ADTDecl =
    case adtLookup of
    | adtRefIdItem(decl) :: _ -> decl
    | _ -> error("adt refId not an adtRefIdItem")
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(decl.showMaxLenFnName, decls(decl.showMaxLenFnDecls))]),
      ableC_Expr { $name{decl.showMaxLenFnName}($Expr{^e}) });
}

abstract production showADT
top::Expr ::= buf::Expr e::Expr
{
  top.pp = pp"showADT(${buf}, ${e})";
  attachNote extensionGenerated("ableC-algebraic-data-types");
  propagate env, controlStmtContext;
  
  local adtLookup::[RefIdItem] =
    case e.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local decl::Decorated ADTDecl =
    case adtLookup of
    | adtRefIdItem(decl) :: _ -> decl
    | _ -> error("adt refId not an adtRefIdItem")
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(decl.showFnName, decls(decl.showFnDecls))]),
      ableC_Expr { $name{decl.showFnName}($Expr{@buf}, $Expr{^e}) });
}

attribute showErrors, showMaxLenFnName, showFnName, showMaxLenFnDecls, showFnDecls occurs on ADTDecl;
flowtype ADTDecl =
  showErrors {decorate},
  showMaxLenFnName {decorate}, showFnName {decorate},
  showMaxLenFnDecls {decorate}, showFnDecls {decorate};

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.showErrors := \ env ->
    if null(lookupValue(top.showFnName, env))
    then
      case attachNote logicalLocationFromOrigin(top) on
          cs.adtShowErrors(addEnv([valueDef(top.showFnName, errorValueItem())], env))
        end of
      | [] -> []
      | m -> [nested(getParsedOriginLocationOrFallback(ambientOrigin()), s"In showing datatype ${top.adtGivenName}", m)]
      end
    else [];
  top.showMaxLenFnName = s"_show_${n.name}_max_len";
  top.showFnName = s"_show_${n.name}";
  top.showMaxLenFnDecls =
    ableC_Decls {
      proto_typedef size_t;
      static size_t $name{top.showMaxLenFnName}($BaseTypeExpr{adtTypeExpr});
      static size_t $name{top.showMaxLenFnName}($BaseTypeExpr{adtTypeExpr} adt) {
        return $Expr{cs.adtShowMaxLenTransform};
      }
    };
  top.showFnDecls =
    ableC_Decls {
      proto_typedef size_t;
      static size_t $name{top.showFnName}(char *, $BaseTypeExpr{adtTypeExpr});
      static size_t $name{top.showFnName}(char *buf, $BaseTypeExpr{adtTypeExpr} adt) {
        size_t bufIndex;
        $Stmt{cs.adtShowTransform}
        buf[bufIndex] = '\0';
        return bufIndex;
      }
    };

  cs.adtShowMaxLenTransformIn = mkIntConst(length(n.name) + 32);
  cs.adtShowTransformIn =
    ableC_Stmt {
      bufIndex = sprintf(buf, "<datatype %s, tag %d>", $stringLiteralExpr{n.name}, adt.tag);
    };
}

monoid attribute adtShowErrors::([Message] ::= Env);
inherited attribute adtShowMaxLenTransformIn::Expr;
synthesized attribute adtShowMaxLenTransform::Expr;
inherited attribute adtShowTransformIn::Stmt;
synthesized attribute adtShowTransform::Stmt;

attribute adtShowErrors, adtShowMaxLenTransformIn, adtShowMaxLenTransform, adtShowTransformIn, adtShowTransform
  occurs on ConstructorList, Constructor;

propagate adtShowErrors on ConstructorList, Constructor;

flowtype adtShowMaxLenTransform {decorate, adtShowMaxLenTransformIn} on ConstructorList, Constructor;
flowtype adtShowTransform {decorate, adtShowTransformIn} on ConstructorList, Constructor;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  thread adtShowMaxLenTransformIn, adtShowMaxLenTransform on top, cl, c, top;
  thread adtShowTransformIn, adtShowTransform on top, cl, c, top;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.adtShowMaxLenTransform = top.adtShowMaxLenTransformIn;
  top.adtShowTransform = top.adtShowTransformIn;
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.adtShowMaxLenTransform =
    ableC_Expr {
      adt.tag == $name{enumItemName} ?
        $intLiteralExpr{length(n.name) + 2} + $Expr{ps.constructorShowMaxLenTransform} :
        $Expr{top.adtShowMaxLenTransformIn}
    };
  top.adtShowTransform =
    ableC_Stmt {
      if (adt.tag == $name{enumItemName}) {
        strcpy(buf, $stringLiteralExpr{n.name ++ "("});
        bufIndex = $intLiteralExpr{length(n.name) + 1};
        $Stmt{foldShowItems(ps.constructorShowTransform)}
        buf[bufIndex++] = ')';
      } else {
        $Stmt{top.adtShowTransformIn}
      }
    };
}

monoid attribute constructorShowMaxLenTransform::Expr with mkIntConst(0), joinMaxLens;
monoid attribute constructorShowTransform::[Stmt];
attribute adtShowErrors, constructorShowMaxLenTransform, constructorShowTransform occurs on Parameters, ParameterDecl;
propagate adtShowErrors, constructorShowMaxLenTransform, constructorShowTransform on Parameters;

flowtype constructorShowMaxLenTransform {decorate, constructorName} on Parameters, ParameterDecl;
flowtype constructorShowTransform {decorate, constructorName} on Parameters, ParameterDecl;

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  top.adtShowErrors := \ env ->
    attachNote logicalLocationFromOrigin(top) on showErrors(env, top.typerep) end;
  top.constructorShowMaxLenTransform :=
    attachNote extensionGenerated("ableC-algebraic-data-types") on
      getShowMaxLen(
        parenExpr(ableC_Expr { adt.contents.$name{top.constructorName}.$Name{fieldName} }),
        top.env, top.typerep)
    end;
  top.constructorShowTransform :=
    attachNote extensionGenerated("ableC-algebraic-data-types") on
      [ableC_Stmt {
        bufIndex += $Expr{getShow(
          ableC_Expr { buf + bufIndex },
          parenExpr(ableC_Expr { adt.contents.$name{top.constructorName}.$Name{fieldName} }),
          top.env, top.typerep)};
      }]
    end;
}
