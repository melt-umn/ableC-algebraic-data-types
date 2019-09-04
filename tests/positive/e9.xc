#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr *e1, Expr *e2);
  Mul (Expr *e1, Expr *e2);
  Const (int val);
};

allocate datatype Expr with malloc;

int main() {
  Expr *t0 = malloc_Mul(malloc_Const(2), malloc_Const(4));
  printf("%s\n", show(t0).text);
         
  if (show(t0) != "&Mul(&Const(2), &Const(4))") return 1;
  
  Expr *t1 = malloc_Add(malloc_Const(3), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));
  printf("%s\n", show(t1).text);

  if (show(t1) != "&Add(&Const(3), &Mul(&Const(2), &Const(4)))") return 2;

  Expr tmp = {42}, *t2 = &tmp;
  printf("%s\n", show(t2).text);

  if (show(t2) != "&<datatype Expr, tag 42>") return 3;

  return 0;
}
