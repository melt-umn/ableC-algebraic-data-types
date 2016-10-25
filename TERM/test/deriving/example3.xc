#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <string.xh>

typedef datatype Term Term;

bool eqTerm(Term*, Term*);

datatype Term {
  Abs(string, Term*);
  App(Term*, Term*);
  Var(const char*);
};

bool eqTerm(Term *t1, Term *t2) {
  match (t1) {
    Abs(_, a) -> {
      match(t2) {
        Abs(_, b) -> {return a == b;}
        _ -> {return false;}
      }
    }
    App(a, b) -> {
      match(t2) {
        App(c, d) -> {return a == c && b == d;}
        _ -> {return false;}
      }
    }
    Var(_) -> {
      match(t2) {
        Var(_) -> {return true;}
        _ -> {return false;}
      }
    }
  }
}

int main() {
  Term *zero_a = Abs("f", Abs("x", Var("x")));
  Term *one_a = Abs("f", Abs("x", App(Var("f"), Var("x"))));
  Term *two_a = Abs("f", Abs("x", App(Var("f"), App(Var("f"), Var("x")))));

  Term *zero_b = Abs("f", Abs("x", Var("x")));
  Term *one_b = Abs("f", Abs("x", App(Var("f"), Var("x"))));
  Term *two_b = Abs("f", Abs("x", App(Var("f"), App(Var("f"), Var("x")))));

  Term *zero_c = Abs("g", Abs("y", Var("y")));

  if (zero_a != zero_b)
    return 1;
  else if (one_a == two_b)
    return 2;
  if (zero_a != zero_c)
    return 3;
  return 0;
}
