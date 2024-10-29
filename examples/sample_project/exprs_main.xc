#include <stdio.h>
#include <stdlib.h>
#include "exprs.xh"

allocate_using heap;

int main () {
  Expr *t = new Add(new Const(3), new Mul(new Const(2), new Const(4)));
 
  int result = value(t);

  printf("value is %d\n", result);
  
  free_Expr(t);
 
  if (result == 11)  
   return 0;   // correct answer
  else
   return 1;   // incorrect answer
}
