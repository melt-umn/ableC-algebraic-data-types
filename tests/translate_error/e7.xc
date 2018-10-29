#include <stdio.h>
#include <stdlib.h>

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};

allocate datatype Expr with malloc;

int main () {
  malloc_Add; // Referencing in invalid context
}
