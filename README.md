# Algebraic Data Type for C

Algebraic data types, sometime referred to as ML-types, were first
made popular in ML.  They quickly became common in functional
languages and are found in Standard ML, OCaml, and Haskell.  They have
migrated into other language paradigms and are the inspriation for
case-classes in Scala.

This language extension for ableC provides these data type and the
corresponding pattern matching facilities so that they can be used in
C programs.

For example, the following declares an ``Expr`` data type for
representing simple arithmetic expressions.
```c
typedef  datatype Expr  Expr;

datatype Expr {
  Add (Expr*, Expr*);
  Mul (Expr*, Expr*);
  Const (int);
};
```

This declaration also creates the constructor functions to build data
values of this type.  For example, one can create an expression as
follows:
```c
Expr *e1 = malloc(sizeof(Expr));
*e1 = Const(3);
Expr *e2 = malloc(sizeof(Expr));
*e2 = Const(2);
Expr *e3 = malloc(sizeof(Expr));
*e3 = Mul(e1, e2);
Expr *e4 = malloc(sizeof(Expr));
*e4 = Const(2);
Expr *e5 = malloc(sizeof(Expr));
*e5 = Const(4);
Expr *e6 = malloc(sizeof(Expr));
*e6 = Mul(e4, e5);
Expr *e7 = malloc(sizeof(Expr));
*e7 = Add(e3, e6);
```

This requirement of allocating each sub-expression as a seperate statement
is cumbersome, and so special syntax is provided to auto-generate allocating
constructors:
```c
allocate datatype Expr with malloc;

Expr *tree = malloc_Add(malloc_Mul(malloc_Const(3), malloc_Const(2)), 
                        malloc_Mul(malloc_Const(2), malloc_Const(4)));
```

Furthermore, one can also use pattern matching to inspect and
deconstruct the data.  Here is a function to compute the value of an
expression: 
```c
int value (Expr *e) {
    int result = 0;
    match (e) {
        Add(e1,e2) -> { result = value(e1) + value(e2); }
        Mul(e1,e2) -> { result = value(e1) * value(e2); }
        Const(v) -> { result = v;  }
    }
    return result;
}
```

This can also be written using a "match expression" instead of a "match
statement":
```c
int value (Expr *e) {
    return
        match (e) (
            Add(e1,e2) -> value(e1) + value(e2);
            Mul(e1,e2) -> value(e1) * value(e2);
            Const(v) -> v;
        );
}
```

More examples can be found in the ``examples`` and ``artifact``
directories.




      
     
      
