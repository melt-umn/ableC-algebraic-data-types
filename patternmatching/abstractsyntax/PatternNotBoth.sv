

abstract production patternBoth
p::Pattern ::= p1::Pattern p2::Pattern
{
  p.pp = cat(p1.pp, cat(text("@"), p2.pp));
  p.errors := p1.errors ++ p2.errors;

  p.defs = p1.defs ++ p2.defs;
  p1.env = p.env;

  --ToDo - ensure pattern vars from p1 are visible in p2 for use
  -- in 'when' pattern.  Or, rewrite 'when' to be
  --  p::Pattern ::=  p1::Pattern 'when' e::Expr - which might be better anyway.
  p2.env = addEnv(p1.defs, p.env);

  p1.expectedType = p.expectedType;
  p2.expectedType = p.expectedType;

  p.decls = p1.decls ++ p2.decls;

  p.transform = seqStmt (p1.transform, p2.transform);
}

abstract production patternNot
p::Pattern ::= p1::Pattern 
{
  p.pp = cat(text("! "), p1.pp);
  p.errors := p1.errors; -- TODO: Exclude variable patterns
  
  p.defs = p1.defs;
  p1.env = p.env;
  p1.expectedType = p.expectedType;
  p.decls = p1.decls;


  p.transform = seqStmt (p1.transform, flip_match);
  local flip_match :: Stmt = 
    txtStmt ("if (_match == 0) { _match = 1; } else { _match = 0; }");
}



abstract production patternWhen
p::Pattern ::= e::Expr
{
  p.pp = text("when");
  p.decls = [];
  p.defs = [];
  p.errors := [];
  p.transform 
    = ifStmt(
        e,
        -- txtExpr("( *_curr_scrutinee_ptr != " ++ show(10, constExpr.pp) ++ ")",
        --        location=p.location),

        -- then clause
        nullStmt(),
        -- else clause
        txtStmt("_match = 0;")
      );

}
