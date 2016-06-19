#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <string.xh>

typedef datatype Term Term;

datatype Term {
  Abs(string, Term*);
  App(Term*, Term*);
  Var(const char*);
};

int main() {
  Term *zero = Abs("f", Abs("x", Var("x")));
  Term *one = Abs("f", Abs("x", App(Var("f"), Var("x"))));
  Term *two = Abs("f", Abs("x", App(Var("f"), App(Var("f"), Var("x")))));

  string res0 = show(zero);
  printf("%s\n", res0);
  string res1 = show(one);
  printf("%s\n", res1);

  if (res0 != "Abs(\"f\", Abs(\"x\", Var(\"x\")))")
    return 1;
  //  else if (one_a == two_b)
  //    return 2;
  return 0;
}
