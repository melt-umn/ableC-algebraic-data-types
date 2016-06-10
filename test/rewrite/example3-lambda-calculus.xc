#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <gc.h>

#include <rewrite.xh>

typedef datatype Term Term;

datatype Term {
  Lambda  (const char*, Term*);
  Apply   (Term*, Term*);
  Var     (const char*);
};

bool occurs_free(const char *var, Term *term) {
  match (term) {
    Lambda(x, a) -> {return false;}
    Apply(a, b) -> {return occurs_free(var, a) || occurs_free(var, b);}
    Var(x) -> {return !strcmp(var, x);}
  }
}

// Manage creation of fresh variable names when needed
// We assume names in the original terms are all letters
int var_num = 0;
const char *get_free_var() {
  const char *res = GC_malloc(10);
  sprintf((char *)res, "%d", var_num);
  var_num++;
  return res;
}

// Performs a capture-avoiding substitution of target for sub when applied to a Term
static strategy substitute(const char *target, Term *sub);
rewrite rule substitute(const char *target, Term *sub) {
  rec (self) {
    try {
      choice {
        // Base cases
        visit (Term*) {
          // Do the subtitution if possible
          Var(n) -> !strcmp(n, target)? sub : Var(n);
          // If term is the same as the target, do nothing and be done
          // Otherwise fail and continue
          // TODO: make this a where pattern
          Lambda(n, a) -> !strcmp(n, target)? Lambda(n, a) : NULL;
        }
        sequence {
          // First check if alpha-conversion is needed
          try {
            visit (Term*) {
              // TODO: make this a where pattern
              Lambda(n, a) ->
                occurs_free(n, sub)?
                ({const char *new_var = get_free_var();
                  Lambda(new_var, a @ substitute(n, Var(new_var)));}) :
                NULL;
            }
          }
          // Then recursively perform the substitution
          all(self);
        }
      }
    }
  }
}

rewrite rule normalize() {
  sequence {
    outermost {
      visit (Term*) {
        // Beta-reduction
        Apply(Lambda(param, body), arg) -> body @ substitute(param, arg);
      }
    }
    outermost {
      visit (Term*) {
        // Eta-reduction
        // TODO: make this a where pattern
        Lambda(x, Apply(f, Var(y))) -> !strcmp(x, y) && !occurs_free(x, f)? f : NULL;
      }
    }
  }
}

Term *normalizeTerm(Term *term) {
  // Attempt to normalize the Term
  return term @ normalize();
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
  //Term *terms[] = {Apply(Lambda("x", Var("x")), Lambda("y", Var("y")))};
  for (int i = 0; i < sizeof(terms) / sizeof(Term*); i++) {
    printTerm(terms[i]);
    printf(": ");
    Term *res = normalizeTerm(terms[i]);
    if (res != NULL)
      printTerm(res);
    else 
      printf("Fail");
    printf("\n");
  }
}
