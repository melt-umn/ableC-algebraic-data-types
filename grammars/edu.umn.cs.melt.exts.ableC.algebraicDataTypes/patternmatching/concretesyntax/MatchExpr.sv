grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

-- Match expression --
concrete production matchMatch_c
top::PrimaryExpr_c ::= 'match' '(' scrutinees::ArgumentExprList_c ')' '(' cs::ExprClauses_c ')'
{
  top.ast = abs:matchExpr(foldr(abs:consScrutineeExpr, abs:nilScrutineeExpr(), scrutinees.ast), cs.ast);
}

tracked nonterminal ExprClauses_c with ast<abs:ExprClauses>;

concrete productions top::ExprClauses_c
| c::ExprClause_c rest::ExprClauses_c
  { top.ast = abs:consExprClause(c.ast, rest.ast); }
| {- empty -}
  { top.ast = abs:failureExprClause(); }

closed tracked nonterminal ExprClause_c with ast<abs:ExprClause> ;
terminal Where_t 'where';

concrete productions top::ExprClause_c
| OpenScope_t p::PatternList_c '->' e::Expr_c ';'
  { top.ast = abs:exprClause(p.ast, e.ast); }
  action { context = closeScope(context); }
