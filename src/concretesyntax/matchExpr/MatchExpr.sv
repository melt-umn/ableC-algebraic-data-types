grammar edu:umn:cs:melt:exts:ableC:algDataTypes:src:concretesyntax:matchExpr;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
--imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
--imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:src:abstractsyntax as abs ;

-- moved up to Exports.sv
exports edu:umn:cs:melt:exts:ableC:algDataTypes:src:concretesyntax:matchKeyword;
exports edu:umn:cs:melt:exts:ableC:algDataTypes:src:concretesyntax:patterns;

--import edu:umn:cs:melt:exts:ableC:algDataTypes:src:concretesyntax:patterns;

-- trigger the test
--import edu:umn:cs:melt:exts:ableC:algDataTypes:src:mda_test;



-- Match expression --
concrete production match_c
e::PrimaryExpr_c ::= 'match' m::Match
{
  e.ast = m.ast ;
}

nonterminal Match with ast<Expr>, location;

concrete production matchExpr_c
m::Match ::= '(' scrutinee::Expr_c ')' '(' cs::ExprClauses ')'
{
  m.ast = abs:matchExpr( scrutinee.ast, cs.ast, location=m.location );
--  cs.defaultClauseAST = 
--    abs:defaultClause(
--      stmtExpr( txtStmt("printf(\"BOOM!\\n\"); exit(1);"), scrutinee.ast, location=m.location), 
--      location=m.location
--     );
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



{-

We don't really need a "default" clause.  One can just use the
wildcard pattern "_" to match anything.

concrete production matchExprWithDefault_c
m::Match ::= '(' scrutinee::Expr_c ')' '(' cs::ExprClauses def::DefaultClause ')'
{
  m.ast = abs:matchExpr( scrutinee.ast, cs.ast, location=m.location );
  cs.defaultClauseAST = def.ast;
}

nonterminal DefaultClause with location, ast<abs:ExprClause> ;

terminal Defualt_t 'default' lexer classes {Ckeyword};

concrete productions c::DefaultClause
| 'default' ':' e::Expr_c ';'
  { c.ast = 
      abs:defaultClause( e.ast, location=c.location ); 
  }
-}

