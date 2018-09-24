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
  top.pp = ppConcat([ text("datatype"), space(), adt.pp ]);
  
  -- TODO: Do local error checking before reporting forward errors once error checking for datatypeDecl is finished
  top.errors <- adt.errors;

  adt.env = top.env;

  -- Env to look up tag and refId
  -- tag isn't always in scope, so we open another scope with the incoming env to get it
  -- in the case of a forward decl
  local lookupEnv::Decorated Env = addEnv(forward.defs, openScopeEnv(top.env));

  -- Get the struct RefId and StructDecl off of forwards to tree since
  -- they are to be used in the ADT tag and ref Def items.
  adt.structRefId
    = case lookupTag(adt.name, lookupEnv) of
      | refIdTagItem(_, r) :: _ -> r
      | _ -> error( "struct ref id not found.")
      end;

  adt.structDcl
    = case lookupRefId(adt.structRefId, lookupEnv) of
      | structRefIdItem(s) :: _  -> s
      | _ -> error( "struct decl not found")
      end;

--  top.defs := adt.defs ++
    -- We don't really want all of these.
    -- We want the functions for constructing values,
    -- but not the 'struct ADT' defs.
  --  forward.defs;

  -- TODO, obviously bad to change env manually!



  forwards to
    decls(foldDecl([defsDecl(adt.defs), adt.transform]));
    -- adt.transform with {env = addEnv(adt.defs, top.env);};
}

synthesized attribute transform<a> :: a;

nonterminal ADTDecl with pp, env, defs, errors, returnType, structRefId, structDcl, name, adtInfo, refId, transform<Decl>;

inherited attribute structRefId :: String;
inherited attribute structDcl :: Decorated StructDecl;
synthesized attribute adtInfo :: Pair<String [ Pair<String [Type]> ]>;

