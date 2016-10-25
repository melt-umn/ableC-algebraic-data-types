#include <stdio.h>
#include <stdlib.h>

#include <rewrite.h>



typedef  datatype Nat  Nat;

datatype Nat {
  Zero ();
  Succ (Nat*);
}


typedef  datatype Expr  Expr;
datatype Expr {
  App( Expr*, Expr* );
  Abs( const char*, Expr* );
  Var( const char*);
  Add( Expr*, Expr* );
  Num( Nat* );
};

void printNat( Nat *n ) {
  match (n) {
    Zero() -> { printf ("Zero()"); }
    Succ(n1) -> { printf ("Succ("); printNat(n1); printf(")"); }
  }
}

void printExpr( Expr *e) {
    match (e) {
        App(e1, e2) -> { printf("App("); printExpr(e1); printf(","); printExpr(e2); printf(")"); }
        Abs(v, e2) -> { printf("Abs(%s,"); printExpr(e2); printf(")"); }
        Var(v) -> { printf("Var(%s)", v); }
        Add(e1, e2) -> { printf("Add("); printExpr(e1); printf(","); printExpr(e2); printf(")"); }
        Num(n) -> { printf("Nat("); printNat(n); printf(")"); }
    }
}

newstrategy add() {
    visit(Expr *) {
        Add( Num(Zero()), Num(x) ) -> Num(x) ;
        Add( Num(Succ(a)), Num(b)) -> Add (Num(a), Num(Succ(b)) );
    }
}




int main() {
    Expr *e1 = Add( Num(Succ(Succ(Zero()))),  Num(Succ(Zero())) );
    
    Expr *e = innermost(add())(e1);

    if (e != NULL) {
        printf("success.\n");
        printExpr(e);
        printf("\n");
    }
}
