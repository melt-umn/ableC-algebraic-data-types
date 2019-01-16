grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

terminal NamedPatternOp_t '@' precedence = 0, association = left, lexer classes {Csymbol};
terminal AntipatternOp_t  '!' precedence = 1, lexer classes {Csymbol};
terminal PointerOp_t      '&' precedence = 1, lexer classes {Csymbol};

terminal When_t 'when' lexer classes {Ckeyword};

closed nonterminal Pattern_c with location, ast<abs:Pattern>;

{- Constants, when used as patterns, cannot be followed by the '@'
   symbol introduced by the 'patternBoth' pattern production
   because the adds that symbol to their follow sets.  Adding them
   causes the modular determinism analysis to fail.

   This may seem odd to users of the extension since constants cannot
   be used in this way.

   An alternative would be to add '@' to the follow sets of constants
   in the host language.  We've opted against that here.
-}

concrete productions top::Pattern_c
| c::Constant_c
  { top.ast = abs:patternConst(c.ast, location=top.location); }
| '(' tn::TypeName_c ')' c::Constant_c
  { top.ast =
      abs:patternConst(
        explicitCastExpr(tn.ast, c.ast, location=top.location),
        location=top.location);
  }
| sl::StringConstant_c
  { top.ast = abs:patternStringLiteral(sl.ast, location=top.location); }
| p1::NonConstPattern_c '@' p2::Pattern_c
  { top.ast = abs:patternBoth(p1.ast, p2.ast, location=top.location); }
| AntipatternOp_t p1::Pattern_c
  { top.ast = abs:patternNot(p1.ast, location=top.location); }
| PointerOp_t p1::Pattern_c
  { top.ast = abs:patternPointer(p1.ast, location=top.location); }
| p1::BasicPattern_c
  { top.ast = p1.ast; }

closed nonterminal NonConstPattern_c with location, ast<abs:Pattern>;

concrete productions top::NonConstPattern_c
| p1::NonConstPattern_c '@' p2::NonConstPattern_c
  { top.ast = abs:patternBoth(p1.ast, p2.ast, location=top.location); }
| AntipatternOp_t p1::NonConstPattern_c
  { top.ast = abs:patternNot(p1.ast, location=top.location); }
| PointerOp_t p1::NonConstPattern_c
  { top.ast = abs:patternPointer(p1.ast, location=top.location); }
| p1::BasicPattern_c
  { top.ast = p1.ast; }

closed nonterminal BasicPattern_c with location, ast<abs:Pattern>;

concrete productions top::BasicPattern_c
| id::Identifier_c '(' ps::PatternList_c ')'
  { top.ast = abs:constructorPattern(id.ast, ps.ast, location=top.location); }
| id::Identifier_c '(' ')'
  { top.ast = abs:constructorPattern(id.ast, abs:nilPattern(), location=top.location); }
| '{' ps::StructPatternList_c '}'
  { top.ast = abs:structPattern(ps.ast, location=top.location); }
| '{' '}'
  { top.ast = abs:structPattern(abs:nilStructPattern(), location=top.location); }
| id::Identifier_t
  { top.ast =
      if id.lexeme == "_"
      then abs:patternWildcard(location=top.location)
      else abs:patternName(fromId(id), location=top.location);
  }
| 'when' '(' e::Expr_c ')'
  { top.ast = abs:patternWhen(e.ast, location=top.location); }
| '(' p1::Pattern_c ')'
  { top.ast = abs:patternParens(p1.ast, location=top.location); }


-- PatternList_c --
-----------------
nonterminal PatternList_c with location, ast<abs:PatternList>;

concrete productions top::PatternList_c
| p::Pattern_c ',' rest::PatternList_c
  { top.ast = abs:consPattern(p.ast, rest.ast); }
| p::Pattern_c
  { top.ast = abs:consPattern(p.ast, abs:nilPattern()); }


-- StructPatternList_c --
-----------------
nonterminal StructPatternList_c with location, ast<abs:StructPatternList>;

concrete productions top::StructPatternList_c
| p::StructPattern_c ',' rest::StructPatternList_c
  { top.ast = abs:consStructPattern(p.ast, rest.ast); }
| p::StructPattern_c
  { top.ast = abs:consStructPattern(p.ast, abs:nilStructPattern()); }


-- StructPattern_c --
-----------------
closed nonterminal StructPattern_c with location, ast<abs:StructPattern>;

concrete productions top::StructPattern_c
| p::Pattern_c
  { top.ast = abs:positionalStructPattern(p.ast, location=top.location); }
| '.' id::Identifier_c '=' p::Pattern_c
  { top.ast = abs:namedStructPattern(id.ast, p.ast, location=top.location); }
