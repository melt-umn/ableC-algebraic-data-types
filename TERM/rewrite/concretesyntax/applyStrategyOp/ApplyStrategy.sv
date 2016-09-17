grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax:applyStrategyOp;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
--imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax as abs;

exports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax;

-- Spurious import, to trigger the tests on build.
--imports edu:umn:cs:melt:exts:ableC:rewrite:mda_test; -- Crashes

marking terminal ApplyStrategy_t '@';

concrete productions top::AddMulNoneOp_c
| '@'
    { top.ast = abs:applyStrategy(top.leftExpr, top.rightExpr,
        location=top.exprLocation); }
