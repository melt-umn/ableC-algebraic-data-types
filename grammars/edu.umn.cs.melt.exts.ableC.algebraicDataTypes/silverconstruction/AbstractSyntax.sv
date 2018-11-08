grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports silver:langutil:pp;
imports silver:reflect;

imports silver:definition:core;

imports edu:umn:cs:melt:exts:silver:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as ableC;

-- AbleC-to-Silver bridge productions
abstract production escapeConstructorList
top::Constructor ::= e::Expr
{
  top.pp = pp"$$ConstructorList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapeConstructorList");
}

abstract production escapeStmtClauses
top::StmtClause ::= e::Expr
{
  top.pp = pp"$$StmtClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapeStmtClauses");
}

abstract production escapeExprClauses
top::ExprClause ::= e::Expr
{
  top.pp = pp"$$ExprClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapeExprClauses");
}

abstract production escapePatternList
top::Pattern ::= e::Expr
{
  top.pp = pp"$$PatternList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapePatternList");
}

abstract production escapePattern
top::Pattern ::= e::Expr
{
  top.pp = pp"$$Pattern{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapePattern");
}

aspect production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs
{
  directEscapeProductions <-
    ["edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:escapePattern"];

  collectionEscapeProductions <-
    [pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:escapeConstructorList",
       pair("ConstructorList",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:consConstructor",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:appendConstructorList"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:escapeStmtClauses",
       pair("StmtClauses",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consStmtClause",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendStmtClauses"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:escapeExprClauses",
       pair("ExprClauses",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consExprClause",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendExprClauses"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:escapePatternList",
       pair("PatternList",
         pair(
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consPattern",
           "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendPatternList")))];
}
