#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  AddAll (Expr* *);
  Const (int);
};

int test (Expr *e) {
    int result = 99;
    match (e) {
//        AddAll( [ ..., Const(1), ..., Const(3), ...] ) -> { result = 1; }

        AddAll (vvv) -> {result = 1;}
        Const(2) -> {result = 222;}
        Const(4) -> {result = 444;}
        _ -> { result = 0 ;  }
    }
    return result;
}


int main () {
  Expr *e0 = Const(0);
  Expr *e1 = Const(1);
  Expr *e2 = Const(2);
  Expr *e3 = Const(3);

  Expr *e4 = Const(4);
  Expr *e5 = Const(5);
  Expr *e6 = Const(6);

  Expr *all[7] = {e0, e1, e2, e3, e4, e5, e6};

  Expr *e = AddAll(all);

  int result = test(e);

  printf("result is %d\n", result);

  return 0;
}
