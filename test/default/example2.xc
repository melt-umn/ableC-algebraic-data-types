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


int valueE (Expr *e) {
  return
      match (e) (
          Add(e1,e2) -> valueE(e1) + valueE(e2) ;
          Sub(e1,e2) -> valueE(e1) - valueE(e2) ;
          Mul(e1,e2) -> valueE(e1) * valueE(e2) ;
          Div(e1,e2) -> valueE(e1) / valueE(e2) ; 
          Const(v) -> 1000 + v ; 
          ) ;
}



int value (Expr *e) {
    int result = 99;
    match (e) {
        Add(Sub(e1,e2),Mul(e3,e4)) -> {
           result = (value(e1) - value(e2)) + (value(e3) * value(e4)) ; }

        Add(_,Add(e3,e4)) -> { result = 100 ; }

        Add(e1,e2) -> { result = value(e1) + value(e2) ; }
        Sub(e1,e2) -> { result = value(e1) - value(e2) ; }
        Mul(e1,e2) -> { result = value(e1) * value(e2) ; }
        Div(e1,e2) -> { result = value(e1) / value(e2) ; }
        Const(v) -> { result = v ;  }
    }
    return result;
}




int free_Expr (Expr *e) {
  match(e) {
    Add(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    Sub(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    Mul(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    Div(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    Const(v) ->   { ; } 
  };
  free(e);
}

/*
void checkConsts (Expr *e, int *result) {
    match (e) {
      _   -> { *result = 1; }
      v   -> { *result = 1; }
      1   -> { *result = 2; }
      "1" -> { *result = 3; }
    }
}
*/

int main () {
  Expr *t = Add( Const(4), 
                 Mul(Const(2), Const(4)) ) ;
 
  int result = valueE(t);

  printf("value is %d\n", result );
  
  free_Expr(t);



 
  if (result == 1007012)  
    return 0;   // correct answer
  else
    return 1;   // incorrect answer

}
