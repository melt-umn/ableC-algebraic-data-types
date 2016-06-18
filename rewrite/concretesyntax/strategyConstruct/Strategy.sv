grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax:strategyConstruct;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax as abs;
imports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax as abs;

exports edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:concretesyntax;

-- trigger the test
import edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:mda_test;

terminal Extends_t 'extends';

lexer class StrategyKeyword;
terminal Visit_t     'visit' lexer classes {StrategyKeyword};
terminal Print_t     'print' lexer classes {StrategyKeyword};
terminal Rec_t       'rec'   lexer classes {StrategyKeyword};
terminal IfVisit_t   'if'    lexer classes {StrategyKeyword};
terminal ElseVisit_t 'else'  lexer classes {StrategyKeyword}, precedence = 2, association = left;

terminal StrategyName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ submits to {StrategyKeyword};

concrete production strategy_c
e::Declaration_c ::= 'newstrategy' s::Strategy
{
  e.ast = s.ast;
}

nonterminal Strategy with ast<Decl>, location;

concrete production strategyDecl_c
s::Strategy ::= n::Identifier_t extends::Extends '{' visits::VisitList '}'
{
  s.ast =
    abs:strategyDecl(
      fromId(n),
      extends.ast,
      visits.ast);
}

concrete production strategyDeclParams_c
s::Strategy ::= n::Identifier_t '(' params::ParameterList_c ')' extends::Extends '{' visits::VisitList '}'
{
  s.ast =
    abs:strategyDeclParams(
      fromId(n),
      foldParameterDecl(params.ast),
      extends.ast,
      visits.ast);
}

concrete production strategyDeclEmptyParams_c
s::Strategy ::= n::Identifier_t '(' ')' extends::Extends '{' visits::VisitList '}'
{
  s.ast =
    abs:strategyDeclParams(
      fromId(n),
      nilParameters(),
      extends.ast,
      visits.ast);
}

-- TODO: remove this
nonterminal Extends with ast<Expr>;

concrete productions top::Extends
  | 'extends' '(' base::Expr_c ')'
  {
    top.ast = base.ast;
  }
  |
  {
    top.ast = abs:failStrategy;
  }

nonterminal VisitList with ast<abs:VisitList>;

concrete productions top::VisitList
  | v::Visit rest::VisitList
  {
    top.ast = abs:consVisitList(v.ast, rest.ast);
  }
  |
  {
    top.ast = abs:nilVisitList();
  }

nonterminal Visit with location, ast<abs:Visit>;

concrete production strategyVisit
top::Visit ::= '(' e::Expr_c ')' ';'
{
  top.ast = abs:strategyVisit(e.ast, location=top.location);
}

concrete production strategyVisitParams
top::Visit ::= '(' e::Expr_c ')' '{' params::VisitList '}'
{
  top.ast = abs:strategyVisitParams(e.ast, params.ast, location=top.location);
}

concrete production idVisitParams
top::Visit ::= id::StrategyName_t '(' args::ArgumentExprList_c ')' ';'
{
  top.ast =
    abs:strategyVisit(
      directCallExpr(
        fromStrategyName(id),
        foldExpr(args.ast),
        location=abs:builtIn()),
      location=top.location);
}

concrete production idVisitNoParams
top::Visit ::= id::StrategyName_t '(' ')' ';'
{
  top.ast =
    abs:strategyVisit(
      directCallExpr(
        fromStrategyName(id),
        nilExpr(),
        location=abs:builtIn()),
      location=top.location);
}

concrete production idVisitBlockParams
top::Visit ::= id::StrategyName_t '{' visits::VisitList '}'
{
  top.ast = abs:idVisitParams(fromStrategyName(id), visits.ast, location=top.location);
}

concrete production idVisit
top::Visit ::= id::StrategyName_t ';'
{
  top.ast = abs:idVisit(fromStrategyName(id), location=top.location);
}

concrete production printVisit
top::Visit ::= 'print' '(' args::ArgumentExprList_c ')' ';'
{
  top.ast = abs:printVisit(foldExpr(args.ast), location=top.location);
}

concrete production ruleVisit
top::Visit ::= 'visit' '(' type::TypeName_c ')' '{' cs::ExprClauses '}'
{
  top.ast = abs:ruleVisit(type.ast, cs.ast, location=top.location);
}

concrete production condVisitElse
top::Visit ::= IfVisit_t '(' c::Expr_c ')' th::Visit ElseVisit_t el::Visit
{
  top.ast = abs:condVisit(c.ast, th.ast, el.ast, location=top.location);
}

concrete production condVisitNoElse
top::Visit ::= IfVisit_t '(' c::Expr_c ')' th::Visit
{
  top.ast =
    abs:condVisit(
      c.ast,
      th.ast,
      abs:strategyVisit(
        abs:failStrategy,
        location=abs:builtIn()),
      location=top.location);
}

concrete production recStrategyVisit
top::Visit ::= 'rec' '(' id::Identifier_t ')' '{' body::Visit '}'
{
  top.ast = abs:recStrategyVisit(fromId(id), body.ast, location=top.location);
}

function fromStrategyName
Name ::= id::StrategyName_t
{
  return name(id.lexeme, location=id.location);
}
