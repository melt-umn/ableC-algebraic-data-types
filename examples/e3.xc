#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};

allocate datatype Expr with malloc;

int funny_value(Expr *e) {
  int result = 999;
  match (e) {
    &Add(&Mul(e1,e2), &Mul(e3,e4)) -> {
      result = (funny_value(e1) - funny_value(e2)) + (funny_value(e3) * funny_value(e4));
    }

    &Mul(e1,&m@&Mul(_,_)) -> { 
      match (m) {
        Mul(e2,e3) -> { result = funny_value(e1) * funny_value(e2) * funny_value(e3); }
      }
    }

    &Mul(e1,e2) -> { result = funny_value(e1) * funny_value(e2); }

    &Const(c)@when (c < 0) -> { result = 42; }
    
    &Const(v1@v2) -> { result = v1 + v2; }

    !&Const(_) -> { result = 1000; }
  }
  return result;
}


int main () {
  int result;

  Expr *t0 = malloc_Add(malloc_Mul(malloc_Const(3), malloc_Const(2)), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));
  result = funny_value(t0);
  printf("funny_value of t0 is %d\n", result);
  if (result != 34) return 1;
  
  Expr *t1 = malloc_Mul(malloc_Const(3), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));
  result = funny_value(t1);
  printf("funny_value of t1 is %d\n", result);
  if (result != 192) return 2;
  
  Expr *t2 = malloc_Mul(malloc_Const(2), malloc_Const(4));
  result = funny_value(t2);
  printf("funny_value of t2 is %d\n", result);
  if (result != 32) return 3;

  Expr *t3 = malloc_Const(2); 
  result = funny_value(t3);
  printf("funny_value of t3 is %d\n", result);
  if (result != 2 + 2) return 4;
  
  Expr *t4 = malloc_Add(malloc_Const(2), malloc_Const(4));
  result = funny_value(t4);
  printf("funny_value of t4 is %d\n", result);
  if (result != 1000) return 5;
  
  Expr *t5 = malloc_Mul(malloc_Const(1), malloc_Const(-4));
  result = funny_value(t5);
  printf("funny_value of t5 is %d\n", result);
  if (result != 84) return 6;
  
  return 0;
}
