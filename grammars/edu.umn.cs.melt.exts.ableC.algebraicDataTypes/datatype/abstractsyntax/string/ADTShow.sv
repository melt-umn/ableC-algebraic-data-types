grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:substitution;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:string:abstractsyntax with showErrors as strShowErrors;

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  top.strShowErrors =
    \ l::Location env::Decorated Env ->
      checkStringHeaderDef("concat_string", l, env) ++
      case lookupRefId(refId, globalEnv(env)) of
      | adtRefIdItem(adt) :: _ -> adt.showErrors(l, env)
      | _ -> [err(l, s"datatype ${adtName} does not have a (global) definition.")]
      end;
  top.showProd = showADT(_, location=builtin);
}

abstract production showADT
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"show(${e.pp})";
  
  local adtLookup::[RefIdItem] =
    case e.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local decl::Decorated ADTDecl =
    case adtLookup of
    | adtRefIdItem(decl) :: _ -> decl
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(decl.showFnName, decls(decl.showTransform))]),
      ableC_Expr { $name{decl.showFnName}($Expr{e}) },
      location=builtin);
}

-- Can't use the attributes from the string extension here to avoid orphaned occurs
synthesized attribute showErrors::([Message] ::= Location Decorated Env);
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
  top.showErrors =
    \ l::Location env::Decorated Env ->
      if null(lookupValue(top.showFnName, env))
      then
        case cs.showErrors(top.location, addEnv([valueDef(top.showFnName, errorValueItem())], env)) of
        | [] -> []
        | m -> [nested(l, s"In showing datatype ${top.adtGivenName}", m)]
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

attribute showErrors occurs on ConstructorList, Constructor, Parameters, ParameterDecl;
attribute showTransform<Stmt> occurs on ConstructorList, Constructor, Parameters, ParameterDecl;
inherited attribute showTransformIn::Stmt occurs on ConstructorList, Constructor;
flowtype showTransform {decorate, showTransformIn} on ConstructorList, Constructor;
flowtype showTransform {decorate, constructorName} on Parameters, ParameterDecl;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.showErrors =
    \ l::Location env::Decorated Env -> c.showErrors(l, env) ++ cl.showErrors(l, env);
  top.showTransform = c.showTransform;
  c.showTransformIn = cl.showTransform;
  cl.showTransformIn = top.showTransformIn;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.showErrors = \ l::Location env::Decorated Env -> [];
  top.showTransform = top.showTransformIn;
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.showErrors = ps.showErrors;
  top.showTransform =
    ableC_Stmt {
      if (adt.tag == $name{enumItemName}) {
        string result = str($stringLiteralExpr{n.name ++ "("});
        $Stmt{ps.showTransform}
        return result + ")";
      } else {
        $Stmt{top.showTransformIn}
      }
    };
}

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.showErrors =
    \ l::Location env::Decorated Env -> h.showErrors(l, env) ++ t.showErrors(l, env);
  top.showTransform = seqStmt(h.showTransform, t.showTransform);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.showErrors = \ l::Location env::Decorated Env -> [];
  top.showTransform = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  top.showErrors =
    \ Location env::Decorated Env -> top.typerep.strShowErrors(top.sourceLocation, env);
  local showField::Expr =
    showExpr(
      parenExpr(
        ableC_Expr { adt.contents.$name{top.constructorName}.$Name{fieldName} },
        location=top.sourceLocation),
      location=top.sourceLocation);
  top.showTransform =
    if top.position == 0
    then ableC_Stmt { result += $Expr{showField}; }
    else ableC_Stmt { result += ", " + $Expr{showField}; };
}
