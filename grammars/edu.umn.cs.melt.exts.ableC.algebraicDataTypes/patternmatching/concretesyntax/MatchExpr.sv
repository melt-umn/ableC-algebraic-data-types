grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

-- Match expression --
concrete production matchMatch_c
e::PrimaryExpr_c ::= 'match' m::Match
{
  e.ast = m.ast ;
}

nonterminal Match with ast<Expr>, location;

concrete production matchExpr_c
m::Match ::= '(' scrutinee::Expr_c ')' '(' cs::ExprClauses ')'
{
  m.ast = abs:matchExpr( scrutinee.ast, cs.ast, location=m.location );
}


nonterminal ExprClauses with location, ast<abs:ExprClauses>; --, defaultClauseAST ;

-- inherited attribute defaultClauseAST :: abs:ExprClause ;

concrete productions cs::ExprClauses
| c::ExprClause rest::ExprClauses
  {
    cs.ast = abs:consExprClause( c.ast, rest.ast, location=cs.location ); 
--    rest.defaultClauseAST = cs.defaultClauseAST;
  }
| c::ExprClause 
  {
    cs.ast = abs:oneExprClause (c.ast, location=cs.location);
  }

{-
| -- empty --
  {
    cs.ast = abs:failureClause (location=cs.location);
  }
-}

nonterminal ExprClause with location, ast<abs:ExprClause> ;
terminal Where_t 'where' ; -- lexer classes {Ckeyword};

concrete productions c::ExprClause
| p::Pattern '->' e::Expr_c ';'
  { c.ast = 
      abs:exprClause( p.ast, e.ast, location=c.location ); 
  }
| p::ConstPattern '->' e::Expr_c ';'
  { c.ast = 
      abs:exprClause( p.ast, e.ast, location=c.location ); 
  }

{-

Following causes a shift/reduce error since PostfixExpr_c in host is
followed by '->'.

| p::Pattern 'where' guard::Expr_c '->' e::Expr_c ';'
  { c.ast = 
      abs:guardedExprClause( p.ast, guard.ast, e.ast, location=c.location ); 
  }
| p::ConstPattern 'where' guard::Expr_c '->' e::Expr_c ';'
  { c.ast = 
      abs:guardedExprClause( p.ast, guard.ast, e.ast, location=c.location ); 
  }

-}
