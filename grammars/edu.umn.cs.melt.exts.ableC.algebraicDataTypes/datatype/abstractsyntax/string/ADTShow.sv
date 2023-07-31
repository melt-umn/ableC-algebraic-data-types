grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:string:abstractsyntax;

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  top.showErrors =
    \ e::Decorated Expr with {env} ->
      checkStringHeaderDef("concat_string", e.env) ++
      case lookupRefId(refId, globalEnv(e.env)) of
      | adtRefIdItem(adt) :: _ -> adt.showErrors(e)
      | _ -> [errFromOrigin(e, s"datatype ${adtName} does not have a (global) definition.")]
      end;
  top.showProd = showADT;
}

abstract production showADT
top::Expr ::= e::Expr
{
  top.pp = pp"show(${e.pp})";
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
      foldDecl([maybeValueDecl(decl.showFnName, decls(decl.showTransform))]),
      ableC_Expr { $name{decl.showFnName}($Expr{e}) });
}

synthesized attribute showTransform<a>::a;

attribute showFnName occurs on ADTDecl;
attribute showErrors occurs on ADTDecl;
attribute showTransform<Decls> occurs on ADTDecl;
flowtype showFnName {decorate} on ADTDecl;
flowtype showErrors {decorate} on ADTDecl;
flowtype showTransform {decorate} on ADTDecl;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  top.showFnName = "_show_" ++ n.name;
  local checkExpr::Expr = errorExpr([]); -- Expr that gets decorated to pass the right origin and env
  top.showErrors =
    \ e::Decorated Expr with {env} ->
      if null(lookupValue(top.showFnName, e.env))
      then
        case cs.showErrors(decorate checkExpr with {env = addEnv([valueDef(top.showFnName, errorValueItem())], e.env);}) of
        | [] -> []
        | m -> [nested(getParsedOriginLocationOrFallback(e), s"In showing datatype ${top.adtGivenName}", m)]
        end
      else [];
  top.showTransform =
    ableC_Decls {
      static string $name{top.showFnName}($BaseTypeExpr{adtTypeExpr} adt);
      static string $name{top.showFnName}($BaseTypeExpr{adtTypeExpr} adt) {
        $Stmt{cs.showTransform}
      }
    };
  
  cs.showTransformIn =
    ableC_Stmt {
      char buffer[100];
      sprintf(buffer, "<datatype %s, tag %d>", $stringLiteralExpr{n.name}, adt.tag);
      return str(buffer);
    };
}

attribute showErrors occurs on ConstructorList, Constructor;
attribute showTransform<Stmt> occurs on ConstructorList, Constructor;
inherited attribute showTransformIn::Stmt occurs on ConstructorList, Constructor;
flowtype showTransform {decorate, showTransformIn} on ConstructorList, Constructor;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.showErrors =
    \ e::Decorated Expr with {env} -> c.showErrors(e) ++ cl.showErrors(e);
  top.showTransform = c.showTransform;
  c.showTransformIn = cl.showTransform;
  cl.showTransformIn = top.showTransformIn;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.showErrors = \ e::Decorated Expr with {env} -> [];
  top.showTransform = top.showTransformIn;
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.showErrors = ps.adtShowErrors;
  top.showTransform =
    ableC_Stmt {
      if (adt.tag == $name{enumItemName}) {
        string result = str($stringLiteralExpr{n.name ++ "("});
        $Stmt{ps.adtShowTransform}
        return result + ")";
      } else {
        $Stmt{top.showTransformIn}
      }
    };
}

-- Seperate attribute needed to avoid orphaned occurs
synthesized attribute adtShowErrors::([Message] ::= Decorated Expr with {env}) occurs on Parameters, ParameterDecl;
synthesized attribute adtShowTransform::Stmt occurs on Parameters, ParameterDecl;
flowtype adtShowTransform {decorate, constructorName} on Parameters, ParameterDecl;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.adtShowErrors =
    \ e::Decorated Expr with {env} -> h.adtShowErrors(e) ++ t.adtShowErrors(e);
  top.adtShowTransform = seqStmt(h.adtShowTransform, t.adtShowTransform);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.adtShowErrors = \ e::Decorated Expr with {env} -> [];
  top.adtShowTransform = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  local checkExpr::Expr = errorExpr([]); -- Expr that gets decorated to pass the right origin and env
  top.adtShowErrors =
    \ e::Decorated Expr with {env} -> showErrors(decorate checkExpr with {env = e.env;}, top.typerep);
  local showField::Expr =
    showExpr(
      parenExpr(
        ableC_Expr { adt.contents.$name{top.constructorName}.$Name{fieldName} }));
  top.adtShowTransform =
    if top.position == 0
    then ableC_Stmt { result += $Expr{showField}; }
    else ableC_Stmt { result += ", " + $Expr{showField}; };
}
