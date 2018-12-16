grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

{- ADTs, like structs, allow forward declarations so that mutually
   recursive ADTs can be specified.  Thus we use the same refId-based
   type scheme that structs use.

   RefIdItem - contains reference attribute to the declaration
               (this is StructDecl for structs)
   
   TagItem - contains the refId String
 
   struct foo;
   adds <"foo",  refIdTagItem(structSEU(), "ID123")>
   to the tag namespace of the environment.
   
   struct foo { ...decls... };
   adds <"ID123",  structRefIdItem (...ref attr to foo decls...)>
    to the refId namespace and
   adds <"foo",  refIdTagItem(structSEU(), "ID123")>
    to the tag namespace of the environment if it isn't already there.
   
   A struct Type is really just the refId.  This is used to look up
   actual type information - specifically the Decorated StructDecl
 
   For ADTs:
   datatype Stmt;
   adds <"Stmt", adtRefIdTagItem("ADT123" "Struct123")>
   to the tag namespace.  This TagItem forwards to a 
 -}

-- Def --
---------
-- New defs for adding ADT tag items and refId items.
abstract production adtTagDef
top::Def ::= n::String t::TagItem
{
  top.tagContribs = [pair(n,t)];
}
abstract production adtRefIdDef
top::Def ::= n::String r::RefIdItem
{
  top.refIdContribs = [pair(n,r)];
}


-- TagItem --
--------------
{- adtTagItem: when looking up this type by name in the env,
   this is the structure that is returned.
 -}
abstract production adtRefIdTagItem
top::TagItem ::= refId::String
{
  top.pp = text("ADT, refId = " ++ refId);
}

-- RefIdItem --
--------------
attribute constructors occurs on RefIdItem;

aspect default production
top::RefIdItem ::=
{
  top.constructors = [];
}
 
{- adtRefIdItem: when looking up this type by RefId in the env,
   this is the structure that is returned.  It has a reference
   to the ADT declaration in the syntax tree. 
 -}
abstract production adtRefIdItem
top::RefIdItem ::= adt::Decorated ADTDecl
{
  top.pp = text("ADTDecl: adt.refId=" ++ adt.refId);
  top.tagEnv = adt.tagEnv;
  top.hasConstField = false; -- ADT is always assignable
  top.constructors = adt.constructors;
}


-- Type expressions --
----------------------

-- e.g. "datatype Expr;"
-- mirroring C structure of 'struct Expr'
abstract production adtTagReferenceTypeExpr 
top::BaseTypeExpr ::= q::Qualifiers n::Name
{
  propagate substituted;
  top.pp = ppConcat([terminate(space(), q.pps), pp"datatype", space(), n.pp]);

  local tags :: [TagItem] = lookupTag(n.name, top.env);
  local refId :: String = toString(genInt());
  
  local defs::[Def] =
    case tags of
    -- We don't see the declaration, so we're adding it.
    | [] -> [adtTagDef(n.name, adtRefIdTagItem(refId))]
    -- already declared, so nothing to declare here
    | _ -> [] 
    end;
  
  local fwrd::BaseTypeExpr =
    case tags of
    -- We don't see the declaration, so we're adding it.
    | [] -> extTypeExpr(q, adtExtType(n.name, n.name, refId))
    -- It's a datatype and the tag type agrees.
    | adtRefIdTagItem(r) :: _ -> extTypeExpr(q, adtExtType(n.name, n.name, r))
    -- It's a datatype and the tag type doesn't agree.
    | _ -> errorTypeExpr([err(n.location, "Tag " ++ n.name ++ " is not a datatype")])
    end;
  
  forwards to defsTypeExpr(defs, fwrd);
}

-- Type --
----------
synthesized attribute adtName::Maybe<String> occurs on Type, ExtType;

aspect default production
top::Type ::=
{
  top.adtName = nothing();
}

aspect production extType
top::Type ::= q::Qualifiers sub::ExtType
{
  top.adtName = sub.adtName;
}

aspect default production
top::ExtType ::=
{
  top.adtName = nothing();
}

-- adtName is the name of the datatype, as written, used for field names and enum values.
-- adtDeclName is the name of the datatype that is actually declared, used for struct/union names.
-- These are always the same within this extension, but other extensions (such as templated ADTs)
-- may wish to generate multiple datatypes from a single declaration, but the enum and field names
-- don't need to be renamed.
abstract production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  propagate substituted, canonicalType;
  top.host =
    extType(top.givenQualifiers, refIdExtType(structSEU(), adtDeclName ++ "_s", refId ++ "_s"));
  top.pp = ppConcat([pp"datatype", space(), text(adtDeclName)]);
  top.mangledName =
    s"datatype_${if adtDeclName == "<anon>" then "anon" else adtDeclName}_${substitute(":", "_", refId)}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | adtExtType(_, _, otherRefId) -> refId == otherRefId
      | _ -> false
      end;
  top.maybeRefId = just(refId);
  top.adtName = just(adtName);
  top.isCompleteType =
    \ env::Decorated Env -> !null(lookupRefId(refId, env));
}
