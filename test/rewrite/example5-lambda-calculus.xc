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

typedef struct nameEnv nameEnv;

struct nameEnv {
  const char *name;
  const char *trans;
  nameEnv *next;
};

typedef datatype RenameTerm RenameTerm;

datatype RenameTerm {
  NameEnvTerm(nameEnv*, Term*);
};

Term *evalTerm(Term *term) {
  int *varNum = gcnew(int);

  rewrite rule rename() {
    sequence {
      visit (Term*) {
        Lambda(n, t) -> NameEnvTerm(NULL, Lambda(n, t)); // TODO: Fix NoParent error
        Apply(t1, t2) -> NameEnvTerm(NULL, Apply(t1, t2));
        Var(n) -> NameEnvTerm(NULL, Var(n));
      }

      topDown {
        try {
          visit (RenameTerm*) {
            NameEnvTerm(env, Lambda(name, e)) -> ({
                const char *newName = malloc(20);
                sprintf((char*)newName, "%s%d", name, *varNum); // Need cast due to ableC bug...
                printf("New name: %s -> %s\n", name, newName);
                (*varNum)++;
                nameEnv *newEnv = gcnew(nameEnv);
                *newEnv = (struct nameEnv){name, newName, env};
                printf("New name: %s -> %s\n", name, newName);
                RenameTerm *res = NameEnvTerm(newEnv, Lambda(newName, e));
                res;
              });
            NameEnvTerm(env, Var(name)) -> ({
                const char *newName = name;
                nameEnv *tempEnv = env;
                while (tempEnv) {
                  if (!strcmp(name, tempEnv->name))
                    newName = tempEnv->trans;
                  tempEnv = tempEnv->next;
                }

                NameEnvTerm(env, Var(newName));
              });
          }
        }
      }
    }
  }

  rewrite rule substitute(const char *target, Term *newVal) {
    bottomUp {
      try {
        visit (Term*) {
          Var(n) -> !strcmp(n, target)? newVal : Var(n);
        }
      }
    }
  }

  rewrite rule eval() {
    sequence {
      rename();
      innermost {
        visit (Term*) {
          Apply(Lambda(param, body), arg) -> body @ substitute(param, arg);
        }
      }
    }
  }

  return term @ rename();
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

  Term *terms[] = {Var("x"), zero, one, two, three};
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
