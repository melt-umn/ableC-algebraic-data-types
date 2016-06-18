#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
    AddAll (int, Expr* *);
  AddOne (Expr*);
  Const (int);
};

int test (Expr *e) {
  int result = 99;
  match (e) {
    AddAll( len, [ ..., Const(x) @ when (x =5) , ..., Const(6), ...] len ) 
      -> { result = 1000 + x ; }

        //AddOne( [ ..,  Const(1), ..  ] ) -> { result = 111; }

        //AddAll (vvv) -> {result = 1;}
        //Const(2) -> {result = 222;}
        //Const(4) -> {result = 444;}
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

  Expr *e = AddAll(7, all);
  //Expr *e = AddOne(e1);

  int result = test(e);

  printf("result is %d\n", result);

  return 0;
}
