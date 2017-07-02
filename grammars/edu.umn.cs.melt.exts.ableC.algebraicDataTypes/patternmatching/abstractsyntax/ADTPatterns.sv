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
p::Pattern ::= id::String ps::PatternList
{
  p.pp = cat( text(id), parens( ppImplode(text(","), ps.pps) ) );
  ps.env = p.env;
  p.decls = ps.decls;
  p.defs := ps.defs;
  
  -- Type checking
  p.errors :=
    -- Check that expected type for this pattern is an ADT type of some sort.
    if  ! adtTypeInfo.fst
    then [ err( p.location, "Constructor \"" ++ id ++ "\" does not match " ++
           "expected type of \"" ++ 
           show(100,cat(p.expectedType.lpp,p.expectedType.rpp)) ++ "\".") ]
    else

    -- Check that this pattern is a constructor for the expected ADT type.
    if ! constructorM.isJust
    then [ err( p.location, "\"" ++ id ++ "\" is not a valid constructor " ++
           "for the expected type of \"" ++ 
           show(100,cat(p.expectedType.lpp,p.expectedType.rpp)) ++ "\".") ]
    else

    -- Check that the number of patterns matches number of arguments for 
    -- this constructor.
    if  ps.pslength != length( constructorM.fromJust.snd )
    then [ err( p.location, "This pattern has " ++ toString(ps.pslength) ++ 
           " arguments, but " ++ 
           toString(length( constructorM.fromJust.snd )) ++ " were expected.") ]
    else ps.errors;

  -- 1. get the RefIdItem for the expected type
  local adtTypeInfo :: Pair<Boolean [RefIdItem]>
    = case p.expectedType of
      | adtTagType( _, adtRefId, _) -> pair( true, lookupRefId(adtRefId, p.env))
      | tagType( _, refIdTagType(_,_,refId)) -> pair( true, lookupRefId(refId, p.env) )
      | pointerType( _, adtTagType(_,adtRefId,_) ) -> pair(true, lookupRefId(adtRefId, p.env))
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

  p.transform = foldStmt ( [
      txtStmt( "/* matching against a ADT constructor pattern */" ),
      txtStmt( "/* match against constructor */" ),
      ifStmt(
        txtExpr( " (* _curr_scrutinee_ptr)->tag != " ++ tag_name ++ " ", 
                 location = p.location ),
        -- then
        txtStmt( "_match = 0;" ),
        -- else
        foldStmt( [
          txtStmt( "/* match against sub-patterns," ++
                   " setting _match to 0 on a fail */" ) ,

 
          declStmt(
           variableDecls( [], nilAttribute(), directTypeExpr(p.expectedType),
             consDeclarator(
               declarator( name("_cons_scrutinee_ptr", location=bogus_loc()), 
                 pointerTypeExpr (nilQualifier(), baseTypeExpr()), nilAttribute(), 
                 justInitializer( exprInitializer( txtExpr( "_curr_scrutinee_ptr",
                                                            location=bogus_loc() ) ) ) ),
               nilDeclarator() ) ) ),


          (if length(ps.transform) == length(ps.expectedTypes)
           then mkTrans(ps.transform, ps.expectedTypes, id, 0)
           else txtStmt("/* Error - ps.transform and ps.expectedTypes have " ++ 
                        "different lengths */") )
         ] )
      )
    ] );
}

function mkTrans
Stmt ::= pts::[Stmt] ptypes::[Type] tag::String pos::Integer
{
  return
    if null(pts)
    then nullStmt()
    else seqStmt( mkTran (head(pts), head(ptypes), tag, pos), 
                  mkTrans (tail(pts), tail(ptypes), tag, pos+1) );
}

