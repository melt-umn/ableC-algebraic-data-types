grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax as abs;

marking terminal Match_t 'match' lexer classes {Keyword, Global};

terminal OpenScope_t '' action { context = openScope(context); };

-- Match statement --
concrete production match_c
top::SelectionStmt_c ::= 'match' '(' scrutinees::ArgumentExprList_c ')' '{' cs::StmtClauses_c '}'
{
  top.ast = abs:matchStmt(foldr(abs:consScrutineeExpr, abs:nilScrutineeExpr(), scrutinees.ast), cs.ast);
}


tracked nonterminal StmtClauses_c with ast<abs:StmtClauses>;

concrete productions top::StmtClauses_c
| c::StmtClause_c rest::StmtClauses_c
  { top.ast = abs:consStmtClause(c.ast, rest.ast); }
| {- empty -}
  { top.ast = abs:failureStmtClause(); }


closed tracked nonterminal StmtClause_c with ast<abs:StmtClause>;

concrete productions top::StmtClause_c
| OpenScope_t p::PatternList_c '->' '{' l::BlockItemList_c '}'
  { top.ast = abs:stmtClause(p.ast, foldStmt(l.ast)); }
  action { context = closeScope(context); }
| OpenScope_t p::PatternList_c '->' '{' '}'
  { top.ast = abs:stmtClause(p.ast, nullStmt()); }
  action { context = closeScope(context); }
