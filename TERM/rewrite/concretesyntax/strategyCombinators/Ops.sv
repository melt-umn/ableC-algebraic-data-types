grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax:strategyCombinators;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
--imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax as abs;

exports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax;

-- Spurious import, to trigger the tests on build.
imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:mda_test;

marking terminal Choice_t '<+';
marking terminal Sequence_t '<*';

concrete productions top::AdditiveOp_c
| '<+'
  { top.ast =
      directCallExpr(
        name("choice", location=top.exprLocation),
        consExpr(top.leftExpr, consExpr(top.rightExpr, nilExpr())),
        location=top.exprLocation); }
| '<*'
  { top.ast =
      directCallExpr(
        name("sequence", location=top.exprLocation),
        consExpr(top.leftExpr, consExpr(top.rightExpr, nilExpr())),
        location=top.exprLocation); }