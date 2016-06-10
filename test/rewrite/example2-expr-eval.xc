#include <stdio.h>
#include <stdlib.h>

#include <rewrite.xh>

typedef datatype Expr Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Sub (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Div (Expr*, Expr*);
  Const (int);
};

Expr *evalExpr(Expr *expr) {
  rewrite rule eval() {
    innermost {
      choice {
        // Simplify
        visit (Expr*) {
          Mul(_, Const(0)) -> Const(0);
          Mul(Const(0), _) -> Const(0);
          Mul(e1, Const(1)) -> e1;
          Mul(Const(1), e2) -> e2;
          Div(Const(0), _) -> Const(0);
          Div(e1, Const(1)) -> e1;
        }

        // Evaluate
        visit (Expr*) {
          Add(Const(a), Const(b)) -> Const(a + b);
          Sub(Const(a), Const(b)) -> Const(a - b);
          Mul(Const(a), Const(b)) -> Const(a * b);
          Div(Const(a), Const(b)@!Const(0)) -> Const(a / b);
        }
      }
    }
  }

  return expr @ eval();
}

void printExpr(Expr *expr) {
  match (expr) {
  Add(e1, e2) -> {
      printExpr(e1);
      printf(" + ");
      printExpr(e2);
    }
  Sub(e1, e2) -> {
      printExpr(e1);
      printf(" - ");
      match(e2) {
      Add(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      Sub(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      _ -> {printExpr(e2);}
      }
    }
  Mul(e1, e2) -> {
      match(e1) {
      Add(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      Sub(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      _ -> {printExpr(e1);}
      }
      printf(" * ");
      match(e2) {
      Add(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      Sub(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      _ -> {printExpr(e2);}
      }
    }
  Div(e1, e2) -> {
      match(e1) {
      Add(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      Sub(_, _) -> {
          printf("(");
          printExpr(e1);
          printf(")");
        }
      _ -> {printExpr(e1);}
      }
      printf(" / ");
      match(e2) {
      Add(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      Sub(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      Mul(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      Div(_, _) -> {
          printf("(");
          printExpr(e2);
          printf(")");
        }
      _ -> {printExpr(e2);}
      }
    }
  Const(n) -> {printf("%d", n);}
  }
}

int main() {
  Expr *exprs[] = {Add(Const(1), Const(2)),
                   Add(Const(3), Mul(Const(2), Const(4))),
                   Sub(Const(7), Div(Const(6), Const(7))),
                   Mul(Const(7), Div(Const(7), Const(0))),
                   Mul(Const(1), Div(Const(7), Const(0))),
                   Mul(Const(1), Add(Div(Const(7), Const(1)), Const(4)))};
  for (int i = 0; i < sizeof(exprs) / sizeof(Expr*); i++) {
    printExpr(exprs[i]);
    printf(": ");
    Expr *res = evalExpr(exprs[i]);
    if (res != NULL)
      printExpr(res);
    else 
      printf("Fail");
    printf("\n");
  }
}
