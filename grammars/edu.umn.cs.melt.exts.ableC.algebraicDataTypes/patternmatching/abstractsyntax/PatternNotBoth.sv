grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax;

abstract production patternBoth
top::Pattern ::= p1::Pattern p2::Pattern
{
  top.pp = ppConcat([p1.pp, space(), text("@"), space(), p2.pp ]);
  top.errors := p1.errors ++ p2.errors;

  top.defs := p1.defs ++ p2.defs;
  p1.env = top.env;

  --ToDo - ensure pattern vars from p1 are visible in p2 for use
  -- in 'when' pattern.  Or, rewrite 'when' to be
  --  top::Pattern ::=  p1::Pattern 'when' e::Expr - which might be better anyway.
  p2.env = addEnv(p1.defs, top.env);

  p1.expectedType = top.expectedType;
  p2.expectedType = top.expectedType;

  top.decls = p1.decls ++ p2.decls;

  top.transform =
    seqStmt(
      p1.transform,
      ifStmtNoElse(
        declRefExpr(name("_match", location=builtin), location=builtin),
        p2.transform));
}

abstract production patternNot
top::Pattern ::= p::Pattern 
{
  top.pp = cat(text("! "), p.pp);
  top.errors := p.errors; -- TODO: Exclude variable patterns
  
  top.defs := p.defs;
  p.env = top.env;
  p.expectedType = top.expectedType;
  top.decls = p.decls;


  top.transform = seqStmt (p.transform, flip_match);
  local flip_match :: Stmt = 
    parseStmt ("if (_match == 0) { _match = 1; } else { _match = 0; }");
}

abstract production patternWhen
top::Pattern ::= e::Expr
{
  top.pp = cat( text("when"), parens(e.pp));
  top.decls = [];
  top.defs := [];
  top.errors := e.errors;
  top.transform = ifStmt(e, nullStmt(), parseStmt("_match = 0;") );
}
