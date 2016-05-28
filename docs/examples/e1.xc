#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};

int value (Expr *e) {
    int result = 99;
    match (e) {
        Add(e1,e2) -> { result = value(e1) + value(e2) ; }
        Mul(e1,e2) -> { result = value(e1) * value(e2) ; }
        Const(v) -> { result = v ;  }
    }
    return result;
}

int v2 (Expr *e) {
    int result = 99;
    match (e) {
        //Add (Mul (e1,e2), Mul (e3,e4)) -> {
        //   result = (v2(e1) - v2(e2)) + (v2(e3) * v2(e4)) ; }

        ! Const(_) -> { printf ("Not a constant!\n"); }

        Add(e1,e2) -> { result = v2(e1) + v2(e2) ; }
        Mul(e1,m@Mul(_,_)) -> { 
            match (m) {
                Mul(e2,e3) -> { result = v2(e1) * v2(e2) * v2(e3) ; }
            }
        }

        Mul(e1,Add(_,_)@Mul(_,_)) -> { 
            result = 9999; 
            printf ("Oh no, should never get here...\n"); 
        }

        Mul(e1,e2) -> { result = v2(e1) * v2(e2) ; }
        Const(v1@v2) -> { result = v1 + v2 ;  }
    }
    return result;
}

int main () {
  Expr *t0 = Mul(Const(2), Const(4)) ;

  Expr *t1 = Mul( Const(3), 
                 Mul(Const(2), Const(4)) ) ;

  Expr *t2 = Add( Mul( Const(3), Const(2) ), 
                  Mul( Const(2), Const(4) ) ) ;

  int result, r2;

  result = value(t0);
  printf("value of t0 is %d\n", result );

  r2 = v2(t0);
  printf("v2 of t0 is %d\n", r2 );

  result = value(t1);
  printf("value of t1 is %d\n", result );

  r2 = v2(t1);
  printf("v2 of t1 is %d\n", r2 );

  result = value(t2);
  printf("value of t2 is %d\n", result );

  r2 = v2(t2);
  printf("v2 of t2 is %d\n", r2 );

 
  if (result == 14)  
    return 0;   // correct answer
  else
    return 1;   // incorrect answer

}
