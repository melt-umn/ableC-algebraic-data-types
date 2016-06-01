#include <stdio.h>
#include <stdlib.h>
#include <gc.h>

typedef  datatype Expr  Expr;
typedef  GC:datatype GExpr  GExpr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  GCExpr (GExpr*);
  Const (int);
};

GC:datatype GExpr {
  AddG (GExpr*, GExpr*);
  MulG (GExpr*, GExpr*);
  ConstG (int);
};

int gvalue (GExpr *e) {
    int result = 99;
    match (e) {
        AddG(e1,e2) -> { result = gvalue(e1) + gvalue(e2) ; }
        MulG(e1,e2) -> { result = gvalue(e1) * gvalue(e2) ; }
        ConstG(v) -> { result = v ;  }
    }
    return result;
}

int value (Expr *e) {
    int result = 99;
    match (e) {
        Add(e1,e2) -> { result = value(e1) + value(e2) ; }
        Mul(e1,e2) -> { result = value(e1) * value(e2) ; }
        GCExpr(e) -> { result = gvalue(e) ;  }
        Const(v) -> { result = v ;  }
    }
    return result;
}

int free_Expr (Expr *e) {
  match(e) {
    Add(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    Mul(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    GCExpr(e) ->   { ; } 
    Const(v) ->   { ; } 
  };
  free(e);
}

int main () {
  Expr *test = Add( Mul( Const(3), Const(2) ), 
                    GCExpr(MulG( ConstG(2), ConstG(4) )) ) ;

  int result = value(test);
  printf("value of t0 is %d\n", result );
  
  free_Expr(test);
 
  if (result == 14)  
    return 0;   // correct answer
  else
    return 1;   // incorrect answer

}
