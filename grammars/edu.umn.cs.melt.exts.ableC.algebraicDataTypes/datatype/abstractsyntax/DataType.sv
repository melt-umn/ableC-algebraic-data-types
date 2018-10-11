grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

{- 
 - datatype Type {
 -   Unit();
 -   Arrow(Type *, Type *);
 -   Var(char *);
 -  };
 - 
 - becomes 
 - 
 - struct Type {
 -   enum { Type_Unit, Type_Arrow, Type_Var } tag;
 -   struct Contents_s {
 -     struct Type_Unit_s { } Unit ;
 -     struct Type_Arrow_s { struct Type *p1; struct Type *p2; } Arrow;
 -     struct Type_Var_s { char* p1; } Var;
 -   } contents;
 - };

 - // Constructor functions for each variant
 - static inline Type *Unit() { ... }
 - static inline Type *Arrow(...) { ... }
 - ...
 -}

abstract production datatypeDecl
top::Decl ::= adt::ADTDecl
{
  propagate substituted;
  top.pp = ppConcat([ text("datatype"), space(), adt.pp ]);
  
  forwards to
    decls(
      foldDecl([
        defsDecl(adt.defs), warnDecl(adt.errors)] ++
        if null(adt.errors) then [adt.transform] else []));
}

synthesized attribute transform<a> :: a;

nonterminal ADTDecl with location, pp, env, defs, errors, isTopLevel, returnType, name, refId, constructors, tagEnv, transform<Decl>, substituted<ADTDecl>, substitutions;
flowtype ADTDecl = decorate {isTopLevel, env, returnType};

abstract production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  propagate substituted;
  top.pp = ppConcat([ n.pp, space(), braces(cs.pp) ]);
  top.errors := cs.errors; -- TODO: check for redeclaration

  {- structs create a tagItem and a refIdItem in the environment
      < structName, adtTagItem ( SEU, RefIdAsString ) >
      < refIdAsString, structRefIdItem(decorated StructDecl) >
     The reason for this is to deal with forward declarations of structs.
     
     We have to do this for ADTs as well.
   -} 
  top.name = n.name;
  
  local preDefs :: [Def] = 
    if name_tagHasForwardDcl_workaround
    then []
    else [adtTagDef(n.name, adtRefIdTagItem(name_tagRefId_workaround))];
  local postDefs :: [Def] =
    [adtRefIdDef(name_tagRefId_workaround, adtRefIdItem(top))];
  
  top.defs := preDefs ++ cs.defs ++ postDefs;

  local name_refIdIfOld_workaround :: Maybe<String> =
    case n.tagLocalLookup of
    | adtRefIdTagItem(thisRefId) :: _ -> just(thisRefId)
    | _ -> nothing()
    end;
  local name_tagRefId_workaround :: String =
    fromMaybe(toString(genInt()), name_refIdIfOld_workaround);
  local name_tagHasForwardDcl_workaround :: Boolean =
    name_refIdIfOld_workaround.isJust;

  top.refId = name_tagRefId_workaround;
  top.constructors = cs.constructors;
  
  production structName::String = n.name ++ "_s";
  production structRefId::String = name_tagRefId_workaround ++ "_s";
  production enumName::String = n.name ++ "_tag";
  production unionName::String = "_" ++ n.name ++ "_contents";
  production unionRefId::String = name_tagRefId_workaround ++ "_contents";
  
  local transStructDecl::Decl =
    ableC_Decl {
      struct __attribute__((refId($stringLiteralExpr{structRefId}))) $name{structName} {
        enum $name{enumName} {
          $EnumItemList{
            -- Ensure we don't generate an empty enum if there are no constructors
            case cs.enumItems of
              nilEnumItem() ->
                consEnumItem(
                  enumItem(
                    name("_dummy_" ++ n.name ++ "_enum_item", location=builtin),
                    nothingExpr()),
                  nilEnumItem())
            | _ -> cs.enumItems
            end}
        } tag;
        union __attribute__((refId($stringLiteralExpr{unionRefId}))) $name{unionName} {
          $StructItemList{cs.structItems}
        } contents;
        $StructItemList{structItems}
      };
    };
  
  -- Decorate struct declaration here to compute tagEnv
  transStructDecl.env = top.env;
  transStructDecl.returnType = top.returnType;
  transStructDecl.isTopLevel = top.isTopLevel;
  
  top.tagEnv = case transStructDecl of typeExprDecl(_, structTypeExpr(_, d)) -> d.tagEnv end;
  
  {- This attribute is for extensions to use to add additional auto-generated functions
     for ADT, for example an auto-generated recursive freeing function. -}
  production attribute adtDecls::Decls with appendDecls;
  adtDecls := nilDecl();
  
  {- Used to generate prototypes for adtDecls which are inserted before the constructors -}
  production attribute adtProtos::Decls with appendDecls;
  adtProtos := nilDecl();
  
  {- This attribute is for extensions to use to add additional members to the generated
     ADT struct. -}
  production attribute structItems::StructItemList with appendStructItemList;
  structItems := nilStructItem();

  top.transform =
    decls(consDecl(transStructDecl, foldr1(appendDecls, [adtProtos, cs.funDecls, adtDecls])));
  
  cs.env = addEnv(preDefs, top.env);
  cs.topTypeName = n.name;
}

