#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr *e1, Expr *e2);
  Mul (Expr *e1, Expr *e2);
  Const (int val);
};

allocate datatype Expr with malloc;

int value (Expr *e) {
  int result = 99;
    
  match (e) {
    &Add(e1,e2) -> { result = value(e1) + value(e2); }
    &Mul(e1,e2) -> { result = value(e1) * value(e2); }
    &Const(v) -> { result = v;  }
  }
  return result;
}

int main () {
  Expr *t0 = malloc_Mul(malloc_Const(2), malloc_Const(4));

  if (value(t0) != 8) return 1;
  
  Expr *t1 = malloc_Mul(malloc_Const(3), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));

  if (value(t1) != 24) return 2;

  Expr *t2 = malloc_Add(malloc_Mul(malloc_Const(3), malloc_Const(2)), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));

  if (value(t2) != 14) return 3;

  return 0;
}
