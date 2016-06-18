grammar edu:umn:cs:melt:exts:ableC:algDataTypes:associative:abstractsyntax;

imports silver:langutil ; --only pp, errors; --, pp, errors; --, err, wrn;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax as abs;

abstract production arrayPattern
p::abs:Pattern ::= items::ItemList len::Expr
{
  local errTyp :: Pair< [Message] Type>
    = case p.abs:expectedType of
      | pointerType(_, t) -> pair([], t)
      | arrayType(t, _, _, _) -> pair([], t)
      | _ -> pair( [err(p.location, "Incorrect non-array/non-pointer type in pattern")], 
                   errorType() )
      end;

  items.abs:expectedType = errTyp.snd;
  items.transIn = nullStmt();

  p.pp = text("ITEMLIST");

  -- I'm not sure about setting all of these explictly.
  -- I tried to get decls off of forwards-to, but had some issues
  -- so I reverted to this, which seems to at least work for the
  -- simple e1.xc example in artifacts/associative
  p.defs = pv.defs ++ items.defs;
  p.abs:decls = pv.abs:decls ++ items.abs:decls;

  local pv :: abs:Pattern = 
     abs:patternVariable("vvv", location=items.location) ;
  pv.env = p.env;
  pv.abs:expectedType = p.abs:expectedType;
 
  p.errors := errTyp.fst ++ items.errors ++ len.errors;

  forwards to
    abs:patternBoth( 
      pv,
      abs:patternWhen( 
        stmtExpr(
          compoundStmt( foldStmt(
           [
            txtStmt("int _index = 0;"),
            txtStmt("int _done = 0;"),
            mkIntDeclExpr("_length", len, len.location),
            items.transOut 
           ])
          ),  
          txtExpr("_match", location=items.location), 
          location=items.location ),
        location=items.location ),
      location=items.location 
    );
}

abstract production vecPattern
p::abs:Pattern ::= items::ItemList
{
 items.transIn = nullStmt();
 forwards to 
    abs:patternWhen( 
      stmtExpr(
        items.transOut, 
        txtExpr("_match", location=items.location), 
        location=items.location ),
      location=items.location );
}

synthesized attribute transOut :: Stmt;
inherited attribute transIn :: Stmt;

nonterminal ItemList with location, pp, env, transIn, transOut, abs:expectedType, abs:decls, defs, errors;

abstract production consItems
is::ItemList ::= h::Item t::ItemList
{
  is.transOut = h.transOut;
  h.transIn = t.transOut;
  t.transIn = is.transIn;
  h.abs:expectedType = is.abs:expectedType;
  t.abs:expectedType = is.abs:expectedType;
  is.errors := h.errors ++ t.errors;
  is.abs:decls = h.abs:decls ++ t.abs:decls;
  is.defs = h.defs ++ t.defs;
}
abstract production oneItem
is::ItemList ::= h::Item 
{
  is.transOut = h.transOut;
  h.transIn = is.transIn;
  h.abs:expectedType = is.abs:expectedType;
  is.errors := h.errors;
  is.defs = h.defs;
  is.abs:decls = h.abs:decls;
}

nonterminal Item with location, pp, env, transIn, transOut, abs:expectedType, abs:decls, defs, errors;

abstract production searchItem
i::Item ::= p::abs:Pattern
{
  i.pp = cat( text("..., "), p.pp );
  i.errors := p.errors;
  i.abs:decls = p.abs:decls;
  i.defs = p.defs;

  p.abs:expectedType = i.abs:expectedType;
  local thisMatch :: Stmt = nullStmt();

  local pIndexName :: String = "_p" ++ toString(genInt()) ++ "_index" ;

  i.transOut = compoundStmt ( 
    seqStmt( mkIntDeclInit(pIndexName, "_index", p.location), 
      whileStmt(
        txtExpr("(! _done /*while expr*/)", location=p.location), 
        foldStmt(
          -- p.abs:decls ++
          [ whileStmt ( 
              mkAnd( 
                txtExpr(pIndexName ++ " < _length", location=p.location), 
                stmtExpr( 
                  foldStmt( [

                     txtStmt("/*something*/"),
                     mkDecl("_curr_scrutinee_ptr", 
                            pointerType([], i.abs:expectedType),
                            mkAddressOf( txtExpr("vvv[" ++ pIndexName ++ "]", location=p.location), p.location),
                            p.location
                           ),



                     p.abs:transform,
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
i::Item ::= p::abs:Pattern
{
  i.pp = p.pp;

  local thisMatch :: Stmt = nullStmt();
  i.transOut = compoundStmt ( foldStmt([
    thisMatch, txtStmt("/* advance one! */"), i.transIn ]) );
}

{- `trailingDots` is always the last item in the list.
   This is ensured by the concrete syntax. -}
abstract production trailingDots
i::Item ::= 
{
  i.pp = text("...");
  i.abs:decls = [];
  i.defs = [];
  i.errors := [];
  i.transOut = txtStmt("_done = 1;");
}
