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
  // Limit memory allocation to 1 MiB so in case of a bug the program doesn't use all memory and cause a freeze
  //struct rlimit rl = {1048576, 1048576};
  //setrlimit(RLIMIT_DATA, &rl);

  Term *zero_a = Abs("f", Abs("x", Var("x")));
  Term *one_a = Abs("f", Abs("x", App(Var("f"), Var("x"))));
  Term *two_a = Abs("f", Abs("x", App(Var("f"), App(Var("f"), Var("x")))));

  Term *zero_b = Abs("f", Abs("x", Var("x")));
  Term *one_b = Abs("f", Abs("x", App(Var("f"), Var("x"))));
  Term *two_b = Abs("f", Abs("x", App(Var("f"), App(Var("f"), Var("x")))));

  if (zero_a != zero_b)
    return 1;
  else if (one_a == two_b)
    return 2;
  return 0;
}
