grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:substitution;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:string:abstractsyntax;

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  top.showProd = just(showADT(_, location=_));
}

abstract production showADT
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"show(${e.pp})";
  
  local adtName::Maybe<String> = e.typerep.adtName;
  
  local adtLookup::[RefIdItem] =
    case e.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local adt::Decorated ADTDecl =
    case adtLookup of
    | adtRefIdItem(adt) :: _ -> adt
    end;
  
  local decl::Decl = showADTDecl(adt);
  decl.env = globalEnv(top.env);
  decl.returnType = nothing();
  decl.isTopLevel = false;
  
  local localErrors::[Message] =
    case e.typerep, adtName, adtLookup of
    | errorType(), _, _ -> []
    -- Check that parameter type is an ADT of some sort
    | t, nothing(), _ -> [err(top.location, s"show expected a datatype (got ${showType(t)}).")]
    -- Check that this ADT has a definition
    | _, just(id), [] -> [err(top.location, s"datatype ${id} does not have a definition.")]
    | _, just(id), _ ->
      if !null(decl.errors)
      then [nested(e.location, s"In showing datatype ${id}", decl.errors)]
      else []
    end ++
    checkStringHeaderDef("str_char_pointer", top.location, top.env);
  local fwrd::Expr =
    injectGlobalDeclsExpr(
      consDecl(decDecl(decl), nilDecl()),
      directCallExpr(
        name(adt.showFnName, location=builtin),
        consExpr(e, nilExpr()),
        location=builtin),
      location=builtin);
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production showADTDecl
top::Decl ::= adt::Decorated ADTDecl
{
  propagate substituted;
  top.pp = pp"showADTDecl ${adt.pp}";
  forwards to
    if !null(lookupValue(adt.showFnName, top.env))
    then decls(nilDecl())
    else adt.showTransform;
}

synthesized attribute showFnName::String occurs on ADTDecl;
synthesized attribute showTransform<a>::a;
attribute showTransform<Decl> occurs on ADTDecl;
flowtype showTransform {decorate} on ADTDecl;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  top.showFnName = "_show_" ++ n.name;
  top.showTransform =
    decls(
      ableC_Decls {
        static string $name{top.showFnName}($BaseTypeExpr{adtTypeExpr} adt);
        static string $name{top.showFnName}($BaseTypeExpr{adtTypeExpr} adt) {
          $Stmt{cs.showTransform}
        }
      });
  
  cs.showTransformIn =
    ableC_Stmt {
      char buffer[100];
      sprintf(buffer, "<datatype %s, tag %d>", $stringLiteralExpr{n.name}, adt.tag);
      return str(buffer);
    };
}

attribute showTransform<Stmt> occurs on ConstructorList, Constructor, Parameters, ParameterDecl;
inherited attribute showTransformIn::Stmt occurs on ConstructorList, Constructor;
flowtype showTransform {decorate, showTransformIn} on ConstructorList, Constructor;
flowtype showTransform {decorate, constructorName} on Parameters, ParameterDecl;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.showTransform = c.showTransform;
  c.showTransformIn = cl.showTransform;
  cl.showTransformIn = top.showTransformIn;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.showTransform = top.showTransformIn;
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
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
  top.showTransform = seqStmt(h.showTransform, t.showTransform);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.showTransform = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
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
