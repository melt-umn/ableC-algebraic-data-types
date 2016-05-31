grammar edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax ;

{-
nonterminal TypeNameList with pps, env, typereps, returnType;

abstract production nilTypeName
ts::TypeNameList ::= 
{ 
  ts.pps = [];
  ts.typereps = [ ];
}
abstract production consTypeName
ts::TypeNameList ::= t::TypeName rest::TypeNameList
{
 ts.pps = t.pp :: rest.pps ;
 ts.typereps = t.typerep :: rest.typereps;
}
-}

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
        []),
      rest.asParameters) ;

  ts.asStructItemList =
    consStructItem(
      structItem([],
        bty,
        consStructDeclarator(
          structField(
            name("f"++toString(ts.position),location=builtIn()),
            mty,
            []),
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
