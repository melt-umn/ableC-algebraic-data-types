grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction only foldStmt;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax as abs ;

marking terminal Match_t 'match' lexer classes {Ckeyword};

-- Match statement --
concrete production match_c
s::SelectionStmt_c ::= mm::'match' m::MatchStmt
{ 
  s.ast = m.ast ;
}

nonterminal MatchStmt with ast<Stmt>, location;

concrete production matchStmt_c
m::MatchStmt ::= '(' scrutinee::Expr_c ')' '{' cs::StmtClauses '}'
{
  m.ast = abs:matchStmt( scrutinee.ast, cs.ast ); --, location=m.location );
}


nonterminal StmtClauses with location, ast<abs:StmtClauses>; --, defaultClauseAST ;

concrete productions cs::StmtClauses
| c::StmtClause rest::StmtClauses
  {
    cs.ast = abs:consStmtClause( c.ast, rest.ast, location=cs.location ); 
--    rest.defaultClauseAST = cs.defaultClauseAST;
  }
| {- empty -}
  {
    cs.ast = abs:failureStmtClause (location=cs.location);
  }


nonterminalStmtClause with location, ast<abs:StmtClause> ;
--terminal Where_t 'where' ; -- lexer classes {Ckeyword};

concrete productions c::StmtClause
| p::Pattern '->' '{' l::BlockItemList_c '}'
  { c.ast = 
      abs:stmtClause( p.ast, foldStmt(l.ast), location=c.location ); 
  }

| p::Pattern '->' '{' '}'
  { c.ast = 
      abs:stmtClause( p.ast, nullStmt(), location=c.location ); 
  }
  
| p::ConstPattern '->' '{' l::BlockItemList_c '}'
  { c.ast = 
      abs:stmtClause( p.ast, foldStmt(l.ast), location=c.location ); 
  }

| p::ConstPattern '->' '{' '}'
  { c.ast = 
      abs:stmtClause( p.ast, nullStmt(), location=c.location ); 
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

