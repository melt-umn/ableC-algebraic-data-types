grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax:recStrategyOp;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax as abs;

exports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax;

-- Spurious import, to trigger the tests on build.
--imports edu:umn:cs:melt:exts:ableC:rewrite:mda_test; -- Crashes

marking terminal RecStrategy_t 'recstrategy' lexer classes {Ckeyword};

-- TODO: Get rid of parentheses?
concrete productions top::PrimaryExpr_c
| 'recstrategy' id::Identifier_t '.' '(' body::Expr_c ')'
    { top.ast = abs:recStrategy(fromId(id), body.ast,
        location=top.location); }
