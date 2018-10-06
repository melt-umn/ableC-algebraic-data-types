grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

import edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

terminal PatternName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier}; 
   -- Same as Identifier_t

disambiguate PatternName_t, TypeName_t
{
  pluck
    case lookupBy(stringEq, lexeme, head(context)) of
    | just(lh:typenameType_c()) -> TypeName_t
    | _ -> PatternName_t
    end;
}

terminal NamedPatternOp_t '@' precedence = 0, association = left, lexer classes {Csymbol};
terminal AntipatternOp_t  '!' precedence = 1, lexer classes {Csymbol};
terminal PointerOp_t      '&' precedence = 1, lexer classes {Csymbol};

terminal When_t 'when' lexer classes {Ckeyword};

nonterminal Pattern_c with location, ast<abs:Pattern>;
nonterminal ConstPattern_c with location, ast<abs:Pattern>;

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

nonterminal NonConstPattern_c with location, ast<abs:Pattern>;

concrete productions top::NonConstPattern_c
| p1::NonConstPattern_c '@' p2::NonConstPattern_c
  { top.ast = abs:patternBoth(p1.ast, p2.ast, location=top.location); }
| AntipatternOp_t p1::NonConstPattern_c
  { top.ast = abs:patternNot(p1.ast, location=top.location); }
| PointerOp_t p1::NonConstPattern_c
  { top.ast = abs:patternPointer(p1.ast, location=top.location); }
| p1::BasicPattern_c
  { top.ast = p1.ast; }

nonterminal BasicPattern_c with location, ast<abs:Pattern>;

concrete productions top::BasicPattern_c
| id::PatternName_t '(' ps::PatternList_c ')'
  { top.ast = abs:constructorPattern(id.lexeme, ps.ast, location=top.location); }
| id::PatternName_t '(' ')'
  { top.ast = 
      abs:constructorPattern(
        id.lexeme, abs:nilPattern(location=top.location),
        location=top.location);
  }
| id::PatternName_t
  { top.ast =
      if id.lexeme == "_"
      then abs:patternWildcard(location=top.location)
      else abs:patternVariable(id.lexeme, location=top.location);
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
  { top.ast = abs:consPattern(p.ast, rest.ast, location=top.location); }
| p::Pattern_c
  { top.ast = 
      abs:consPattern(p.ast, abs:nilPattern(location=top.location), location=p.location);
  }
