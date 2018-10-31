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
 - enum Type_tag { Type_Unit, Type_Arrow, Type_Var };
 - struct Type {
 -   enum Type_tag tag;
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
  
  adt.givenRefId = nothing();
  adt.adtGivenName = adt.name;
  
  forwards to
    decls(
      foldDecl([
        defsDecl(adt.defs),
        if null(adt.errors) then adt.transform else warnDecl(adt.errors)]));
}

synthesized attribute transform<a> :: a;

-- Used to specify a name to use for translation naming convensions.
-- Usually the same as adtDeclName, but but extensions building on ADTs can
-- specify a different one.  This can be the same for multiple adtDecls with
-- the same constructors.
autocopy attribute adtGivenName :: String;

nonterminal ADTDecl with location, pp, env, defs, errors, isTopLevel, returnType, adtGivenName, name, givenRefId, refId, constructors, tagEnv, transform<Decl>, substituted<ADTDecl>, substitutions;
flowtype ADTDecl = decorate {isTopLevel, env, returnType, givenRefId, adtGivenName}, pp {}, defs {decorate}, errors {decorate}, name {}, refId {decorate}, constructors {decorate}, transform {decorate}, substituted {substitutions};

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
  
  production preDefs :: [Def] =
    if name_tagHasForwardDcl_workaround
    then []
    else [adtTagDef(n.name, adtRefIdTagItem(top.refId))];
  production postDefs :: [Def] =
    [adtRefIdDef(top.refId, adtRefIdItem(top))];
  
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
  
  top.refId = fromMaybe(name_tagRefId_workaround, top.givenRefId);
  top.constructors = cs.constructors;
  
  production adtTypeExpr::BaseTypeExpr =
    extTypeExpr(nilQualifier(), adtExtType(top.adtGivenName, n.name, top.refId));
  
  production structName::String = n.name ++ "_s";
  production structRefId::String = top.refId ++ "_s";
  production enumName::String = top.adtGivenName ++ "_tag";
  production unionName::String = "_" ++ n.name ++ "_contents";
  production unionRefId::String = top.refId ++ "_contents";
  
  production adtEnumDecl::Decl =
    ableC_Decl {
      enum $name{enumName} {
        $EnumItemList{
          -- Ensure we don't generate an empty enum if there are no constructors
          case cs.enumItems of
            nilEnumItem() ->
              consEnumItem(
                enumItem(
                  name(s"_dummy_${top.adtGivenName}_enum_item_${toString(genInt())}", location=builtin),
                  nothingExpr()),
                nilEnumItem())
          | _ -> cs.enumItems
          end}
        };
    };
  
  production adtStructDecl::Decl =
    ableC_Decl {
      struct __attribute__((refId($stringLiteralExpr{structRefId}))) $name{structName} {
        enum $name{enumName} tag;
        union __attribute__((refId($stringLiteralExpr{unionRefId}))) $name{unionName} {
          $StructItemList{cs.structItems}
        } contents;
        $StructItemList{structItems}
      };
    };
  
  -- Decorate struct and enum declarations here to compute tagEnv
  adtEnumDecl.env = top.env;
  adtEnumDecl.returnType = top.returnType;
  adtEnumDecl.isTopLevel = top.isTopLevel;
  adtStructDecl.env = addEnv(adtEnumDecl.defs, top.env);
  adtStructDecl.returnType = top.returnType;
  adtStructDecl.isTopLevel = top.isTopLevel;
  
  top.tagEnv = case adtStructDecl of typeExprDecl(_, structTypeExpr(_, d)) -> d.tagEnv end;
  
  {- This attribute is for extensions to use to add additional auto-generated functions
     for ADT, for example an auto-generated recursive freeing function. -}
  production attribute adtDecls::Decls with appendDecls;
  adtDecls := nilDecl();
  -- Seed the flowtype
  adtDecls <- if false then error(hackUnparse(top.env) ++ hackUnparse(top.returnType) ++ hackUnparse(top.givenRefId) ++ top.adtGivenName) else nilDecl();
  
  {- Used to generate prototypes for adtDecls which are inserted before the constructors -}
  production attribute adtProtos::Decls with appendDecls;
  adtProtos := nilDecl();
  -- Seed the flowtype
  adtProtos <- if false then error(hackUnparse(top.env) ++ hackUnparse(top.returnType) ++ hackUnparse(top.givenRefId) ++ top.adtGivenName) else nilDecl();
  
  {- This attribute is for extensions to use to add additional members to the generated
     ADT struct. -}
  production attribute structItems::StructItemList with appendStructItemList;
  structItems := nilStructItem();

  top.transform =
    decls(
      foldr1(
        appendDecls,
        [foldDecl([adtEnumDecl, adtStructDecl]), adtProtos, cs.funDecls, adtDecls]));
  
  cs.env = addEnv(preDefs, top.env);
  cs.adtDeclName = n.name;
}

