grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

inherited attribute constructorName::String;
synthesized attribute fieldNames::[String];
synthesized attribute fieldName::String;
synthesized attribute asStructItemList<a>::a;
synthesized attribute asConstructorParameters<a>::a;
synthesized attribute asAssignments::Stmt;

attribute constructorName, fieldNames, asStructItemList<StructItemList>, asConstructorParameters<Parameters>, asAssignments occurs on Parameters;
attribute constructorName, fieldName, asStructItemList<StructItem>, asConstructorParameters<ParameterDecl>, asAssignments occurs on ParameterDecl;

flowtype Parameters = fieldNames {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};
flowtype ParameterDecl = fieldName {decorate}, asStructItemList {decorate}, asConstructorParameters {decorate}, asAssignments {decorate, constructorName};

propagate constructorName on Parameters;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.fieldNames = h.fieldName :: t.fieldNames;
  top.asStructItemList = consStructItem(h.asStructItemList, t.asStructItemList);
  top.asConstructorParameters = consParameters(h.asConstructorParameters, t.asConstructorParameters);
  top.asAssignments = seqStmt(h.asAssignments, t.asAssignments);
}

aspect production nilParameters
top::Parameters ::= 
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.fieldNames = [];
  top.asStructItemList = nilStructItem();
  top.asConstructorParameters = nilParameters();
  top.asAssignments = nullStmt();
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  attachNote extensionGenerated("ableC-algebraic-data-types");
  nondecorated production fieldName::Name =
    case n of
    | justName(n) -> ^n
    | nothingName() -> name("f" ++ toString(top.position))
    end;
  top.fieldName = fieldName.name;
  
  top.asStructItemList =
    structItem(
      nilAttribute(), ^bty,
      consStructDeclarator(structField(fieldName, ^mty, nilAttribute()), nilStructDeclarator()));
  
  top.asConstructorParameters =
    parameterDecl(^storage, directTypeExpr(mty.typerep), baseTypeExpr(), justName(fieldName), ^attrs);
  
  top.asAssignments =
    ableC_Stmt {
      result.contents.$name{top.constructorName}.$Name{fieldName} = $Name{fieldName};
    };
}
