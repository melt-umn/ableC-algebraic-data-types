grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

synthesized attribute fieldNames::[String];
synthesized attribute fieldName::String;
synthesized attribute asStructItemList<a>::a;
synthesized attribute asConstructorParameters<a>::a;
synthesized attribute asAssignments::Stmt;
autocopy attribute constructorName::String;

attribute fieldNames, asStructItemList<StructItemList>, asConstructorParameters<Parameters>, asAssignments, constructorName occurs on Parameters;
attribute fieldName, asStructItemList<StructItem>, asConstructorParameters<ParameterDecl>, asAssignments, constructorName occurs on ParameterDecl;

flowtype Parameters = fieldNames {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};
flowtype ParameterDecl = fieldName {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.fieldNames = h.fieldName :: t.fieldNames;
  top.asStructItemList = consStructItem(h.asStructItemList, t.asStructItemList);
  top.asConstructorParameters = consParameters(h.asConstructorParameters, t.asConstructorParameters);
  top.asAssignments = seqStmt(h.asAssignments, t.asAssignments);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.fieldNames = [];
  top.asStructItemList = nilStructItem();
  top.asConstructorParameters = nilParameters();
  top.asAssignments = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  production fieldName::Name =
    case n of
    | justName(n) -> n
    | nothingName() -> name("f" ++ toString(top.position), location=builtin)
    end;
  top.fieldName = fieldName.name;
  
  top.asStructItemList =
    structItem(
      nilAttribute(), bty,
      consStructDeclarator(structField(fieldName, mty, nilAttribute()), nilStructDeclarator()));
  
  top.asConstructorParameters =
    parameterDecl(storage, directTypeExpr(mty.typerep), baseTypeExpr(), justName(fieldName), attrs);
  
  top.asAssignments =
    ableC_Stmt {
      result.contents.$name{top.constructorName}.$Name{fieldName} = $Name{fieldName};
    };
}
