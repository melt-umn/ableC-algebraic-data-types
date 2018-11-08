grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax as abs;

marking terminal Match_t 'match' lexer classes {Ckeyword};

-- Match statement --
concrete production match_c
top::SelectionStmt_c ::= 'match' '(' scrutinees::ArgumentExprList_c ')' '{' cs::StmtClauses_c '}'
{
  top.ast = abs:matchStmt(foldExpr(scrutinees.ast), cs.ast);
}


nonterminal StmtClauses_c with location, ast<abs:StmtClauses>;

concrete productions top::StmtClauses_c
| c::StmtClause_c rest::StmtClauses_c
  { top.ast = abs:consStmtClause(c.ast, rest.ast, location=top.location); }
| {- empty -}
  { top.ast = abs:failureStmtClause(location=top.location); }


nonterminal StmtClause_c with location, ast<abs:StmtClause>;

concrete productions top::StmtClause_c
| p::PatternList_c '->' '{' l::BlockItemList_c '}'
  { top.ast = abs:stmtClause(p.ast, foldStmt(l.ast), location=top.location); }
| p::PatternList_c '->' '{' '}'
  { top.ast = abs:stmtClause(p.ast, nullStmt(), location=top.location); }
