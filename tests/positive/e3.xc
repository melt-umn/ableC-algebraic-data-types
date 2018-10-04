#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};

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

  Expr *t0 = &#Add(&#Mul(&#Const(3), &#Const(2)),
                   &#Mul(&#Const(2), &#Const(4)));
  result = funny_value(t0);
  if (result != 34) return 1;
  
  Expr *t1 = &#Mul(&#Const(3), &#Mul(&#Const(2), &#Const(4)));
  result = funny_value(t1);
  if (result != 192) return 2;
  
  Expr *t2 = &#Mul(&#Const(2), &#Const(4));
  result = funny_value(t2);
  if (result != 32) return 3;

  Expr *t3 = &#Const(2); 
  result = funny_value(t3);
  if (result != 2 + 2) return 4;
  
  Expr *t4 = &#Add(&#Const(2), &#Const(4));
  result = funny_value(t4);
  if (result != 1000) return 5;
  
  Expr *t5 = &#Mul(&#Const(1), &#Const(-4));
  result = funny_value(t5);
  if ( result != 84) return 6;
  
  return 0;
}
