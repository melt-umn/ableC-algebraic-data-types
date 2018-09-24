grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax ;

synthesized attribute asParameters :: Parameters;
synthesized attribute asStructItemList :: StructItemList;
synthesized attribute asAssignments :: Stmt;
synthesized attribute len :: Integer;
inherited attribute position :: Integer;
autocopy attribute name_i :: String;

attribute asParameters, asStructItemList, asAssignments, len, position, name_i
  occurs on TypeNames ;

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
  rest.position = 1 + top.position ;

  local bty::BaseTypeExpr =
    case t of
    | typeName(bty,_) -> bty
    end ;

  local mty::TypeModifierExpr =
    case t of
    | typeName(_,mty) -> mty
    end ;

  top.asParameters =
    consParameters(
      parameterDecl(
        [], bty, mty,
        justName(name("f"++toString(top.position),
          location=builtin)), 
        nilAttribute()),
      rest.asParameters) ;

  top.asStructItemList =
    consStructItem(
      structItem(nilAttribute(),
        bty,
        consStructDeclarator(
          structField(
            name("f"++toString(top.position),location=builtin),
            mty,
            nilAttribute()),
          nilStructDeclarator())),
      rest.asStructItemList) ;

  top.asAssignments =
    seqStmt(
      exprStmt(
        eqExpr(
          memberExpr(
            memberExpr(
              memberExpr(
                declRefExpr(
                  name("temp",location=builtin),location=builtin),
                true,
                name("contents",location=builtin),location=builtin),
              false,
              name(top.name_i,location=builtin),location=builtin),
            false,
            name("f"++toString(top.position),location=builtin),location=builtin),
          declRefExpr(
            name("f"++toString(top.position),location=builtin),location=builtin),location=builtin)),
      rest.asAssignments);

  top.len = rest.len + 1;
}
