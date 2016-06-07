#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <rewrite.xh>

typedef datatype Term Term;

datatype Term {
  Lambda  (const char*, Term*);
  Apply   (Term*, Term*);
  Var     (const char*);
};

Term *evalTerm(Term *term) {
  rewrite rule substitute(const char *target, Term *newVal) {
    rec (self) {
      try {
        sequence {
          visit (Term*) {
            Var(n) -> !strcmp(n, target)? newVal : Var(n);
          }
          all(self);
        }
      }
    }
  }
  
  rewrite rule eval() {
    innermost {
      visit (Term*) {
        Apply(Lambda(param, body), arg) -> body @ substitute(param, arg);
      }
    }
  }

  return term @ eval();
}

void printTerm(Term *term) {
  match (term) {
  Lambda(n, e) -> {
      const char params[100];
      strcpy((char*)params, n);
      bool matched = true;
      while (matched) {
        match(e) {
        Lambda(n, e1) -> {strcat((char*)params, n); e = e1;}
        _ -> {matched = false;}
        }
      }
      printf("lambda %s . ", params);
      printTerm(e);
    }
  Apply(e1, e2) -> {
      match(e1) {
      Lambda(_, _) -> {
          printf("(");
          printTerm(e1);
          printf(")");
        }
      _ -> {printTerm(e1);}
      }
      printf(" ");
      match(e2) {
      Lambda(_, _) -> {
          printf("(");
          printTerm(e2);
          printf(")");
        }
      Apply(_, _) -> {
          printf("(");
          printTerm(e2);
          printf(")");
        }
      _ -> {printTerm(e2);}
      }
    }
  Var(n) -> {printf("%s", n);}
  }
}

int main() {
  Term *succ = Lambda("n", Lambda("f", Lambda("x", Apply(Var("f"), Apply(Apply(Var("n"), Var("f")), Var("x"))))));

  Term *zero = Lambda("f", Lambda("x", Var("x")));
  Term *one = Apply(succ, zero);
  Term *two = Apply(succ, one);
  Term *three = Apply(succ, two);

  Term *terms[] = {zero, one, two, three};
  for (int i = 0; i < sizeof(terms) / sizeof(Term*); i++) {
    printTerm(terms[i]);
    printf(": ");
    Term *res = evalTerm(terms[i]);
    if (res != NULL)
      printTerm(res);
    else 
      printf("Fail");
    printf("\n");
  }
}
