#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <gc.h>
//#include <sys/resource.h>

#include <rewrite.xh>
#include <string.xh>

typedef datatype Term Term;

datatype Term {
  Abs(string, Term*);
  App(Term*, Term*);
  Var(string);

  // Used in evaluation
  Let(string, Term*, Term*);
};

string ppTerm(Term *term) {
  match (term) {
    Abs(n, e) -> {
      string res = "\\";
      res += n;
      bool matched = true;
      while (matched) {
        match(e) {
          Abs(n, e1) -> {res += n; e = e1;}
          _ -> {matched = false;}
        }
      }
      res += ". ";
      return res + ppTerm(e);
    }
    App(e1, e2) -> {
      return match(e1)
        (Abs(_, _) -> "(" + ppTerm(e1) + ")";
         Let(_, _, _) -> "(" + ppTerm(e1) + ")";
         _ -> ppTerm(e1);) + match(e2)
        (Abs(_, _) -> "(" + ppTerm(e2) + ")";
         App(_, _) -> "(" + ppTerm(e2) + ")";
         Let(_, _, _) -> "(" + ppTerm(e1) + ")";
         _ -> ppTerm(e2););
    }
    Var(n) -> {return n;}
    Let(n, e1, e2) ->
      {return "let " + n + "=" + ppTerm(e1) + " in " + ppTerm(e2);}
  }
}

/*
bool occurs_free(const char *var, Term *term) {
  match (term) {
    Abs(x, a) -> {return false;}
    App(a, b) -> {return occurs_free(var, a) || occurs_free(var, b);}
    Var(x) -> {return !strcmp(var, x);}
  }
}
*/

// Manage creation of fresh variable names when needed
// We assume names in the original terms are all letters
const char *get_fresh_var() {
  static int var_num = 0;
  return str(var_num++);
}
/*
// Performs a capture-avoiding substitution of target for sub when applied to a Term
newstrategy substitute(const char *target, Term *sub) {
  rec (self) {
    try {
      choice {
        // Base cases
        visit (Term*) {
          // Do the substitution if possible
          Var(n)@when(n == target) -> sub;
          Var(n) -> Var(n);

          // If term is the same as the target, do nothing and be done
          // Otherwise fail and continue
          Abs(n, a)@when(n == target) -> Abs(n, a);
        }
        sequence {
          // First check if alpha-conversion is needed
          try {
            visit (Term*) {
              Abs(n, a)@when(occurs_free(n, sub)) ->
                ({string new_var = get_fresh_var();
                  Abs(new_var, a @ substitute(n, Var(new_var)));});
            }
          }
          // Then recursively perform the substitution
          all(self);
        }
      }
    }
  }
}

newstrategy reduce() {
  visit (Term*) {
    // Beta-reduction
    App(Abs(param, body), arg) -> body @ substitute(param, arg);

    // Eta-reduction
    Abs(x, App(f, Var(y)))@when(x == y && !occurs_free(x, f)) -> f;
  }
}
*/

newstrategy reduce() {
  visit (Term*) {
    // beta
    App(Abs(x, e1), e2) -> Let(x, e2, e1);

    // subsVar
    Let(x, e, Var(y))@when(x == y) -> e;
    Let(_, _, v@Var(_))            -> v;

    // subsApp
    Let(x, e, App(e1, e2)) -> App(Let(x, e, e1), Let(x, e, e2));

    // subsLam
    Let(x, e1, Abs(y, e2))@when(x == y) -> Abs(y, e1);
    Let(x, e1, Abs(y, e2)) -> 
      ({string z = get_fresh_var();
        Abs(z, Let(x, e1, Let(y, Var(z), e2)));});
  }
}

newstrategy normalize() {
  // TODO: I think this is the same as outermost?
  repeat {
    onceTopDown {
      sequence {
        print("term: %s\n", ppTerm(term));
        reduce();
        print("reduced: %s\n", ppTerm(term));
      }
    }
  }
}

newstrategy normalize_hnf() {
  rec (self) {
    sequence {
      //print("term: %s\n", showTerm(term));
      try {
        visit (Term*) {
          App(a, b) -> App(a @ self, b @ self);
        }
      }
      try {
        sequence {
          reduce();
          self;
        }
      }
    }
  }
}

int decode_num(Term *term) {
  match (term) {
    Abs(_, Abs(a, Var(b)))@when (a == b) -> {return 0;}
    Abs(a, Var(b))@when (a == b) -> {return 1;}
    Abs(a, Abs(b, App(Var(c), t)))@when (a == c) ->
      {return decode_num(Abs(a, Abs(b, t))) + 1;}
    _ -> {
      printf("Error: %s does not correspond to a Church numeral\n", ppTerm(term));
      exit(1);
    }
  }
}

int decode_num_hnf(Term *term) {
  match (term) {
    Abs(_, Abs(a, Var(b)))@when (a == b) -> {return 0;}
    Abs(a, Var(b))@when (a == b) -> {return 1;}
    Abs(a, Abs(b, App(Var(c), t)))@when (a == c) ->
      {return decode_num(Abs(a, Abs(b, t)) @ normalize_hnf()) + 1;}
    _ -> {
      printf("Error: %s does not correspond to a Church numeral\n", ppTerm(term));
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

  Term *id_e = Abs("x", Var("x"));

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

  //Term *t = three_e;
  //printf("%s: %s\n", ppTerm(t), ppTerm(t @ normalize()));

  Term *terms[] = {one_e};//, App(fact_e, one_e)};
  for (int i = 0; i < sizeof(terms) / sizeof(Term*); i++) {
    printf("%s: ", ppTerm(terms[i]));
    Term *res = normalize()(terms[i]);
    if (res != NULL) {
      printf("\n%s\n", ppTerm(res));
      printf("%d\n", decode_num(res));
    }
    else
      printf("Fail\n");
  }
}
