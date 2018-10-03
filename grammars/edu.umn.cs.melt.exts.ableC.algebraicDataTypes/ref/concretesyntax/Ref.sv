grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:ref:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:ref:abstractsyntax;

marking terminal Ref_t 'ref' lexer classes {Ckeyword};

marking terminal MallocRefOp_t '&#' lexer classes {Ckeyword};

concrete production refExpr_c
top::PrimaryExpr_c ::= 'ref' '(' e::AssignExpr_c ',' alloc::Expr_c ')'
{ top.ast = refExpr(e.ast, alloc.ast, location=top.location); }

concrete production mallocRefOp_c
top::UnaryOp_c ::= '&#'
{ top.ast = mallocRefExpr(top.expr, location=top.location); }