abstract production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  top.pp = ppConcat([ n.pp, space(), braces(cs.pp) ]);
  top.errors := cs.errors; -- TODO: check for redeclaration

  {- Since ADTs translate down to structs with the same name, we don't
     want to allow programmer to create structs that also have this
     name.  So we use the same namespace in the environment for ADTs
     and structs (and enums and unions).
   
     structs create a tagItem and a refIdItem in the environment
      < structName, refIdTagItem ( SEU, RefIdAsString ) >
      < refIdAsString, structRefIdItem(decorated StructDecl) >
     The reason for this is to deal with forward declarations of structs.
     
     We have to do this for ADTs as well.
   -} 
  top.name = n.name;

  local preDefs :: [Def] = 
    if name_tagHasForwardDcl_workaround -- n.tagHasForwardDcl {-|| !name.hasName-} 
    then []
    else [ adtTagDef( n.name, adtRefIdTagItem( name_tagRefId_workaround, -- n.tagRefId,
                                               top.structRefId )) ];

  cs.env = addEnv(preDefs, top.env);

  top.defs := preDefs ++
    [ adtRefIdDef( name_tagRefId_workaround, adtRefIdItem(top, top.structDcl) ) ] ;

  local name_refIdIfOld_workaround :: Maybe<String>
    = case n.tagLocalLookup of
      | adtRefIdTagItem(thisRefId,_) :: _ -> just(thisRefId)
      -- | refIdTagItem(_, thisRefID) :: _ -> just(thisRefID)
      | _ -> nothing()
      end;
  local name_tagRefId_workaround :: String
    = fromMaybe(toString(genInt()), name_refIdIfOld_workaround);
  local name_tagHasForwardDcl_workaround :: Boolean
    = name_refIdIfOld_workaround.isJust;

  top.adtInfo = pair(n.name,cs.constructors);
  top.refId = name_tagRefId_workaround;

  cs.topTypeName = n.name;
  
  {- This attribute is for extensions to use to add additional auto-generated functions
     for ADT, for example an auto-generated recursive freeing function.  This is being used
     in the rewriting extension for the construct and destruct functions.
  -}
  production attribute adtDecls::Decls with appendDecls;
  adtDecls := nilDecl();
  
  {- Used to generate prototypes for adtDecls which are inserted before the constructors -}
  production attribute adtProtos::Decls with appendDecls;
  adtProtos := nilDecl();
  
  production attribute structItems::StructItemList with appendStructItemList;
  structItems := nilStructItem();
  
  structItems <-
    consStructItem(
      structItem(
        nilAttribute(),
        directTypeExpr(
          builtinType(
            nilQualifier(),
            unsignedType(intType()))),
            consStructDeclarator(
              structField(
                name("refId", location=builtin),
                baseTypeExpr(),
                nilAttribute()),
            nilStructDeclarator())),
      nilStructItem());
      
  local attribute genericAdtDecl::Decl =
    typeExprDecl(
      nilAttribute(),
      structTypeExpr(
        nilQualifier(),
        structDecl(nilAttribute(),
          justName(name("_GenericDatatype", location=builtin)),
          appendStructItemList(
            structItems,
            consStructItem(
              structItem(
                nilAttribute(),
                directTypeExpr(
                  builtinType(
                    nilQualifier(),
                    unsignedType(intType()))),
                consStructDeclarator(
                  structField(
                    name("tag", location=builtin),
                    baseTypeExpr(),
                    nilAttribute()),
                  nilStructDeclarator())),
              nilStructItem())),
          location=builtin)));
  

  local attribute defaultDecls::Decls =
      consDecl(
        typeExprDecl(
          nilAttribute(),
          structTypeExpr(
            nilQualifier(),
            structDecl(nilAttribute(),
              justName( n ),
              appendStructItemList(
                structItems,
                consStructItem(
                  structItem(nilAttribute(),
                    enumTypeExpr(
                      nilQualifier(),
                      enumDecl(justName(name("_" ++ n.name ++ "_types", location=builtin)),
                      case cs.enumItems of
                        nilEnumItem() ->
                          consEnumItem(
                            enumItem(
                              name("_dummy_" ++ n.name ++ "_enum_item", location=builtin),
                              nothingExpr()),
                            nilEnumItem())
                      | _ -> cs.enumItems
                      end,
                      location=builtin)),
                     consStructDeclarator(
                      structField(
                        name("tag", location=builtin),
                        baseTypeExpr(),
                        nilAttribute()),
                      nilStructDeclarator())),
                  consStructItem(
                    structItem(nilAttribute(),
                      unionTypeExpr(
                        nilQualifier(),
                        unionDecl(
                          nilAttribute(),
                          justName(
                            name("_" ++ n.name ++ "_contents", location=builtin)),
                          cs.structItems, location=builtin)),
                      consStructDeclarator(
                        structField(
                          name("contents",location=builtin), 
                          baseTypeExpr(),
                          nilAttribute()),
                        nilStructDeclarator())),
                    nilStructItem()))), location=builtin))),
        nilDecl() ) ; --cs.funDecls);

--  top.transform = decls(appendDecls(defaultDecls, adtDecls));

  top.transform =
    if !null(lookupTag("_GenericDatatype", top.env))
    then decls(
           appendDecls(
             defaultDecls,
             appendDecls(
               adtProtos,
               appendDecls(
                 cs.funDecls,
                 adtDecls))))
    else decls(
           consDecl(
             genericAdtDecl,
               appendDecls(
                 defaultDecls,
                 appendDecls(
                   adtProtos,
                   appendDecls(
                     cs.funDecls,
                     adtDecls)))));

}

function appendStructItemList
StructItemList ::= d1::StructItemList d2::StructItemList
{
  return case d1 of
              nilStructItem() -> d2
            | consStructItem(d, rest) -> consStructItem(d, appendStructItemList(rest, d2))
         end;
}


-- Constructs the enum item for each constructor
synthesized attribute enumItems :: EnumItemList;

-- Constructs the struct item for each constructor
synthesized attribute structItems :: StructItemList;

-- Constructs the initialization function for each constructor
synthesized attribute funDecls :: Decls;

-- Used to pass down the datatype's name for naming conventions
inherited attribute topTypeName :: String;

-- Cosntructor list used, e.g., when type checking patterns
synthesized attribute constructors :: [ Pair<String [Type]> ];

nonterminal ConstructorList
  with pp, env, errors, returnType, enumItems, structItems, funDecls, topTypeName, constructors;

abstract production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.pp = ppConcat([ c.pp, sep, cl.pp ]) ;
  top.errors := c.errors ++ cl.errors;
  local attribute sep::Document =
    case cl of
    | consConstructor(_,_) -> line()
    | nilConstructor() -> notext()
    end ;
  top.enumItems = consEnumItem(c.enumItem, cl.enumItems);
  top.structItems = consStructItem(c.structItem, cl.structItems);
  top.funDecls = consDecl( c.funDecl, cl.funDecls );

  c.topTypeName = top.topTypeName;
  cl.topTypeName = top.topTypeName;
  top.constructors = c.constructors ++ cl.constructors;
}

