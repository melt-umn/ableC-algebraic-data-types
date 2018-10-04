#include <stdio.h>
#include <stdlib.h>
#include "exprs.xh"

int main () {
  Expr *t = &#Add(&#Const(3), &#Mul(&#Const(2), &#Const(4)));
 
  int result = value(t);

  printf("value is %d\n", result);
  
  free_Expr(t);
 
  if (result == 11)  
   return 0;   // correct answer
  else
   return 1;   // incorrect answer
}
