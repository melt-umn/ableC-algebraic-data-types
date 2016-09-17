grammar edu:umn:cs:melt:exts:ableC:algDataTypes:associativepatterns:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp with implode as ppImplode;

imports edu:umn:cs:melt:ableC:abstractsyntax hiding vectorType;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:overload;

imports edu:umn:cs:melt:exts:ableC:vector:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax;

abstract production arrayPattern
p::Pattern ::= items::ItemList len::Expr
{
  local errTyp :: Pair< [Message] Type>
    = case p.expectedType of
      | pointerType(_, t) -> pair([], t)
      | arrayType(t, _, _, _) -> pair([], t)
      | _ -> pair( [err(p.location, "Incorrect non-array/non-pointer type in pattern")], 
                   errorType() )
      end;

  items.expectedType = errTyp.snd;
  items.transIn = nullStmt();

  p.pp = text("ITEMLIST");

  -- I'm not sure about setting all of these explictly.
  -- I tried to get decls off of forwards-to, but had some issues
  -- so I reverted to this, which seems to at least work for the
  -- simple e1.xc example in artifacts/associative
  p.defs = pv.defs ++ items.defs;
  p.decls = pv.decls ++ items.decls;

  local pv :: Pattern = 
     patternVariable("_v", location=items.location) ;
  pv.env = p.env;
  pv.expectedType = p.expectedType;
 
  p.errors := errTyp.fst ++ items.errors ++ len.errors;

  forwards to
    patternBoth( 
      pv,
      patternWhen( 
        stmtExpr(
          compoundStmt(
            foldStmt([
              txtStmt("int _index = 0;"),
              txtStmt("int _done = 0;"),
              mkIntDeclExpr("_length", len, len.location),
              items.transOut])),  
          txtExpr("_match", location=items.location), 
          location=items.location),
        location=items.location),
      location=items.location);
}

abstract production vectorPattern
p::Pattern ::= items::ItemList
{
  local errTyp::Pair<[Message] Type> =
    case p.expectedType of
    | vectorType(_, t) -> pair([], t)
    | t -> pair([err(p.location, s"Expected vector type in pattern (got ${showType(t)})")], errorType())
    end;

  items.expectedType = errTyp.snd;
  items.transIn = nullStmt();

  -- TODO
  p.pp = text("ITEMLIST");

  -- I'm not sure about setting all of these explictly.
  -- I tried to get decls off of forwards-to, but had some issues
  -- so I reverted to this, which seems to at least work for the
  -- simple e1.xc example in artifacts/associative
  p.defs = pv.defs ++ items.defs;
  p.decls = pv.decls ++ items.decls;

  local pv::Pattern = patternVariable("_v", location=items.location);
  pv.env = p.env;
  pv.expectedType = p.expectedType;
 
  p.errors <- errTyp.fst ++ items.errors;

  forwards to
    patternBoth( 
      pv,
      patternWhen( 
        stmtExpr(
          compoundStmt(
            foldStmt([
              txtStmt("int _index = 0;"),
              txtStmt("int _done = 0;"),
              txtStmt("int _length = _v->length;"),
              items.transOut])),  
          txtExpr("_match", location=items.location), 
          location=items.location),
        location=items.location),
      location=items.location);
}

synthesized attribute transOut :: Stmt;
inherited attribute transIn :: Stmt;

nonterminal ItemList with location, pp, env, transIn, transOut, expectedType, decls, defs, errors;

abstract production consItems
is::ItemList ::= h::Item t::ItemList
{
  is.transOut = h.transOut;
  h.transIn = t.transOut;
  t.transIn = is.transIn;
  h.expectedType = is.expectedType;
  t.expectedType = is.expectedType;
  is.errors := h.errors ++ t.errors;
  is.decls = h.decls ++ t.decls;
  is.defs = h.defs ++ t.defs;
}
abstract production oneItem
is::ItemList ::= h::Item 
{
  is.transOut = h.transOut;
  h.transIn = is.transIn;
  h.expectedType = is.expectedType;
  is.errors := h.errors;
  is.defs = h.defs;
  is.decls = h.decls;
}

nonterminal Item with location, pp, env, transIn, transOut, expectedType, decls, defs, errors;

abstract production searchItem
i::Item ::= p::Pattern
{
  i.pp = cat( text("..., "), p.pp );
  i.errors := p.errors;
  i.decls = p.decls;
  i.defs = p.defs;

  p.expectedType = i.expectedType;
  local thisMatch :: Stmt = nullStmt();

  local pIndexName :: String = "_p" ++ toString(genInt()) ++ "_index" ;

  i.transOut = compoundStmt ( 
    seqStmt(
      mkIntDeclInit(pIndexName, "_index", p.location), 
      whileStmt(
        txtExpr("(! _done /*while expr*/)", location=p.location), 
        foldStmt(
          -- p.decls ++
          [ whileStmt ( 
              mkAnd( 
                txtExpr(pIndexName ++ " < _length", location=p.location), 
                stmtExpr( 
                  foldStmt( [
                     txtStmt("/*something*/"),
                     mkDecl(
                       "_curr_scrutinee_ptr", 
                       pointerType([], i.expectedType),
                       mkAddressOf(
                         arraySubscriptExpr(
                           declRefExpr(
                             name("_v", location=p.location),
                             location=p.location),
                           declRefExpr(
                             name(pIndexName, location=p.location),
                             location=p.location),
                           location=p.location),
                         p.location),
                       p.location),

                     p.transform,
                     txtStmt("int _match_new = _match; _match = 1;")
                   ] ),
                  txtExpr("! _match_new", location=p.location), 
                  location=p.location 
                ),
                p.location 
              ),
              txtStmt("++ " ++ pIndexName ++ ";")
            ), -- inner while

            ifStmt(
              txtExpr(pIndexName ++ " == _length", location=p.location), 
              txtStmt("_match = 0; _done = 1;"),
              seqStmt(
                txtStmt("_index = " ++ pIndexName ++ " + 1;"),
                i.transIn)
            )
          ]
        )
      )
    )
  );
}

abstract production hereItem
i::Item ::= p::Pattern
{
  i.pp = p.pp;
  i.transOut =
    compoundStmt(
      foldStmt([
        p.transform,
        txtStmt("_index++"),
        i.transIn]));
}

{- `trailingDots` is always the last item in the list.
   This is ensured by the concrete syntax. -}
abstract production trailingDots
i::Item ::= 
{
  i.pp = text("...");
  i.decls = [];
  i.defs = [];
  i.errors := [];
  i.transOut = txtStmt("_done = 1;");
}

abstract production trailingEmpty
i::Item ::= 
{
  i.pp = text("");
  i.decls = [];
  i.defs = [];
  i.errors := [];
  i.transOut = txtStmt("_done = _index == _length;");
}