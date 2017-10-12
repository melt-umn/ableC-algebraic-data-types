

abstract production patternBoth
p::Pattern ::= p1::Pattern p2::Pattern
{
  p.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  p.errors := p1.errors ++ p2.errors;

  p.defs := p1.defs ++ p2.defs;
  p1.env = p.env;

  --ToDo - ensure pattern vars from p1 are visible in p2 for use
  -- in 'when' pattern.  Or, rewrite 'when' to be
  --  p::Pattern ::=  p1::Pattern 'when' e::Expr - which might be better anyway.
  p2.env = addEnv(p1.defs, p.env);

  p1.expectedType = p.expectedType;
  p2.expectedType = p.expectedType;

  p.decls = p1.decls ++ p2.decls;

  p.transform =
    seqStmt(
      p1.transform,
      ifStmtNoElse(
        declRefExpr(name("_match", location=builtIn()), location=builtIn()),
        p2.transform));
}

abstract production patternNot
p::Pattern ::= p1::Pattern 
{
  p.pp = cat(text("! "), p1.pp);
  p.errors := p1.errors; -- TODO: Exclude variable patterns
  
  p.defs := p1.defs;
  p1.env = p.env;
  p1.expectedType = p.expectedType;
  p.decls = p1.decls;


  p.transform = seqStmt (p1.transform, flip_match);
  local flip_match :: Stmt = 
    parseStmt ("if (_match == 0) { _match = 1; } else { _match = 0; }");
}



abstract production patternWhen
p::Pattern ::= e::Expr
{
  p.pp = cat( text("when"), parens(e.pp));
  p.decls = [];
  p.defs := [];
  p.errors := e.errors;
  p.transform = ifStmt(e, nullStmt(), parseStmt("_match = 0;") );
}
