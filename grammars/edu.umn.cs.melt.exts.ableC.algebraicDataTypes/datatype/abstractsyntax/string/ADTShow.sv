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
    \ env::Decorated Env ->
      checkStringHeaderDef("concat_string", env) ++
      case lookupRefId(refId, globalEnv(env)) of
      | adtRefIdItem(adt) :: _ -> adt.showErrors(env)
      | _ -> [errFromOrigin(ambientOrigin(), s"datatype ${adtName} does not have a (global) definition.")]
      end;
  top.showProd = showADT;
}

abstract production showADT
top::Expr ::= e::Expr
{
  top.pp = pp"show(${e.pp})";
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
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.showFnName = "_show_" ++ n.name;
  top.showErrors =
    \ env::Decorated Env ->
      if null(lookupValue(top.showFnName, env))
      then
        case attachNote logicalLocationFromOrigin(top) on
            cs.showErrors(addEnv([valueDef(top.showFnName, errorValueItem())], env))
          end of
        | [] -> []
        | m -> [nested(getParsedOriginLocationOrFallback(ambientOrigin()), s"In showing datatype ${top.adtGivenName}", m)]
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
  top.showErrors = \ env::Decorated Env -> c.showErrors(env) ++ cl.showErrors(env);
  top.showTransform = c.showTransform;
  c.showTransformIn = cl.showTransform;
  cl.showTransformIn = top.showTransformIn;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.showErrors = \ _ -> [];
  top.showTransform = top.showTransformIn;
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
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
synthesized attribute adtShowErrors::([Message] ::= Decorated Env) occurs on Parameters, ParameterDecl;
synthesized attribute adtShowTransform::Stmt occurs on Parameters, ParameterDecl;
flowtype adtShowTransform {decorate, constructorName} on Parameters, ParameterDecl;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.adtShowErrors = \ env::Decorated Env -> h.adtShowErrors(env) ++ t.adtShowErrors(env);
  top.adtShowTransform = seqStmt(h.adtShowTransform, t.adtShowTransform);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.adtShowErrors = \ _ -> [];
  top.adtShowTransform = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  local checkExpr::Expr = errorExpr([]); -- Expr that gets decorated to pass the right origin and env
  top.adtShowErrors = \ env::Decorated Env ->
    attachNote logicalLocationFromOrigin(top) on showErrors(env, top.typerep) end;
  local showField::Expr =
    attachNote extensionGenerated("ableC-algebraic-data-types") on
      showExpr(
        parenExpr(
          ableC_Expr { adt.contents.$name{top.constructorName}.$Name{fieldName} }))
    end;
  top.adtShowTransform =
    attachNote extensionGenerated("ableC-algebraic-data-types") on
      if top.position == 0
      then ableC_Stmt { result += $Expr{showField}; }
      else ableC_Stmt { result += ", " + $Expr{showField}; }
    end;
}