function mkTran
Stmt ::= pt::Stmt ptype::Type tag::String pos::Integer
{
  return
    compoundStmt ( foldStmt ([
      declStmt(
       variableDecls( [], nilAttribute(), directTypeExpr(ptype),
         consDeclarator(
           declarator( 
             name("_curr_scrutinee_ptr", location=bogus_loc()), 
             pointerTypeExpr (nilQualifier(), baseTypeExpr()), nilAttribute(), 
             justInitializer( exprInitializer( 
               txtExpr( "& (* _cons_scrutinee_ptr)->contents." ++ tag ++ ".f" ++ 
                        toString(pos),
                        location=bogus_loc()
                ) ) ) ),
           nilDeclarator() ) ) ),

      pt

     ])
    ) ; 


{-
    [ txtStmt ("FIX 

Expr * * _curr_scrutinee_ptr = & (* _curr_scrutinee_ptr)->contents.Add.f0;") ;


  compoundStmt ( foldStmt ([

          p.transform 
      ]) ) ;-}

}

function bogus_loc
Location ::= 
{ return loc("", -1, -1, -1, -1, -1, -1); }


function matchConstructorName
Boolean ::= n::String cnst::Pair<String [Type]>
{ return n == cnst.fst;
}


{-
  ps.transformIn = p.transformIn;

  p.transform =
   foldStmt (
     (if   p.depth > 0 
      then [txtStmt("_current_ADT" ++ "[" ++ toString(p.depth) ++ "] = " ++
                    "( void *)" ++
                    "((" ++ p.parent_idType ++ ")" ++
                    "_current_ADT" ++ "[" ++ 
                    toString(p.depth-1) ++ "])" ++ 
                    "->contents." ++ 
                    p.parent_id ++ ".f" ++ toString(p.position) ++ " ; ")]
      else [ ] ) ++

    [ ifStmt(
        -- check that the 'tag' field of the current node has the tag for this pattern.
        txtExpr(" ((" ++ idType ++ ")" ++ 
                "_current_ADT" ++ "[" ++ toString(p.depth) ++ "])->tag == " ++
                " " ++ idTypeIndicator ++ "_" ++ id, location=p.location),
      
        -- then clause
        foldStmt ([ 
          ps.transform
         ]),           
        -- else clause  
        nullStmt()
       ) 
    ]);
      
  local scrutineeTypeInfo :: Pair<String [ Pair<String [Type]> ]> 
    = getExpectedADTTypeInfo ( p.expectedType, p.env );

  local idType :: String = scrutineeTypeInfo.fst ++ " *";
  local attribute idTypeIndicator :: String = scrutineeTypeInfo.fst;
    -- if head(explode("",id)) == "v" then "int " else "Expr" ;
  
  ps.position = 0;
  ps.depth = p.depth + 1;
  ps.parentTag = id;
  ps.parent_id = id;
  ps.parent_idType = idType;
  ps.parent_idTypeIndicator = idTypeIndicator;

-- This was all part of constructor pattern
-}




{-
function getExpectedADTTypeInfo
Pair<String [ Pair<String [Type]> ]> ::= t::Type e::Decorated Env
{
  return 
      case t of
      | pointerType(_,adtTagType(_, adtRefId, _)) ->
        case lookupRefId(adtRefId, e) of
        | [] -> error ("Internal error: ADT_1: " ++ hackUnparse(t) )
        | xs -> case head(xs) of
                | adtRefIdItem(adtDcl,_) -> adtDcl.adtInfo
                | _ -> error ("Internal error: ADT_2")
                end
        end
      | _ -> error ("Internal error: ADT_3: " ++ hackUnparse(t))
      end;
}


-}



-- PatternList --
-----------------
synthesized attribute pslength::Integer;
nonterminal PatternList with location, pps, errors,
  env, defs, decls, expectedTypes, 
  transform<[Stmt]>,
  pslength,
  returnType;

-- , defs, env, errors, pslength, position, depth, parent_id, parent_idType, parent_idTypeIndicator, parentTag, 
--       decls, 
  -- transform<Stmt>, transformIn<Stmt>;


abstract production consPattern
ps::PatternList ::= p::Pattern rest::PatternList
{
  ps.pps = p.pp :: rest.pps;
  ps.errors := p.errors ++ rest.errors;
  ps.pslength = 1 + rest.pslength;

  p.env = ps.env;
  rest.env = addEnv(p.defs,ps.env);
  
  ps.defs := p.defs ++ rest.defs;

  ps.decls = p.decls ++ rest.decls;

  local splitTypes :: Pair<Type [Type]>
    = case ps.expectedTypes of
      | t::ts -> pair(t,ts)
      | _ -> pair(errorType(),[])
      end;

  p.expectedType = splitTypes.fst;
  rest.expectedTypes = splitTypes.snd;

  -- rest.transformIn = ps.transformIn;
  -- p.transformIn = rest.transform;
  ps.transform = p.transform :: rest.transform ;

{-

  p.position = ps.position ;
  rest.position = ps.position + 1;
  p.depth = ps.depth;
  rest.depth = ps.depth;
  p.parentTag = ps.parentTag;
  rest.parentTag = ps.parentTag;
-}
}

abstract production nilPattern
ps::PatternList ::= {-empty-}
{
  ps.pps = [];
  ps.errors := [];
  ps.pslength = 0;
  ps.defs := [];
  ps.decls = [ ];
  ps.transform = [];
}


