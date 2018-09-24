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
  --forwards to tagDef(n,t);
}
abstract production adtRefIdDef
top::Def ::= n::String r::RefIdItem
{
  top.refIdContribs = [pair(n,r)];
  --forwards to refIdDef(n,r);
}


-- TagItem --
--------------
{- atdTagItem: when looking up this type by name in the env,
   this is the structure that is returned.
 -}
abstract production adtRefIdTagItem
top::TagItem ::= adtRefId::String structRefId::String
{
  top.pp = text("ADT, adtRefId = " ++ adtRefId ++ ", structRefId = " ++ structRefId);
  forwards to refIdTagItem (structSEU(), structRefId) ;
}
{- adtRefIdItem: when looking up this type by RefId in the env,
   this is the structure that is returned.  It has a reference
   to the ADT declaration in the syntax tree. 
 -}
abstract production adtRefIdItem
top::RefIdItem ::= adt::Decorated ADTDecl s::Decorated StructDecl 
{
  top.pp = text("ADTDecl: adt.refId=" ++ adt.refId ++ ", s.refId=" ++ s.refId);
  forwards to structRefIdItem (s);
}

 
-- Type expressions --
----------------------

-- e.g. "datatype Expr;"
-- mirroring C structure of 'struct Expr'
abstract production adtTagReferenceTypeExpr 
top::BaseTypeExpr ::= q::Qualifiers n::Name
{
  top.pp = ppConcat([ 
          terminate( space(), q.pps ),
          text("datatype"), space(), 
          n.pp ]);

  local tags :: [TagItem] = lookupTag(n.name, top.env);

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

  local refId :: String =
    case tags of
    | [ ] -- not already declared, this is the declaration
      -> name_tagRefId_workaround -- n.tagRefId
    | adtRefIdTagItem (r,_)::_ -- already declared, so use previous refId
      -> r
    end ;
    
  local attribute structRefId :: String = toString(genInt());
  -- maybe create it here, stick in in defs with some bogus name -
  --    n.name ++ "STRUCT"?
    
  top.defs := 
    case tags of
    -- not already declared, this is the declaration
    | [ ] -> [  adtTagDef( n.name, adtRefIdTagItem( refId, structRefId ) ) ]
    -- already declared, so nothing to declare here
    | _ -> [] 
    end ;

  top.typerep = 
    case tags of
    -- Don't see the declaration, so we're adding it.
    | [ ] ->  adtTagType( n.name, refId, structRefId )
    -- It's an ADT and the tag type agrees.
    | adtRefIdTagItem(r,s)::_ -> adtTagType( n.name, refId, structRefId )
    | _ -> errorType()
    end ;    
    
  forwards to 
    case tags of
    | [ ] -> tagReferenceTypeExpr( q, structSEU(), n )
    | adtRefIdTagItem(r,s)::_ -> tagReferenceTypeExpr( q, structSEU(), n )
    | _ -> errorTypeExpr([err(n.location, n.name ++ " is not a declared datatype")])
    end ;

  
  
}

{- ToDo: 
-- e.g. "datatype Expr { ... }"

abstract production adtTypeExpr
top::BaseTypeExpr ::= q::[Qualifier] def::StructDecl
{
}
--}

-- Type --
----------
abstract production adtTagType
top::Type ::= name::String adtRefId::String structRefId::String
{
  top.lpp = text("ADT adtTagType(" ++ name ++ "," ++ adtRefId ++ "," ++ structRefId ++ ")"); -- TODO
  top.rpp = notext();
  top.withTypeQualifiers = top; -- TODO: Hack, discarding type qualifiers here!
  top.withoutAttributes = top;
  forwards to extType( nilQualifier(),
                refIdExtType( structSEU(), name, structRefId ) );
}
