grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports edu:umn:cs:melt:exts:silver:ableC:concretesyntax;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation;

terminal EscapeConstructorList_t '$ConstructorList' lexer classes {Escape, Reserved};
terminal EscapeStmtClauses_t     '$StmtClauses'     lexer classes {Escape, Reserved};
terminal EscapeExprClauses_t     '$ExprClauses'     lexer classes {Escape, Reserved};
terminal EscapePatternList_t     '$PatternList'     lexer classes {Escape, Reserved};
terminal EscapePattern_t         '$Pattern'         lexer classes {Escape, Reserved};

concrete productions top::Constructor_c
| '$ConstructorList' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquoteConstructorList(e, location=top.location); }

concrete productions top::StmtClause_c
| '$StmtClauses' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquoteStmtClauses(e, location=top.location); }

concrete productions top::ExprClause_c
| '$ExprClauses' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquoteExprClauses(e, location=top.location); }

concrete productions top::Pattern_c
| '$PatternList' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquotePatternList(e, location=top.location); }
| '$Pattern' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquotePattern(e, location=top.location); }
