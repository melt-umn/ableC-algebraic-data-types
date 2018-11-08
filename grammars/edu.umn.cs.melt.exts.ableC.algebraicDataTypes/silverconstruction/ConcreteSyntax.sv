grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports edu:umn:cs:melt:exts:silver:ableC:concretesyntax;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation;

terminal EscapeConstructorList_t '$ConstructorList' lexer classes {Escape, Ckeyword};
terminal EscapeStmtClauses_t     '$StmtClauses'     lexer classes {Escape, Ckeyword};
terminal EscapeExprClauses_t     '$ExprClauses'     lexer classes {Escape, Ckeyword};
terminal EscapePatternList_t     '$PatternList'     lexer classes {Escape, Ckeyword};
terminal EscapePattern_t         '$Pattern'         lexer classes {Escape, Ckeyword};

concrete productions top::Constructor_c
| '$ConstructorList' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = escapeConstructorList(e, location=top.location); }

concrete productions top::StmtClause_c
| '$StmtClauses' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = escapeStmtClauses(e, location=top.location); }

concrete productions top::ExprClause_c
| '$ExprClauses' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = escapeExprClauses(e, location=top.location); }

concrete productions top::Pattern_c
| '$PatternList' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = escapePatternList(e, location=top.location); }
| '$Pattern' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = escapePattern(e, location=top.location); }