abstract production nilConstructor
top::ConstructorList ::=
{
  top.pp = notext();
  top.errors := [];
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
  with pp, env, errors, enumItem, structItem, funDecl, topTypeName, constructors,
       returnType, -- because Types may contain Exprs
       location;

-- Default ADT pointer allocation using malloc
abstract production constructor
top::Constructor ::= n::String tms::TypeNames
{
  forwards to
    allocConstructor(
      n, tms,
      \ty::String -> parseExpr(s"""
        ({proto_typedef ${ty};
          (${ty}*) malloc (sizeof(${ty}));})"""),
      location=top.location);
}

-- Takes a function that takes a String and returns an Expr that does the allocation for that type
abstract production allocConstructor
top::Constructor ::= n::String tms::TypeNames allocExpr::(Expr ::= String)
{
  production attribute initStmts::[Stmt] with ++;
  initStmts := [];

  top.pp = ppConcat( [ text(n ++ " ( "), ppImplode (text(", "), tms.pps),
                     text(" );") ] );
  top.errors :=
    if !null(lookupValue(n, top.env))
    then [err(top.location, n ++ " is already defined as a constructor or value")]
    else [];
  
  tms.position = 0;  
  tms.name_i = n;

  top.constructors = [ pair(n, tms.typereps) ];

  top.enumItem =
    enumItem(
      name( top.topTypeName ++ "_" ++ n, location=builtin ),
      nothingExpr());

  top.structItem =
    structItem(nilAttribute(),
      structTypeExpr(
        nilQualifier(),
        structDecl(nilAttribute(),
          justName(
            name(top.topTypeName ++ "_" ++ n ++ "_s", location=builtin)),
          tms.asStructItemList, location=builtin)),
      consStructDeclarator(
        structField(
          name(n, location=builtin),
          baseTypeExpr(), nilAttribute()),
        nilStructDeclarator()));

  top.funDecl =
    functionDeclaration(
      functionDecl(
        [staticStorageClass()],
        consSpecialSpecifier(inlineQualifier(), nilSpecialSpecifier()),
        typedefTypeExpr(
          nilQualifier(),
          name(top.topTypeName, location=builtin)),
        functionTypeExprWithArgs(
          pointerTypeExpr(nilQualifier(), baseTypeExpr()),
          tms.asParameters,
          false,
          nilQualifier()),
        name(n, location=builtin),
        nilAttribute(),

        nilDecl(),

        foldStmt([
          declStmt(
            variableDecls(
              [], nilAttribute(),
              typedefTypeExpr(
                nilQualifier(), 
                name(top.topTypeName, location=builtin)), 
              consDeclarator(
                declarator(
                  name("temp", location=builtin), 
                  pointerTypeExpr(nilQualifier(), baseTypeExpr()),
                  nilAttribute(),
                  nothingInitializer()),
                nilDeclarator()))),

          mkAssign("temp", allocExpr(top.topTypeName), builtin),
          
          exprStmt(
            eqExpr(
              memberExpr(
                declRefExpr(
                  name("temp",location=builtin),location=builtin),
                true,
                name("tag",location=builtin),location=builtin),
              declRefExpr(
                name(top.topTypeName++"_"++n,location=builtin),location=builtin),location=builtin)),

          exprStmt(
            eqExpr(
              memberExpr(
                declRefExpr(
                  name("temp",location=builtin),location=builtin),
                true,
                name("refId",location=builtin),location=builtin),
              realConstant(
                integerConstant(
                  case lookupTag(top.topTypeName, top.env) of
                    refIdTagItem(_, refId) :: _ -> refId
                  | _ -> error("ref id not found for " ++ top.topTypeName)
                  end,
                  true, -- Lucas, verify that this should be true and not false
                  noIntSuffix(),
                  location=builtin),
                location=builtin),
              location=builtin)),
          foldStmt(initStmts),
          tms.asAssignments,
          returnStmt(justExpr(declRefExpr(name("temp",location=builtin),location=builtin)))


        ])

       ));
}
