#include <stdio.h>
#include <stdlib.h>
#include <alloca.h>

datatype Expr {
  Add (datatype Expr*, datatype Expr*);
  Mul (datatype Expr*, datatype Expr*);
  Const (int);
};

allocate datatype Expr with malloc;
allocate datatype Expr with alloca;

int value (datatype Expr e) {
  int result = 99;
  match (e) {
    Add(&e1,&e2) -> { result = value(e1) + value(e2); }
    Mul(&e1,&e2) -> { result = value(e1) * value(e2); }
    Const(v) -> { result = v ;  }
  }
  return result;
}

int main () {
  datatype Expr t0 = Mul(malloc_Const(2), malloc_Const(4));

  if (value(t0) != 8) return 1;
  
  datatype Expr t1 = Mul(alloca_Const(3), alloca_Mul(alloca_Const(2), alloca_Const(4)));

  if (value(t1) != 24) return 2;

  datatype Expr t2 = Add(malloc_Mul(malloc_Const(3), malloc_Const(2)), 
                         alloca_Mul(alloca_Const(2), alloca_Const(4)));

  if (value(t2) != 14) return 3;

  return 0;
}
