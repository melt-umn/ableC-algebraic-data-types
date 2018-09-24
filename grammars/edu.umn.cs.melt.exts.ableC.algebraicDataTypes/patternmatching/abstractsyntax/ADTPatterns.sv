grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

-- ADT Patterns --
-------------------
-- The positin of a pattern in a list, and its depths.
-- These are used to access the value matched by pattern variables.
inherited attribute position :: Integer;
inherited attribute depth :: Integer;

{-
-- These are all suspect, there may be a better way
inherited attribute parentTag :: String;
autocopy attribute parent_id:: String;
autocopy attribute parent_idType :: String;
autocopy attribute parent_idTypeIndicator :: String;
-}

abstract production constructorPattern
top::Pattern ::= id::String ps::PatternList
{
  top.pp = cat( text(id), parens( ppImplode(text(","), ps.pps) ) );
  ps.env = top.env;
  top.decls = ps.decls;
  top.defs := ps.defs;
  
  -- Type checking
  top.errors :=
    -- Check that expected type for this pattern is an ADT type of some sort.
    if  ! adtTypeInfo.fst
    then [ err( top.location, "Constructor \"" ++ id ++ "\" does not match " ++
           "expected type of \"" ++ 
           show(100,cat(top.expectedType.lpp,top.expectedType.rpp)) ++ "\".") ]
    else

    -- Check that this pattern is a constructor for the expected ADT type.
    if ! constructorM.isJust
    then [ err( top.location, "\"" ++ id ++ "\" is not a valid constructor " ++
           "for the expected type of \"" ++ 
           show(100,cat(top.expectedType.lpp,top.expectedType.rpp)) ++ "\".") ]
    else

    -- Check that the number of patterns matches number of arguments for 
    -- this constructor.
    if  ps.pslength != length( constructorM.fromJust.snd )
    then [ err( top.location, "This pattern has " ++ toString(ps.pslength) ++ 
           " arguments, but " ++ 
           toString(length( constructorM.fromJust.snd )) ++ " were expected.") ]
    else ps.errors;

  -- 1. get the RefIdItem for the expected type
  local adtTypeInfo :: Pair<Boolean [RefIdItem]>
    = case top.expectedType of
      | adtTagType( _, adtRefId, _) -> pair( true, lookupRefId(adtRefId, top.env))
      | extType( _, refIdExtType(_,_,refId)) -> pair( true, lookupRefId(refId, top.env) )
      | pointerType( _, adtTagType(_,adtRefId,_) ) -> pair(true, lookupRefId(adtRefId, top.env))
      | errorType() -> pair(true, [])
      | _ -> pair(false, [])
      end;

  -- 2. get the ADTDecl - reference to the declaration of this ADT
  local maybe_adtDcl :: Maybe<Decorated ADTDecl> 
    = case adtTypeInfo.snd of
      | [] -> nothing()
      | xs -> case head(xs) of
              | adtRefIdItem(adtDcl,_) -> just(adtDcl)
              | _ -> nothing()
              end
      end;

  -- 3. get the ADT constructors for this ADT
  local all_ADT_constructors :: [ Pair<String [Type]> ]
    = case maybe_adtDcl of
      | nothing() -> error("ADT decl not found!")
      | just(adtDcl) -> adtDcl.adtInfo.snd
      end;

  -- 4. we want adtDecl.name ++ "_" ++ id to make the tag name to match against
  local tag_name :: String
    = case maybe_adtDcl of
      | nothing() -> "ERROR_no_tag_name"
      | just(adtDcl) -> adtDcl.name ++ "_" ++ id
      end;

  -- 5. get the constructor and its argument types that match the pattern, if it exists
  local constructorM :: Maybe< Pair<String [Type]> >
    = case filter( matchConstructorName(id,_), all_ADT_constructors ) of
      | [] -> nothing()
      | [x] -> just(x)
      | _ -> error ("Two constructors with the same name in ADT type")
      end;

  ps.expectedTypes 
    = case adtTypeInfo.fst, constructorM of
      | true, just(pair(_,ts)) -> ts
      | _, _ -> []
      end ;

  -- ps.transformIn = nullStmt();

  top.transform = foldStmt ( [
      exprStmt(comment("matching against a ADT constructor pattern" , location=top.location)),
      exprStmt(comment("match against constructor", location=top.location)),
      ifStmt(
        parseExpr( " (* _curr_scrutinee_ptr)->tag != " ++ tag_name ++ " "),
        -- then
        parseStmt( "_match = 0;" ),
        -- else
        foldStmt( [
          exprStmt(comment("match against sub-patterns," ++
                   " setting _match to 0 on a fail", location=top.location)),

 
          declStmt(
           variableDecls( [], nilAttribute(), directTypeExpr(top.expectedType),
             consDeclarator(
               declarator( name("_cons_scrutinee_ptr", location=top.location), 
                 pointerTypeExpr (nilQualifier(), baseTypeExpr()), nilAttribute(), 
                 justInitializer( exprInitializer( parseExpr( "_curr_scrutinee_ptr") ) ) ),
               nilDeclarator() ) ) ),


          (if length(ps.transform) == length(ps.expectedTypes)
           then mkTrans(ps.transform, ps.expectedTypes, id, 0, ps.locations)
           else warnStmt([err(top.location,"/* Error - ps.transform and ps.expectedTypes have " ++ 
                        "different lengths */")] ) )
         ] )
      )
    ] );
}

