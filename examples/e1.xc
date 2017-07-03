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

int main () {
  Expr *t0 = Mul(Const(2), Const(4)) ;

  if ( value(t0) != 8 ) return 1;
  
  Expr *t1 = Mul( Const(3), 
                   Mul(Const(2), Const(4)) ) ;

  if ( value(t1) != 24 ) return 2;

  Expr *t2 = Add( Mul( Const(3), Const(2) ), 
                  Mul( Const(2), Const(4) ) ) ;

  if ( value(t2) != 14 ) return 3;

  return 0;
}
