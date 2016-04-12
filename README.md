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
```
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
```
Expr *tree = Add( Mul( Const(3), Const(2) ), 
                  Mul( Const(2), Const(4) ) ) ;
```

Furthermore, one can also use pattern matching to inspect and
deconstruct the data.  Here is a function to compute the value of an
expression: 
```
int value (Expr *e) {
    int result = 0;
    match (e) {
        Add(e1,e2) -> { result = value(e1) + value(e2) ; }
        Mul(e1,e2) -> { result = value(e1) * value(e2) ; }
        Const(v) -> { result = v ;  }
    }
    return result;
}
```

More examples can be found in the ``examples`` and ``artifact``
directories.

Additional documentation can be found in the ``docs`` directory.


## Status:

### Modular composition analyses
* passes modular determinism analysis
* DOES NOT pass modular well-definedness
* * mostly (presumebly) because the attribution isn't complete yet.

### Semantic Analysis
* Currently, almost no error checking is done.  We need
* * check for type errors
    defs doesn't even decorate PatternList - so lots to do here
* * check that patterns are linear
* * others?

### Enhancement
* match expressions do not evaluate to a defined value if none of the
  patterns match.  The unitialized variable _result is simply used.




      
     
      
