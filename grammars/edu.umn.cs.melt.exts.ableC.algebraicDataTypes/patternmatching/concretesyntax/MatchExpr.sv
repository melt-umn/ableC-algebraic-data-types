grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

-- Match expression --
concrete production matchMatch_c
top::PrimaryExpr_c ::= 'match' '(' scrutinees::ArgumentExprList_c ')' '(' cs::ExprClauses_c ')'
{
  top.ast = abs:matchExpr(foldExpr(scrutinees.ast), cs.ast, location=top.location);
}

nonterminal ExprClauses_c with location, ast<abs:ExprClauses>;

concrete productions top::ExprClauses_c
| c::ExprClause_c rest::ExprClauses_c
  { top.ast = abs:consExprClause(c.ast, rest.ast, location=top.location); }
| {- empty -}
  { top.ast = abs:failureExprClause(location=top.location); }

nonterminal ExprClause_c with location, ast<abs:ExprClause> ;
terminal Where_t 'where';

concrete productions top::ExprClause_c
| p::PatternList_c '->' e::Expr_c ';'
  { top.ast = abs:exprClause(p.ast, e.ast, location=top.location); }
