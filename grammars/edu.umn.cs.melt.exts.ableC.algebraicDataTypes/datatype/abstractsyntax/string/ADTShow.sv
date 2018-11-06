grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string;

imports core:monad;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:substitution;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:string:abstractsyntax;

abstract production showADT
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"show(${e.pp})";
  
  local adtName::Maybe<String> =
    case e.typerep of
    | extType( _, adtExtType(n, _, _)) -> just(n)
    | _ -> nothing()
    end;
  
  local adtDeclName::Maybe<String> =
    case e.typerep of
    | extType( _, adtExtType(_, n, _)) -> just(n)
    | _ -> nothing()
    end;
  
  local adtLookup::[RefIdItem] =
    case e.typerep of
    | extType( _, e) ->
      case e.maybeRefId of
      | just(rid) -> lookupRefId(rid, top.env)
      | nothing() -> []
      end
    | _ -> []
    end;
  
  local constructors::[Pair<String Decorated Parameters>] =
    case adtLookup of
    | item :: _ -> item.constructors
    | [] -> []
    end;
  
  local localErrors::[Message] =
    case e.typerep, adtName, adtLookup of
    | errorType(), _, _ -> []
    -- Check that parameter type is an ADT of some sort
    | t, nothing(), _ -> [err(top.location, s"show expected a datatype (got ${showType(t)}).")]
    -- Check that this ADT has a definition
    | _, just(id), [] -> [err(top.location, s"datatype ${id} does not have a definition.")]
    | _, just(id), _ ->
      do (bindList, returnList) {
        constructor::Pair<String Decorated Parameters> <- constructors;
        field::Pair<String Type> <- zipWith(pair, constructor.snd.fieldNames, constructor.snd.typereps);
        if field.snd.showProd.isJust
        then []
        else [err(e.location, s"Cannot show datatype ${id} because show of type ${showType(field.snd)} (constructor ${constructor.fst}, field ${field.fst}) is not defined.")];
      }
    end ++
    checkStringHeaderDef("str_char_pointer", top.location, top.env);
  local fwrd::Expr =
    directCallExpr(
      name("show_" ++ adtDeclName.fromJust, location=builtin),
      consExpr(e, nilExpr()),
      location=builtin);
  forwards to mkErrorCheck(localErrors, fwrd);
}

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  top.showProd = just(showADT(_, location=_));
}

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  adtDecls <-
    if null(lookupTag("_string_s", top.env)) then nilDecl() else
      ableC_Decls {
        static string $name{"show_" ++ n.name}($BaseTypeExpr{adtTypeExpr} adt);
        static string $name{"show_" ++ n.name}($BaseTypeExpr{adtTypeExpr} adt) {
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

synthesized attribute showTransform::Stmt occurs on ConstructorList, Constructor, Parameters, ParameterDecl;
inherited attribute showTransformIn::Stmt occurs on ConstructorList, Constructor;

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
  top.showTransform =
    if mty.typerep.showProd.isJust
    then
      if top.position == 0
      then ableC_Stmt { result += show(adt.contents.$name{top.constructorName}.$Name{fieldName}); }
      else ableC_Stmt { result += ", " + show(adt.contents.$name{top.constructorName}.$Name{fieldName}); }
    else nullStmt(); -- Avoid errors in implicitly-generated code
}
