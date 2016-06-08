#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <rewrite.xh>

typedef datatype Term Term;
typedef datatype Term1 Term1;

datatype Term {
  X();
};

datatype Term1 {
  Y(Term*);
};

rewrite rule foo() {
  visit (Term*) {
    X() -> Y(X());
  }
}

int main() {
  match (X()) (X() -> Y(X()););
}
