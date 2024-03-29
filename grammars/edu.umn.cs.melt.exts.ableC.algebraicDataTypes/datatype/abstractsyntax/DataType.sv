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
  top.pp = ppConcat([ text("datatype"), space(), adt.pp, semi() ]);

  propagate env, isTopLevel, controlStmtContext;
  adt.givenRefId = nothing();
  adt.adtGivenName = adt.name;

  forwards to
    if null(adt.errors)
    then adt.transform
    else decls(foldDecl([warnDecl(adt.errors), defsDecl(adt.defs)]));
}

synthesized attribute transform<a> :: a;

-- Used to specify a name to use for translation naming convensions.
-- Usually the same as adtDeclName, but but extensions building on ADTs can
-- specify a different one.  This can be the same for multiple adtDecls with
-- the same constructors.
inherited attribute adtGivenName :: String;

tracked nonterminal ADTDecl with pp, env, defs, errors, isTopLevel,
  adtGivenName, name, givenRefId, refId, constructors, tagEnv, hostFieldNames,
  transform<Decl>, controlStmtContext;
flowtype ADTDecl = decorate {isTopLevel, env, givenRefId, adtGivenName,
  controlStmtContext},
  pp {}, defs {decorate}, errors {decorate}, name {}, refId {decorate},
  constructors {decorate}, tagEnv {decorate}, hostFieldNames {decorate}, transform {decorate};

abstract production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  propagate isTopLevel, controlStmtContext, adtGivenName, errors;  -- TODO: check for redeclaration
  attachNote extensionGenerated("ableC-algebraic-data-types");
  top.pp = ppConcat([ ppAttributes(attrs), n.pp, space(), braces(nestlines(2, cs.pp)) ]);

  {- structs create a tagItem and a refIdItem in the environment
      < structName, adtTagItem ( SEU, RefIdAsString ) >
      < refIdAsString, structRefIdItem(decorated StructDecl) >
     The reason for this is to deal with forward declarations of structs.

     We have to do this for ADTs as well.
   -}
  top.name = n.name;

  attrs.env = top.env;
  n.env = top.env;

  production preDefs :: [Def] =
    if name_tagHasForwardDcl_workaround
    then []
    else [adtTagDef(n.name, adtRefIdTagItem(top.refId))];
  production postDefs :: [Def] =
    [adtRefIdDef(top.refId, adtRefIdItem(top))];

  top.defs := preDefs ++ postDefs;

  local name_refIdIfOld_workaround :: Maybe<String> =
    case n.tagLocalLookup of
    | adtRefIdTagItem(thisRefId) :: _ -> just(thisRefId)
    | _ -> nothing()
    end;
  local name_tagRefId_workaround :: String =
    fromMaybe(toString(genInt()), name_refIdIfOld_workaround);
  local name_tagHasForwardDcl_workaround :: Boolean =
    name_refIdIfOld_workaround.isJust;

  top.refId = fromMaybe(name_tagRefId_workaround, orElse(top.givenRefId, attrs.maybeRefId));
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
                  name(s"_dummy_${top.adtGivenName}_enum_item_${toString(genInt())}"),
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
  
  production adtStructDeclaration::Decorated StructDecl =
    case adtStructDecl of
    | typeExprDecl(_, structTypeExpr(_, d)) -> d
    | _ -> error("unexpected adtStructDecl structure")
    end;

  -- Decorate struct and enum declarations here to compute tagEnv andfieldNames
  adtEnumDecl.env = top.env;
  adtEnumDecl.isTopLevel = top.isTopLevel;
  adtEnumDecl.controlStmtContext = top.controlStmtContext;
  adtStructDecl.env = addEnv(adtEnumDecl.defs, top.env);
  adtStructDecl.isTopLevel = top.isTopLevel;
  adtStructDecl.controlStmtContext = top.controlStmtContext;

  top.tagEnv = adtStructDeclaration.tagEnv;
  top.hostFieldNames := adtStructDeclaration.hostFieldNames;

  {- This attribute is for extensions to use to add additional auto-generated functions
     for ADT, for example an auto-generated recursive freeing function. -}
  production attribute adtDecls::Decls with appendDecls;
  adtDecls := nilDecl();
  -- Seed the flowtype
  adtDecls <- if false then error(hackUnparse(top.env) ++ hackUnparse(top.controlStmtContext) ++ hackUnparse(top.givenRefId) ++ top.adtGivenName) else nilDecl();

  {- Used to generate prototypes for adtDecls which are inserted before the constructors -}
  production attribute adtProtos::Decls with appendDecls;
  adtProtos := nilDecl();
  -- Seed the flowtype
  adtProtos <- if false then error(hackUnparse(top.env) ++ hackUnparse(top.controlStmtContext) ++ hackUnparse(top.givenRefId) ++ top.adtGivenName) else nilDecl();

  {- This attribute is for extensions to use to add additional members to the generated
     ADT struct. -}
  production attribute structItems::StructItemList with appendStructItemList;
  structItems := nilStructItem();

  top.transform =
    decls(
      ableC_Decls {
        $Decl{adtEnumDecl}
        $Decl{defsDecl(preDefs)}
        $Decl{adtStructDecl}
        $Decl{defsDecl(postDefs)}
        $Decls{adtProtos}
        $Decls{cs.funDecls}
        $Decls{adtDecls}
      });

  cs.env = addEnv(preDefs, top.env);
  cs.adtDeclName = n.name;
}