function mkTrans
Stmt ::= pts::[Stmt] ptypes::[Type] tag::String pos::Integer locations::[Location]
{
  return
    if null(pts)
    then nullStmt()
    else seqStmt( mkTran (head(pts), head(ptypes), tag, pos, head(locations)), 
                  mkTrans (tail(pts), tail(ptypes), tag, pos+1, tail(locations)) );
}

function mkTran
Stmt ::= pt::Stmt ptype::Type tag::String pos::Integer l::Location
{
  -- TODO: don't change line number as workaround for Cilk extension
  local fakeloc :: Location =
    loc(l.filename, l.line + 100000 * (pos+1), l.column, l.endLine,
        l.endColumn, l.index, l.endIndex);
  return
    compoundStmt ( foldStmt ([
      declStmt(
       variableDecls( [], nilAttribute(), directTypeExpr(ptype),
         consDeclarator(
           declarator(
             name("_curr_scrutinee_ptr", location=fakeloc),
             pointerTypeExpr (nilQualifier(), baseTypeExpr()), nilAttribute(), 
             justInitializer( exprInitializer( 
               parseExpr( "& (* _cons_scrutinee_ptr)->contents." ++ tag ++ ".f" ++ 
                        toString(pos)
                        
                ) ) ) ),
           nilDeclarator() ) ) ),
      pt

     ])
    ) ;
}

function matchConstructorName
Boolean ::= n::String cnst::Pair<String [Type]>
{ return n == cnst.fst;
}


-- PatternList --
-----------------
synthesized attribute pslength::Integer;
synthesized attribute locations::[Location];
nonterminal PatternList with location, pps, errors,
  env, defs, decls, expectedTypes, 
  transform<[Stmt]>,
  locations,
  pslength,
  returnType;


abstract production consPattern
top::PatternList ::= p::Pattern rest::PatternList
{
  top.pps = p.pp :: rest.pps;
  top.errors := p.errors ++ rest.errors;
  top.pslength = 1 + rest.pslength;
  top.locations = p.location :: rest.locations;
  p.env = top.env;
  rest.env = addEnv(p.defs,top.env);
  
  top.defs := p.defs ++ rest.defs;

  top.decls = p.decls ++ rest.decls;

  local splitTypes :: Pair<Type [Type]>
    = case top.expectedTypes of
      | t::ts -> pair(t,ts)
      | _ -> pair(errorType(),[])
      end;

  p.expectedType = splitTypes.fst;
  rest.expectedTypes = splitTypes.snd;

  top.transform = p.transform :: rest.transform;
}

abstract production nilPattern
top::PatternList ::= {-empty-}
{
  top.pps = [];
  top.errors := [];
  top.pslength = 0;
  top.locations = [];
  top.defs := [];
  top.decls = [ ];
  top.transform = [];
}


