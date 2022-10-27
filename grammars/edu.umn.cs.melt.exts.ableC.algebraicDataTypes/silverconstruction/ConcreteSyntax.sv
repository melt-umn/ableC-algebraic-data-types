grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports edu:umn:cs:melt:exts:silver:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation;

marking terminal AntiquoteConstructorList_t '$ConstructorList' lexer classes {Antiquote, Reserved};
marking terminal AntiquoteStmtClauses_t     '$StmtClauses'     lexer classes {Antiquote, Reserved};
marking terminal AntiquoteExprClauses_t     '$ExprClauses'     lexer classes {Antiquote, Reserved};
marking terminal AntiquotePatternList_t     '$PatternList'     lexer classes {Antiquote, Reserved};
marking terminal AntiquotePattern_t         '$Pattern'         lexer classes {Antiquote, Reserved};

concrete productions top::Constructor_c
| '$ConstructorList' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
{
  top.ast = antiquoteConstructorList(e, location=top.location);
  top.constructorName = ableC:name("", location=top.location);
}

concrete productions top::StmtClause_c
| '$StmtClauses' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquoteStmtClauses(e, location=top.location); }

concrete productions top::ExprClause_c
| '$ExprClauses' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquoteExprClauses(e, location=top.location); }

concrete productions top::Pattern_c
| '$PatternList' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquotePatternList(e, location=top.location); }
| '$Pattern' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquotePattern(e, location=top.location); }
