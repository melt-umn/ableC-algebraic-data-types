#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Sub (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Div (Expr*, Expr*);
  Const (int);
};

int valueE(Expr *e) {
  return
    match (e) (&Add(e1,e2) -> valueE(e1) + valueE(e2);
               &Sub(e1,e2) -> valueE(e1) - valueE(e2);
               // &Mul(e1,e2) -> valueE(e1) * valueE(e2); // Pattern match failure
               &Div(e1,e2) -> valueE(e1) / valueE(e2); 
               &Const(v) -> v;);
}

int valueS(Expr *e) {
  int result = 99;
  match (e) {
    &Add(e1,e2) -> { result = valueS(e1) + valueS(e2); }
    &Sub(e1,e2) -> { result = valueS(e1) - valueS(e2); }
    &Mul(e1,e2) -> { result = valueS(e1) * valueS(e2); }
    &Div(e1,e2) -> { result = valueS(e1) / valueS(e2); }
    &Const(v) ->   { result = v; }
  }
  return result;
}

int free_Expr(Expr *e) {
  match (e) {
    &Add(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Sub(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Mul(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Div(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Const(v) ->   { } 
  };
  free(e);
}

int main () {
  Expr *t = &#Add(&#Const(4), &#Mul(&#Const(2), &#Const(4)));
 
  int result1 = valueE(t);
  int result2 = valueS(t);

  printf("valueE is %d\n", result1 );
  printf("valueS is %d\n", result2 );
  
  free_Expr(t);

  if (result1 == 12 && result2 == 12)  
    return 0;   // correct answer
  else
    return 1;   // incorrect answer
}
