#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr *e1, Expr *e2);
  Mul (Expr *e1, Expr *e2);
  Const (int val);
};

allocate_using heap;

int value (Expr *e) {
  int result = 99;
    
  match (e) {
    &{Expr_Add, {.Add = {e1, e2}}} -> { result = value(e1) + value(e2); }
    &{Expr_Mul, {.Mul = {e1, e2}}} -> { result = value(e1) * value(e2); }
    &{Expr_Const, {.Const = {v}}} -> { result = v; }
  }
  return result;
}

int main () {
  Expr *t0 = new Mul(new Const(2), new Const(4));

  if (value(t0) != 8) return 1;
  
  Expr *t1 = new Mul(new Const(3), 
                     new Mul(new Const(2), new Const(4)));

  if (value(t1) != 24) return 2;

  Expr *t2 = new Add(new Mul(new Const(3), new Const(2)), 
                     new Mul(new Const(2), new Const(4)));

  if (value(t2) != 14) return 3;

  return 0;
}
