#include <stdio.h>
#include <stdlib.h>

void *foo(float size);

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};

allocate datatype Expr with foo; // Invalid allocator type

int value(Expr *e) {
  int result = 99;
  match (e) {
    &Add(e1,e2) -> { result = value(e1) + value(e2); }
    &Mul(e1,e2) -> { result = value(e1) * value(e2); }
    &Const(v) -> { result = v; }
  }
  return result;
}

int main () {
  Expr *t0 = foo_Mul(foo_Const(2), foo_Const(4));

  if (value(t0) != 8) return 1;
  
  Expr *t1 = foo_Mul(foo_Const(3), foo_Mul(foo_Const(2), foo_Const(4)));

  if (value(t1) != 24) return 2;

  Expr *t2 = foo_Add(foo_Mul(foo_Const(3), foo_Const(2)),
                     foo_Mul(foo_Const(2), foo_Const(4)));

  if (value(t2) != 14) return 3;

  return 0;
}
