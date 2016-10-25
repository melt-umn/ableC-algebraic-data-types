grammar edu:umn:cs:melt:exts:ableC:algDataTypes:src:patternmatching:concretesyntax:patterns;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:src:patternmatching:abstractsyntax as abs ;

terminal PatternName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier}; 
   -- Same as Identifier_t

terminal NamedPatternOp_t '@' precedence = 0, lexer classes {Csymbol};
terminal AntipatternOp_t '!'  precedence = 1, lexer classes {Csymbol};

terminal When_t 'when' lexer classes {Ckeyword};

nonterminal Pattern with location, ast<abs:Pattern> ;

{- We need to have algebraic datatype patterns here.  They can't be in
   an extension to algDataTypes since they don't begin with a
   marking terminal.  -}

concrete productions p::Pattern
| id::PatternName_t '(' ps::PatternList ')'
  { p.ast = abs:constructorPattern( id.lexeme, ps.ast, location=p.location );
  }

| id::PatternName_t '(' ')'
  { p.ast = 
      abs:constructorPattern( id.lexeme, abs:nilPattern(location=p.location),
        location=p.location );
  }

-- | id::Identifier_t
| id::PatternName_t   -- why use this?
  { p.ast = if id.lexeme == "_"
            then abs:patternWildcard( location=p.location )
            else abs:patternVariable( id.lexeme, location=p.location );
  }

|  p1::Pattern '@' p2::Pattern
  { p.ast = 
      abs:patternBoth( p1.ast, p2.ast,
        location=p.location );
  }

| op::AntipatternOp_t p1::Pattern
  { p.ast = 
      abs:patternNot( p1.ast,
        location=p.location );
  }

| 'when' '(' e::Expr_c ')'
  { p.ast = abs:patternWhen( e.ast, location=p.location );
  }


-- PatternList --
-----------------
nonterminal PatternList with location, ast<abs:PatternList> ;

concrete productions ps::PatternList
| p::Pattern ',' rest::PatternList
  { ps.ast = abs:consPattern( p.ast, rest.ast, location=ps.location ); }

| p::Pattern
  { ps.ast = 
      abs:consPattern( p.ast, abs:nilPattern(location=ps.location),
        location=p.location ); 
  }


-- TODO: This is only allowing constPattern as the last element in PatternList?  
| p::ConstPattern ',' rest::PatternList
  { ps.ast = abs:consPattern( p.ast, rest.ast, location=ps.location ); }

| p::ConstPattern
  { ps.ast = 
      abs:consPattern( p.ast, abs:nilPattern(location=ps.location),
        location=p.location ); 
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

concrete productions p::ConstPattern
| c::Constant_c 
    { p.ast = abs:patternConst(c.ast, location=p.location); }

| sl::StringConstant_c
    { p.ast = abs:patternStringLiteral(sl.ast, location=p.location); }
