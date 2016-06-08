#include <stdio.h>
#include <stdlib.h>

#include <rewrite.xh>

typedef datatype Expr Expr;

datatype Expr {
  And   (Expr*, Expr*);
  Or    (Expr*, Expr*);
  Not   (Expr*);
  True  ();
  False ();
};

bool exprEq(Expr *e1, Expr *e2) {
  if (e1 == NULL && e2 == NULL)
    return true;
  else if (e1 == NULL || e2 == NULL)
    return false;
  else
    return match(e1)
      (And(a, b) -> match(e2) (And(c, d) -> exprEq(a, c) && exprEq(b, d); _ -> false;);
       Or(a, b) -> match(e2) (Or(c, d) -> exprEq(a, c) && exprEq(b, d); _ -> false;);
       Not(a) -> match(e2) (Not(b) -> exprEq(a, b); _ -> false;);
       True() -> match(e2) (True() -> true; _ -> false;);
       False() -> match(e2) (False() -> true; _ -> false;););
}

Expr *evalExpr(Expr *expr) {
  rewrite rule eval() {
    innermost {
      choice {
        // Simplify and
        visit (Expr*) {
          And(True(), True()) -> True();
          And(_, False()) -> False();
          And(False(), _) -> False();
          And(a, True()) -> a;
          And(True(), b) -> b;
        }

        // Simplify or
        visit (Expr*) {
          Or(False(), False()) -> False();
          Or(_, True()) -> True();
          Or(True(), _) -> True();
          Or(a, False()) -> a;
          Or(False(), b) -> b;
        }

        // Simplify not
        visit (Expr*) {
          Not(True()) -> False();
          Not(False()) -> True();
        }
      }
    }
  }

  return expr @ eval();
}

void printExpr(Expr *expr) {
  match (expr) {
  And(e1, e2) -> {
      match(e1) {
      Or(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      _ -> {printExpr(e1);}
      }
      printf(" ^ ");
      match(e2) {
      Or(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      _ -> {printExpr(e2);}
      }
    }
  Or(e1, e2) -> {
      match(e1) {
      And(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      _ -> {printExpr(e1);}
      }
      printf(" v ");
      match(e2) {
      And(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      _ -> {printExpr(e2);}
      }
    }
  Not(e) -> {
      printf("~");
      match(e) {
      And(_, _) -> {
          printf("(");
          printExpr(e);
          printf(")");
        }
      Or(_, _) -> {
          printf("(");
          printExpr(e);
          printf(")");
        }
      _ -> {printExpr(e);}
      }
    }
  True() -> {printf("T");}
  False() -> {printf("F");}
  }
}

int main() {
  Expr *exprs[] = {True(),
                   Or(True(), False()),
                   Or(False(), Or(True(), False())),
                   Not(Or(True(), False())),
                   And(Or(Not(Not(True())), True()), Not(False())),
                   And(Or(Not(Not(Not(Not(True())))), True()), Not(Or(False(), False())))};
  Expr *expectedResults[] = {True(),
                             True(),
                             True(),
                             False(),
                             True(),
                             True()};
  int result = 0;
  for (int i = 0; i < sizeof(exprs) / sizeof(Expr*); i++) {
    printExpr(exprs[i]);
    printf(": ");
    Expr *res = evalExpr(exprs[i]);
    if (res != NULL)
      printExpr(res);
    else 
      printf("Fail");
    printf("\n");

    if (!exprEq(res, expectedResults[i]) && result == 0)
      result = i + 1;
  }

  return result;
}
