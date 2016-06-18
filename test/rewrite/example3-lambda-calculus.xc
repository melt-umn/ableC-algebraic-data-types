#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <gc.h>
//#include <sys/resource.h>

#include <rewrite.xh>

typedef datatype Term Term;

datatype Term {
  Abs(const char*, Term*);
  App(Term*, Term*);
  Var(const char*);
};

const char *showTerm(Term *term, const char *buffer) {
  match (term) {
    Abs(n, e) -> {
      strcat((char*)buffer, "\\");
      strcat((char*)buffer, n);
      bool matched = true;
      while (matched) {
        match(e) {
          Abs(n, e1) -> {strcat((char*)buffer, n); e = e1;}
          _ -> {matched = false;}
        }
      }
      return showTerm(e, buffer);
    }
    App(e1, e2) -> {
      match(e1) {
        Abs(_, _) -> {
          strcat((char*)buffer, "(");
          showTerm(e1, buffer);
          strcat((char*)buffer, ")");
        }
        _ -> {showTerm(e1, buffer);}
      }
      strcat((char*)buffer, " ");
      match(e2) {
        Abs(_, _) -> {
          strcat((char*)buffer, "(");
          showTerm(e2, buffer);
          strcat((char*)buffer, ")");
        }
        App(_, _) -> {
          strcat((char*)buffer, "(");
          showTerm(e2, buffer);
          strcat((char*)buffer, ")");
        }
        _ -> {showTerm(e2, buffer);}
      }
      return buffer;
    }
    Var(n) -> {
      strcat((char*)buffer, n);
      return buffer;
    }
  }
}

bool occurs_free(const char *var, Term *term) {
  match (term) {
    Abs(x, a) -> {return false;}
    App(a, b) -> {return occurs_free(var, a) || occurs_free(var, b);}
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
newstrategy substitute(const char *target, Term *sub) {
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
          Abs(n, a) -> !strcmp(n, target)? Abs(n, a) : NULL;
        }
        sequence {
          // First check if alpha-conversion is needed
          try {
            visit (Term*) {
              // TODO: make this a where pattern
              Abs(n, a) ->
                occurs_free(n, sub)?
                ({const char *new_var = get_free_var();
                  Abs(new_var, a @ substitute(n, Var(new_var)));}) :
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

newstrategy normalize() {
  // TODO: I think this is the same as outermost?
  repeat {
    onceTopDown {
      visit (Term*) {
        // Beta-reduction
        App(Abs(param, body), arg) -> body @ substitute(param, arg);
        // Eta-reduction
        // TODO: make this a where pattern
        Abs(x, App(f, Var(y))) -> !strcmp(x, y) && !occurs_free(x, f)? f : NULL;
      }
    }
  }
}

char buf[1000];
newstrategy normalize_hnf() {
  print("term: %s\n", showTerm(term, (const char*)buf));
  rec (self) {
    try {
      // TODO
      visit (Term*) {
        App(Abs(param, body), arg) -> ((body @ substitute(param, arg)) @ self);
        Abs(param, body) -> Abs(param, body @ self);
      }
    }
  }
}

int decode_num(Term *term) {
  match (term) {
    Abs(_, Abs(a, Var(b)))@when (!strcmp(a, b)) -> {return 0;}
    Abs(a, Var(b))@when (!strcmp(a, b)) -> {return 1;}
    Abs(a, Abs(b, App(Var(c), t)))@when (!strcmp(a, c)) ->
      {return decode_num(normalize_hnf()(Abs(a, Abs(b, t)))) + 1;}
    _ -> {
      char buf[1000];
      buf[0] = '\0';
      printf("Error: %s does not correspond to a Church numeral\n", showTerm(term, (const char*)buf));
      exit(1);
    }
  }
}

int main() {
  // Limit memory allocation to 1 MiB so in case of a bug the program doesn't use all memory and cause a freeze
  //struct rlimit rl = {1048576, 1048576};
  //setrlimit(RLIMIT_DATA, &rl);

  Term *succ_e =
    Abs("n", Abs("f", Abs("x", App(Var("f"), App(App(Var("n"), Var("f")), Var("x"))))));

  Term *zero_e = Abs("f", Abs("x", Var("x")));
  Term *one_e = App(succ_e, zero_e);
  Term *two_e = App(succ_e, one_e);
  Term *three_e = App(succ_e, two_e);

  Term *true_e = Abs("x", Abs("y", Var("x")));
  Term *false_e = Abs("x", Abs("y", Var("y")));

  Term *pair_e = Abs("x", Abs("y", Abs("f", App(App(Var("f"), Var("x")), Var("y")))));
  Term *fst_e = Abs("p", App(Var("p"), true_e));
  Term *snd_e = Abs("p", App(Var("p"), false_e));

  Term *prefn_e =
    Abs("f",
        Abs("p",
            App(App(pair_e, App(Var("f"), App(fst_e, Var("p")))),
                App(fst_e, Var("p")))));
  Term *pre_e =
    Abs("n",
        Abs("f",
            Abs("x",
                App(snd_e,
                    App(App(Var("n"), App(prefn_e, Var("f"))),
                        App(App(pair_e, Var("x")), Var("x")))))));
  Term *mult_e = 
    Abs("m",
        Abs("n",
            Abs("f",
                Abs("x",
                    App(App(Var("m"), App(Var("n"), Var("f"))),
                        Var("x"))))));

  Term *iszero_e = Abs("n", App(App(Var("n"), Abs("x", false_e)), true_e));

  Term *y_e =
    Abs("f", App(Abs("x", App(Var("f"), App(Var("x"), Var("x")))),
                 Abs("x", App(Var("f"), App(Var("x"), Var("x"))))));

  Term *fact_e =
    App(y_e,
        Abs("g",
            Abs("x",
                App(App(App(iszero_e, Var("x")), one_e),
                    App(App(mult_e, Var("x")),
                        App(Var("g"), App(pre_e, Var("x"))))))));

  Term *terms[] = {App(App(mult_e, two_e), two_e)};//, App(fact_e, one_e)};
  char buf[1000];
  buf[0] = '\0';
  for (int i = 0; i < sizeof(terms) / sizeof(Term*); i++) {
    printf("%s: ", showTerm(terms[i], (const char*)buf));
    Term *res = normalize_hnf()(terms[i]);
    if (res != NULL) {
      printf("\n%s\n", showTerm(res, (const char*)buf));
      //printf("%d\n", decode_num(res));
    }
    else 
      printf("Fail\n");
  }
}
