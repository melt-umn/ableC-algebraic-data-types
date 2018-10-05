grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

-- Match expression --
concrete production matchMatch_c
top::PrimaryExpr_c ::= 'match' m::Match
{
  top.ast = m.ast;
}

nonterminal Match with ast<Expr>, location;

concrete production matchExpr_c
top::Match ::= '(' scrutinee::Expr_c ')' '(' cs::ExprClauses ')'
{
  top.ast = abs:matchExpr(scrutinee.ast, cs.ast, location=top.location);
}

nonterminal ExprClauses with location, ast<abs:ExprClauses>;

concrete productions top::ExprClauses
| c::ExprClause rest::ExprClauses
  { top.ast = abs:consExprClause(c.ast, rest.ast, location=top.location); }
| c::ExprClause 
  { top.ast = abs:oneExprClause (c.ast, location=top.location); }

nonterminal ExprClause with location, ast<abs:ExprClause> ;
terminal Where_t 'where';

concrete productions top::ExprClause
| p::Pattern_c '->' e::Expr_c ';'
  { top.ast = abs:exprClause(p.ast, e.ast, location=top.location); }
