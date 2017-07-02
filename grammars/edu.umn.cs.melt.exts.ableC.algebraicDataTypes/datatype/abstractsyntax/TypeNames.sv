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
ts::TypeNames ::= 
{ 
  ts.asParameters = nilParameters();
  ts.asStructItemList = nilStructItem();
  ts.asAssignments = nullStmt();
  ts.len = 0;
}

aspect production consTypeName
ts::TypeNames ::= t::TypeName rest::TypeNames
{
  rest.position = 1 + ts.position ;

  local bty::BaseTypeExpr =
    case t of
    | typeName(bty,_) -> bty
    end ;

  local mty::TypeModifierExpr =
    case t of
    | typeName(_,mty) -> mty
    end ;

  ts.asParameters =
    consParameters(
      parameterDecl(
        [], bty, mty,
        justName(name("f"++toString(ts.position),
          location=builtIn())), 
        nilAttribute()),
      rest.asParameters) ;

  ts.asStructItemList =
    consStructItem(
      structItem(nilAttribute(),
        bty,
        consStructDeclarator(
          structField(
            name("f"++toString(ts.position),location=builtIn()),
            mty,
            nilAttribute()),
          nilStructDeclarator())),
      rest.asStructItemList) ;

  ts.asAssignments =
    seqStmt(
      exprStmt(
        binaryOpExpr(
          memberExpr(
            memberExpr(
              memberExpr(
                declRefExpr(
                  name("temp",location=builtIn()),location=builtIn()),
                true,
                name("contents",location=builtIn()),location=builtIn()),
              false,
              name(ts.name_i,location=builtIn()),location=builtIn()),
            false,
            name("f"++toString(ts.position),location=builtIn()),location=builtIn()),
          assignOp(
            eqOp(location=builtIn()),location=builtIn()),
          declRefExpr(
            name("f"++toString(ts.position),location=builtIn()),location=builtIn()),location=builtIn())),
      rest.asAssignments);

  ts.len = rest.len + 1;
}
