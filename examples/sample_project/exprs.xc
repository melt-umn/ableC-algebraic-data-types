#include <stdio.h>
#include <stdlib.h>
#include "exprs.xh"

int value (Expr *e) {
    int result = 99;
    match (e) {
        &Add(e1,e2) -> { result = value(e1) + value(e2) ; }
        &Sub(e1,e2) -> { result = value(e1) - value(e2) ; }
        &Mul(e1,e2) -> { result = value(e1) * value(e2) ; }
        &Div(e1,e2) -> { result = value(e1) / value(e2) ; }
        &Const(v) -> { result = v ; }
    }
    return result;
}


int free_Expr (Expr *e) {
  match (e) {
    &Add(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Sub(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Mul(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Div(e1,e2) -> { free_Expr(e1); free_Expr(e2); }
    &Const(v) ->   { }
  };
  free(e);
}
