#include <stdio.h>
#include <stdlib.h>
#include "exprs.xh"

allocate datatype Expr with malloc;

int main () {
  Expr *t = malloc_Add(malloc_Const(3), malloc_Mul(malloc_Const(2), malloc_Const(4)));
 
  int result = value(t);

  printf("value is %d\n", result);
  
  free_Expr(t);
 
  if (result == 11)  
   return 0;   // correct answer
  else
   return 1;   // incorrect answer
}
