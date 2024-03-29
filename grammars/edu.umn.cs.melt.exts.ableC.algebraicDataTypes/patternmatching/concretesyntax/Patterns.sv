grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

terminal NamedPatternOp_t '@' precedence = 0, association = left, lexer classes {Operator};
terminal AntipatternOp_t  '!' precedence = 1, lexer classes {Operator};
terminal PointerOp_t      '&' precedence = 1, lexer classes {Operator};

terminal When_t 'when' lexer classes {Keyword, Global};

-- Used to seed follow sets for MDA
terminal PatternNEVER_t 'PatternNEVER_t123456789!!!never';

closed tracked nonterminal Pattern_c with ast<abs:Pattern>;

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
  { top.ast = abs:patternConst(c.ast); }
| '(' tn::TypeName_c ')' c::Constant_c
  { top.ast =
      abs:patternConst(
        explicitCastExpr(tn.ast, c.ast)); }
| sl::StringConstant_c
  { top.ast = abs:patternStringLiteral(sl.ast); }
| p1::NonConstPattern_c '@' p2::Pattern_c
  { top.ast = abs:patternBoth(p1.ast, p2.ast); }
| AntipatternOp_t p1::Pattern_c
  { top.ast = abs:patternNot(p1.ast); }
| PointerOp_t p1::Pattern_c
  { top.ast = abs:patternPointer(p1.ast); }
| p1::BasicPattern_c
  { top.ast = p1.ast; }
-- Seed follow set with some extra terminals useful for extensions,
-- such as Prolog-style list patterns
| PatternNEVER_t Pattern_c ']'
  { top.ast = error("shouldn't occur in parse tree!"); }
| PatternNEVER_t Pattern_c '|'
  { top.ast = error("shouldn't occur in parse tree!"); }

closed tracked nonterminal NonConstPattern_c with ast<abs:Pattern>;

concrete productions top::NonConstPattern_c
| p1::NonConstPattern_c '@' p2::NonConstPattern_c
  { top.ast = abs:patternBoth(p1.ast, p2.ast); }
| AntipatternOp_t p1::NonConstPattern_c
  { top.ast = abs:patternNot(p1.ast); }
| PointerOp_t p1::NonConstPattern_c
  { top.ast = abs:patternPointer(p1.ast); }
| p1::BasicPattern_c
  { top.ast = p1.ast; }

closed tracked nonterminal BasicPattern_c with ast<abs:Pattern>;

concrete productions top::BasicPattern_c
(constructorPattern) | id::Identifier_c '(' ps::PatternList_c ')'
  { top.ast = abs:constructorPattern(id.ast, ps.ast); }
| id::Identifier_c '(' ')'
  { top.ast = abs:constructorPattern(id.ast, abs:nilPattern()); }
| '{' ps::StructPatternList_c '}'
  { top.ast = abs:structPattern(ps.ast); }
| '{' '}'
  { top.ast = abs:structPattern(abs:nilStructPattern()); }
| id::Identifier_t
  { top.ast =
      if id.lexeme == "_"
      then abs:patternWildcard()
      else abs:patternName(fromId(id));
  }
  action {
    context = addIdentsToScope([fromId(id)], Identifier_t, context);
  }
| 'when' '(' e::Expr_c ')'
  { top.ast = abs:patternWhen(e.ast); }
| '(' p1::Pattern_c ')'
  { top.ast = abs:patternParens(p1.ast); }


-- PatternList_c --
-----------------
tracked nonterminal PatternList_c with ast<abs:PatternList>;

concrete productions top::PatternList_c
| p::Pattern_c ',' rest::PatternList_c
  { top.ast = abs:consPattern(p.ast, rest.ast); }
| p::Pattern_c
  { top.ast = abs:consPattern(p.ast, abs:nilPattern()); }


-- StructPatternList_c --
-----------------
tracked nonterminal StructPatternList_c with ast<abs:StructPatternList>;

concrete productions top::StructPatternList_c
| p::StructPattern_c ',' rest::StructPatternList_c
  { top.ast = abs:consStructPattern(p.ast, rest.ast); }
| p::StructPattern_c
  { top.ast = abs:consStructPattern(p.ast, abs:nilStructPattern()); }


-- StructPattern_c --
-----------------
closed tracked nonterminal StructPattern_c with ast<abs:StructPattern>;

concrete productions top::StructPattern_c
| p::Pattern_c
  { top.ast = abs:positionalStructPattern(p.ast); }
| '.' id::Identifier_c '=' p::Pattern_c
  { top.ast = abs:namedStructPattern(id.ast, p.ast); }
