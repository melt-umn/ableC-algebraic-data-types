#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <rewrite.xh>

typedef datatype Expr Expr;

typedef datatype Stmt Stmt;

datatype Expr {
  Add      (Expr*, Expr*);
  Sub      (Expr*, Expr*);
  Mul      (Expr*, Expr*);
  Div      (Expr*, Expr*);
  Var      (const char*);
  Const    (int);
};

datatype Stmt {
  Seq    (Stmt*, Stmt*);
  If     (Expr*, Stmt*);
  IfElse (Expr*, Stmt*, Stmt*);
  While  (Expr*, Stmt*);
  Assign (const char*, Expr*);
  Print  (Expr*);
  Empty  ();
};

typedef struct envEntry envEntry;

struct envEntry {
  const char *name;
  int value;
};

int envSize = 0;
envEntry env[100];
  
void put(const char *name, int value) {
  env[envSize] = (envEntry){name, value};
  envSize++;
}

bool contains(const char *name) {
  for (int i = 0; i < envSize; i++) {
    if (!strcmp(name, env[i].name))
      return true;
  }
  return false;
}

int get(const char *name) {
  for (int i = 0; i < envSize; i++) {
    if (!strcmp(name, env[i].name))
      return env[i].value;
  }
  return false;
}

void printExpr(Expr *expr);

Stmt *evalStmt(Stmt *prog) {
  rewrite rule eval(envEntry env[]) {
    innermost {
      choice {
        visit (Expr*) {
          Add(Const(a), Const(b)) -> Const(a + b);
          Sub(Const(a), Const(b)) -> Const(a - b);
          Mul(Const(a), Const(b)) -> Const(a * b);
          Div(Const(a), Const(b) @ !Const(0)) -> Const(a / b);
          Var(name) -> contains(name)? Const(get(name)) : NULL;
        }

        visit (Stmt*) {
          Seq(Empty(), s) -> s;
          //  Seq(s, Empty()) -> s;
          If(e, s) -> IfElse(e, s, Empty());
          IfElse(Const(n), s1, s2) -> n != 0? s1 : s2;
          //While(e, s) -> n != 0? Seq(s, While(e, s)) : Empty();
          Assign(var, Const(n)) -> ({
              put(var, n);
              Empty();
            });
          Print(Const(n)) -> ({
              printf("%d\n", n);
              Empty();
            });
        }
      }
    }
  }

  strategy evalStmt = eval(env);

  return prog @ evalStmt;
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
  Var(n) -> {printf("%s", n);}
  }
}

void printStmt(Stmt *stmt) {
  match (stmt) {
  Seq(s1, s2) -> {
      printStmt(s1);
      printf("; ");
      printStmt(s2);
    }
  If(e, s) -> {
      printf("if (");
      printExpr(e);
      printf(") {");
      printStmt(s);
      printf("}");
    }
  IfElse(e, s1, s2) -> {
      printf("if (");
      printExpr(e);
      printf(") {");
      printStmt(s1);
      printf("} else {");
      printStmt(s2);
      printf("}");
    }
  Assign(n, e) -> {
      printf("%s := ", n);
      printExpr(e);
    }
  Print(e) -> {
      printf("print(");
      printExpr(e);
      printf(")");
    }
  Empty() -> {
      printf("<empty>");
    }
  }
}

int main() {
  Stmt *progs[] = {Print(Div(Const(1), Const(0))),
                   Seq(Print(Const(1)), Print(Add(Const(1), Const(2)))),
                   Seq(Assign("a", Const(2)), Print(Mul(Const(2), Var("a")))),
                   Seq(Assign("a", Const(1)), Seq(If(Sub(Var("a"), Const(1)), Assign("a", Sub(Const(0), Var("a")))), Print(Var("a")))),
                   Seq(Assign("a", Const(-1)), Seq(If(Sub(Var("a"), Const(1)), Assign("a", Sub(Const(0), Var("a")))), Print(Var("a"))))};
  for (int i = 0; i < sizeof(progs) / sizeof(Expr*); i++) {
    printf("Program %d:\n", i);
    printStmt(progs[i]);
    printf("\nEvaluation:\n");
    Stmt *result = evalStmt(progs[i]);
    printf("Result:\n");
    if (result == NULL)
      printf("Fail\n");
    else {
      printStmt(result);
      printf("\n");
    }
  }
}
