grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax ;

synthesized attribute asParameters :: Parameters;
synthesized attribute asStructItemList :: StructItemList;
synthesized attribute asAssignments :: Stmt;
synthesized attribute len :: Integer;
inherited attribute position :: Integer;
autocopy attribute constructorName :: String;

attribute asParameters, asStructItemList, asAssignments, len, position, constructorName
  occurs on TypeNames;

aspect production nilTypeName
top::TypeNames ::= 
{ 
  top.asParameters = nilParameters();
  top.asStructItemList = nilStructItem();
  top.asAssignments = nullStmt();
  top.len = 0;
}

aspect production consTypeName
top::TypeNames ::= t::TypeName rest::TypeNames
{
  rest.position = 1 + top.position;
  
  production fieldName::String = "f" ++ toString(top.position);
  
  top.asParameters =
    consParameters(
      parameterDecl(
        [], t.bty, t.mty,
        justName(name(fieldName, location=builtin)), 
        nilAttribute()),
      rest.asParameters);
  
  top.asStructItemList =
    consStructItem(
      structItem(
        nilAttribute(),
        t.bty,
        consStructDeclarator(
          structField(name(fieldName, location=builtin), t.mty, nilAttribute()),
          nilStructDeclarator())),
      rest.asStructItemList);
  
  top.asAssignments =
    ableC_Stmt {
      result.contents.$name{top.constructorName}.$name{fieldName} = $name{fieldName};
      $Stmt{rest.asAssignments}
    };

  top.len = rest.len + 1;
}
