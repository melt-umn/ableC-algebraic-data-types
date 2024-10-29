#include <stdio.h>
#include <stdlib.h>
#include <alloca.h>
#include <arena.h>

datatype Expr {
  Add (datatype Expr*, datatype Expr*);
  Mul (datatype Expr*, datatype Expr*);
  Const (int);
};

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
  allocate_using heap;

  datatype Expr t0 = Mul(new Const(2), new Const(4));

  if (value(t0) != 8) return 1;
  
  allocate_using stack;

  datatype Expr t1 = Mul(new Const(3), new Mul(new Const(2), new Const(4)));

  if (value(t1) != 24) return 2;

  with_arena a {
    datatype Expr t2 = Add(new Mul(new Const(3), new Const(2)), 
                           new Mul(new Const(2), new Const(4)));

    if (value(t2) != 14) return 3;
  }

  match (t0) {
    Mul(e1, e2) -> {
      free(e1); free(e2);
    }
  }

  return 0;
}
