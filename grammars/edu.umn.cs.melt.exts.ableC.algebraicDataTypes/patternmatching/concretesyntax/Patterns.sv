grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

terminal PatternName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier}; 
   -- Same as Identifier_t

terminal NamedPatternOp_t '@' precedence = 0, lexer classes {Csymbol};
terminal AntipatternOp_t  '!' precedence = 1, lexer classes {Csymbol};
terminal PointerOp_t      '&' precedence = 1, lexer classes {Csymbol};

terminal When_t 'when' lexer classes {Ckeyword};

nonterminal Pattern with location, ast<abs:Pattern>;

{- We need to have algebraic datatype patterns here.  They can't be in
   an extension to algebraicDataTypes since they don't begin with a
   marking terminal.  -}

concrete productions top::Pattern
| id::PatternName_t '(' ps::PatternList ')'
  { top.ast = abs:constructorPattern(id.lexeme, ps.ast, location=top.location); }

| id::PatternName_t '(' ')'
  { top.ast = 
      abs:constructorPattern(id.lexeme, abs:nilPattern(location=top.location),
        location=top.location);
  }

-- | id::Identifier_t
| id::PatternName_t   -- why use this?
  { top.ast = if id.lexeme == "_"
            then abs:patternWildcard(location=top.location)
            else abs:patternVariable(id.lexeme, location=top.location);
  }

|  p1::Pattern '@' p2::Pattern
  { top.ast = abs:patternBoth(p1.ast, p2.ast, location=top.location); }

| AntipatternOp_t p1::Pattern
  { top.ast = abs:patternNot(p1.ast, location=top.location); }

| PointerOp_t p1::Pattern
  { top.ast = abs:patternPointer(p1.ast, location=top.location); }

| 'when' '(' e::Expr_c ')'
  { top.ast = abs:patternWhen(e.ast, location=top.location); }

| '(' p1::Pattern ')'
  { top.ast = abs:patternParens(p1.ast, location=top.location); }

| '(' p1::ConstPattern ')'
  { top.ast = abs:patternParens(p1.ast, location=top.location); }


-- PatternList --
-----------------
nonterminal PatternList with location, ast<abs:PatternList> ;

concrete productions top::PatternList
| p::Pattern ',' rest::PatternList
  { top.ast = abs:consPattern(p.ast, rest.ast, location=top.location); }

| p::Pattern
  { top.ast = 
      abs:consPattern(p.ast, abs:nilPattern(location=top.location),
        location=p.location);
  }


-- TODO: This is only allowing constPattern as the last element in PatternList?  
| p::ConstPattern ',' rest::PatternList
  { top.ast = abs:consPattern(p.ast, rest.ast, location=top.location); }

| p::ConstPattern
  { top.ast = 
      abs:consPattern(p.ast, abs:nilPattern(location=top.location),
        location=p.location);
  }


-- ConstPattern --
------------------

{- Constants, when used as patterns, cannot be followed by the '@'
   sybmol introduced by the 'patternBoth' pattern production above
   because the adds that symbol to their follow sets.  Adding them
   causes the modular determinism analysis to fail.

   This may seem odd to users of the extension since constants cannot
   be used in this way.

   An alternative would be to add '@' to the follow sets of constants
   in the host language.  We've opted against that here.
-}

nonterminal ConstPattern with location, ast<abs:Pattern> ;

concrete productions top::ConstPattern
| c::Constant_c
    { top.ast = abs:patternConst(c.ast, location=top.location); }

| sl::StringConstant_c
    { top.ast = abs:patternStringLiteral(sl.ast, location=top.location); }