-- Used to pass down the datatype's actual declared name for naming conventions
inherited attribute adtDeclName :: String;

-- Constructs the enum item for each constructor
synthesized attribute enumItems :: EnumItemList;

-- Constructs the struct item for each constructor
synthesized attribute structItems :: StructItemList;

-- Constructs the initialization function for each constructor
synthesized attribute funDecls :: Decls;

-- Constructor list used, e.g., when type checking patterns
synthesized attribute constructors :: [Pair<String Decorated Parameters>];

inherited attribute appendedConstructors :: ConstructorList;
synthesized attribute appendedConstructorsRes :: ConstructorList;

tracked nonterminal ConstructorList
  with pp, env, errors, defs, enumItems, structItems, funDecls,
    adtGivenName, adtDeclName, constructors, controlStmtContext,
    appendedConstructors, appendedConstructorsRes;
flowtype ConstructorList = decorate {env, adtGivenName, adtDeclName,
  controlStmtContext},
  pp {}, errors {decorate}, defs {decorate}, enumItems {adtGivenName},
  structItems {decorate}, funDecls {decorate}, constructors {decorate},
  appendedConstructorsRes {appendedConstructors};
propagate adtGivenName, adtDeclName, controlStmtContext, errors, defs, appendedConstructors on ConstructorList;

abstract production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  local sep::Document =
    case cl of
    | consConstructor(_,_) -> line()
    | nilConstructor() -> notext()
    end;
  top.pp = ppConcat([ c.pp, sep, cl.pp ]);
  top.enumItems = consEnumItem(c.enumItem, cl.enumItems);
  top.structItems = consStructItem(c.structItem, cl.structItems);
  top.funDecls = consDecl(c.funDecl, cl.funDecls);
  top.constructors = c.constructors ++ cl.constructors;
  top.appendedConstructorsRes = consConstructor(c, cl.appendedConstructorsRes);

  c.env = top.env;
  cl.env = addEnv(c.defs, c.env);
}

abstract production nilConstructor
top::ConstructorList ::=
{
  top.pp = notext();
  top.enumItems = nilEnumItem();
  top.structItems = nilStructItem();
  top.funDecls = nilDecl();
  top.constructors = [];
  top.appendedConstructorsRes = top.appendedConstructors;
}

function appendConstructorList
ConstructorList ::= p1::ConstructorList p2::ConstructorList
{
  p1.appendedConstructors = p2;
  return p1.appendedConstructorsRes;
}

-- Constructs the enum item for each constructor
synthesized attribute enumItem :: EnumItem;

-- Constructs the struct item for each constructor
synthesized attribute structItem :: StructItem;

-- Constructs the function declaration for each constructor
synthesized attribute funDecl :: Decl;

tracked nonterminal Constructor
  with pp, env, defs, errors,
       enumItem, structItem, funDecl, adtGivenName, adtDeclName, constructors,
       controlStmtContext; -- because Types may contain Exprs
flowtype Constructor = decorate {env, adtGivenName, adtDeclName,
  controlStmtContext},
  pp {}, errors {decorate}, defs {decorate}, enumItem {adtGivenName},
  structItem {decorate}, funDecl {decorate}, constructors {decorate};

propagate env, adtGivenName, adtDeclName, controlStmtContext, errors, defs on Constructor;

abstract production constructor
top::Constructor ::= n::Name ps::Parameters
{
  attachNote extensionGenerated("ableC-algebraic-data-types");

  {- This attribute is for extensions to use to initialize additional members added
     to the generated ADT struct. -}
  production attribute initStmts::[Stmt] with ++;
  initStmts := [];

  top.pp = ppConcat([n.pp, parens(ppImplode(text(", "), ps.pps)), semi()]);
  top.errors <- n.valueRedeclarationCheckNoCompatible;

  ps.position = 0;
  ps.constructorName = n.name;

  top.constructors = [(n.name, ps)];

  production enumItemName::String = top.adtGivenName ++ "_" ++ n.name;
  top.enumItem =
    enumItem(name(top.adtGivenName ++ "_" ++ n.name), nothingExpr());

  top.structItem =
    structItem(
      nilAttribute(),
      structTypeExpr(
        nilQualifier(),
        structDecl(
          nilAttribute(),
          justName(name(top.adtDeclName ++ "_" ++ n.name ++ "_s")),
          ps.asStructItemList)),
      consStructDeclarator(
        structField(n, baseTypeExpr(), nilAttribute()),
        nilStructDeclarator()));

  production resultTypeExpr::BaseTypeExpr =
    adtTagReferenceTypeExpr(nilQualifier(), name(top.adtDeclName));
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
