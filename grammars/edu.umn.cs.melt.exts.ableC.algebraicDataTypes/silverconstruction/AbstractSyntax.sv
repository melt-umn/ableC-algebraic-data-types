grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;

imports silver:langutil:pp;
imports silver:reflect;

imports silver:compiler:definition:core;
imports silver:compiler:metatranslation;

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
    [("edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteConstructorList",
      "ConstructorList",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:consConstructor",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:nilConstructor",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:appendConstructorList"),
     ("edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteStmtClauses",
      "StmtClauses",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consStmtClause",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:nilStmtClause",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendStmtClauses"),
     ("edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquoteExprClauses",
      "ExprClauses",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consExprClause",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:nilExprClause",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendExprClauses"),
     ("edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction:antiquotePatternList",
      "PatternList",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:consPattern",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:nilPattern",
      "edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:abstractsyntax:appendPatternList")];
}