-- Used to pass down the datatype's actual declared name for naming conventions.
autocopy attribute adtDeclName :: String;

-- Constructs the enum item for each constructor
synthesized attribute enumItems :: EnumItemList;

-- Constructs the struct item for each constructor
synthesized attribute structItems :: StructItemList;

-- Constructs the initialization function for each constructor
synthesized attribute funDecls :: Decls;

-- Constructor list used, e.g., when type checking patterns
synthesized attribute constructors :: [Pair<String Decorated Parameters>];

nonterminal ConstructorList
  with pp, env, errors, defs, returnType, enumItems, structItems, funDecls, adtGivenName, adtDeclName, constructors,
       substituted<ConstructorList>, substitutions;
flowtype ConstructorList = decorate {env, returnType, adtGivenName, adtDeclName}, pp {}, errors {decorate}, defs {decorate}, enumItems {adtGivenName}, structItems {decorate}, funDecls {decorate}, constructors {decorate}, substituted {substitutions};

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
  with pp, env, defs, errors, enumItem, structItem, funDecl, adtGivenName, adtDeclName, constructors,
       returnType, -- because Types may contain Exprs
       substituted<Constructor>, substitutions,
       location;
flowtype Constructor = decorate {env, returnType, adtGivenName, adtDeclName}, pp {}, errors {decorate}, defs {decorate}, enumItem {adtGivenName}, structItem {decorate}, funDecl {decorate}, constructors {decorate}, substituted {substitutions};

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
  
  top.defs := ps.defs;
  
  ps.position = 0;
  ps.constructorName = n.name;
  
  top.constructors = [pair(n.name, ps)];
  
  production enumItemName::String = top.adtGivenName ++ "_" ++ n.name;
  top.enumItem =
    enumItem(name(top.adtGivenName ++ "_" ++ n.name, location=top.location), nothingExpr());
  
  top.structItem =
    structItem(
      nilAttribute(),
      structTypeExpr(
        nilQualifier(),
        structDecl(
          nilAttribute(),
          justName(name(top.adtDeclName ++ "_" ++ n.name ++ "_s", location=builtin)),
          ps.asStructItemList, location=builtin)),
      consStructDeclarator(
        structField(n, baseTypeExpr(), nilAttribute()),
        nilStructDeclarator()));
  
  production resultTypeExpr::BaseTypeExpr =
    adtTagReferenceTypeExpr(nilQualifier(), name(top.adtDeclName, location=builtin));
  top.funDecl =
    ableC_Decl {
      static inline $BaseTypeExpr{resultTypeExpr} $Name{n}($Parameters{ps.asConstructorParameters}) {
        $BaseTypeExpr{resultTypeExpr} result;
        result.tag = $name{top.adtGivenName ++ "_" ++ n.name};
        $Stmt{ps.asAssignments}
        $Stmt{foldStmt(initStmts)}
        return result;
      }
    };
}
