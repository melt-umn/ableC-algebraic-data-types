#ifndef EXPR_H
#define EXPR_H

datatype Expr ;

typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Sub (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Div (Expr*, Expr*);
  Const (int);
};

int value (Expr *e) ;

int free_Expr (Expr *e) ;


#endif
