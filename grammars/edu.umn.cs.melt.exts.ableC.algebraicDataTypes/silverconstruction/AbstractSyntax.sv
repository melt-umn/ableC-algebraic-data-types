grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports silver:langutil:pp;
imports silver:metatranslation;
imports silver:reflect;

imports silver:definition:core;

imports edu:umn:cs:melt:exts:silver:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as ableC;

-- AbleC-to-Silver bridge productions
abstract production antiquoteConstructorList
top::Constructor ::= e::Expr
{
  top.pp = pp"$$ConstructorList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquoteConstructorList");
}

abstract production antiquoteStmtClauses
top::StmtClause ::= e::Expr
{
  top.pp = pp"$$StmtClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquoteStmtClauses");
}

abstract production antiquoteExprClauses
top::ExprClause ::= e::Expr
{
  top.pp = pp"$$ExprClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquoteExprClauses");
}

abstract production antiquotePatternList
top::Pattern ::= e::Expr
{
  top.pp = pp"$$PatternList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquotePatternList");
}

abstract production antiquotePattern
top::Pattern ::= e::Expr
{
  top.pp = pp"$$Pattern{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquotePattern");
}

aspect production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs
{
  directAntiquoteProductions <-
    ["edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquotePattern"];

  collectionAntiquoteProductions <-
    [pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteConstructorList",
       pair("ConstructorList",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:consConstructor",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:appendConstructorList"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteStmtClauses",
       pair("StmtClauses",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consStmtClause",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendStmtClauses"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteExprClauses",
       pair("ExprClauses",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consExprClause",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendExprClauses"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquotePatternList",
       pair("PatternList",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consPattern",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendPatternList")))];
}