-- Constructs the enum item for each constructor
synthesized attribute enumItems :: EnumItemList;

-- Constructs the struct item for each constructor
synthesized attribute structItems :: StructItemList;

-- Constructs the initialization function for each constructor
synthesized attribute funDecls :: Decls;

-- Used to pass down the datatype's name for naming conventions
autocopy attribute topTypeName :: String;

-- Constructor list used, e.g., when type checking patterns
synthesized attribute constructors :: [Pair<String Decorated Parameters>];

nonterminal ConstructorList
  with pp, env, errors, defs, returnType, enumItems, structItems, funDecls, topTypeName, constructors,
       substituted<ConstructorList>, substitutions;

abstract production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  propagate substituted;
  local sep::Document =
    case cl of
    | consConstructor(_,_) -> line()
    | nilConstructor() -> notext()
    end;
  top.pp = ppConcat([ c.pp, sep, cl.pp ]);
  top.errors := c.errors ++ cl.errors;
  top.defs := c.defs ++ cl.defs;
  top.enumItems = consEnumItem(c.enumItem, cl.enumItems);
  top.structItems = consStructItem(c.structItem, cl.structItems);
  top.funDecls = consDecl(c.funDecl, cl.funDecls);
  top.constructors = c.constructors ++ cl.constructors;

  cl.env = addEnv(c.defs, c.env);
}

abstract production nilConstructor
top::ConstructorList ::=
{
  propagate substituted;
  top.pp = notext();
  top.errors := [];
  top.defs := [];
  top.enumItems = nilEnumItem();
  top.structItems = nilStructItem();
  top.funDecls = nilDecl();
  top.constructors = [];
}

-- Constructs the enum item for each constructor
synthesized attribute enumItem :: EnumItem;

-- Constructs the struct item for each constructor
synthesized attribute structItem :: StructItem;

-- Constructs the function declaration to create each constructor
synthesized attribute funDecl :: Decl;

nonterminal Constructor
  with pp, env, defs, errors, enumItem, structItem, funDecl, topTypeName, constructors,
       returnType, -- because Types may contain Exprs
       substituted<Constructor>, substitutions,
       location;

abstract production constructor
top::Constructor ::= n::Name ps::Parameters
{
  propagate substituted;
  
  {- This attribute is for extensions to use to initialize additional members added
     to the generated ADT struct. -}
  production attribute initStmts::[Stmt] with ++;
  initStmts := [];
  
  top.pp = ppConcat([n.pp, parens(ppImplode(text(", "), ps.pps)), semi()]);
  top.errors := ps.errors;
  top.errors <- n.valueRedeclarationCheckNoCompatible;
  
  top.defs := ps.typeDefs;
  
  ps.position = 0;  
  ps.constructorName = n.name;
  
  top.constructors = [pair(n.name, ps)];
  
  top.enumItem =
    enumItem(name(top.topTypeName ++ "_" ++ n.name, location=builtin), nothingExpr());
  
  top.structItem =
    structItem(
      nilAttribute(),
      structTypeExpr(
        nilQualifier(),
        structDecl(
          nilAttribute(),
          justName(name(top.topTypeName ++ "_" ++ n.name ++ "_s", location=builtin)),
          ps.asStructItemList, location=builtin)),
      consStructDeclarator(
        structField(n, baseTypeExpr(), nilAttribute()),
        nilStructDeclarator()));
  
  production resultTypeExpr::BaseTypeExpr =
    adtTagReferenceTypeExpr(nilQualifier(), name(top.topTypeName, location=builtin));
  top.funDecl =
    ableC_Decl {
      static inline $BaseTypeExpr{resultTypeExpr} $Name{n}($Parameters{ps.asConstructorParameters}) {
        $BaseTypeExpr{resultTypeExpr} result;
        result.tag = $name{top.topTypeName ++ "_" ++ n.name};
        $Stmt{ps.asAssignments}
        $Stmt{foldStmt(initStmts)}
        return result;
      }
    };
}
