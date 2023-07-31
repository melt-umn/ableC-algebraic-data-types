grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

inherited attribute constructorName::String;
synthesized attribute fieldNames::[String];
synthesized attribute fieldName::String;
synthesized attribute asStructItemList<a>::a;
functor attribute asConstructorParameters;
synthesized attribute asAssignments::Stmt;

attribute constructorName, fieldNames, asStructItemList<StructItemList>, asConstructorParameters, asAssignments occurs on Parameters;
attribute constructorName, fieldName, asStructItemList<StructItem>, asConstructorParameters, asAssignments occurs on ParameterDecl;

flowtype Parameters = fieldNames {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};
flowtype ParameterDecl = fieldName {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};

propagate constructorName, asConstructorParameters on Parameters;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.fieldNames = h.fieldName :: t.fieldNames;
  top.asStructItemList = consStructItem(h.asStructItemList, t.asStructItemList);
  top.asAssignments = seqStmt(h.asAssignments, t.asAssignments);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.fieldNames = [];
  top.asStructItemList = nilStructItem();
  top.asAssignments = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  production fieldName::Name =
    case n of
    | justName(n) -> n
    | nothingName() -> name("f" ++ toString(top.position))
    end;
  top.fieldName = fieldName.name;
  
  top.asStructItemList =
    structItem(
      nilAttribute(), decTypeExpr(bty),
      consStructDeclarator(structField(fieldName, mty, nilAttribute()), nilStructDeclarator()));
  
  top.asConstructorParameters =
    parameterDecl(storage, directTypeExpr(mty.typerep), baseTypeExpr(), justName(fieldName), attrs);
  
  top.asAssignments =
    ableC_Stmt {
      result.contents.$name{top.constructorName}.$Name{fieldName} = $Name{fieldName};
    };
}
