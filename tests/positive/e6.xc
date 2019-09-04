#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

enum Foo {
  A, B, C
};

datatype Bar {
  X(enum Foo, int);
  Y(float);
}

bool equals(datatype Bar b1, datatype Bar b2) {
  return match (b1, b2)
    (X(A, n1), X(A, n2) @ when (n1 == n2) -> true;
     X(B, n1), X(B, n2) @ when (n1 == n2) -> true;
     X(C, n1), X(C, n2) @ when (n1 == n2) -> true;
     Y(f1), Y(f2) @ when (f1 == f2) -> true;
     _, _ -> false;);
}

int main () {
  bool res1 = equals(X(A, 2), X(A, 2));
  bool res2 = equals(Y(3.14), Y(3.14));
  bool res3 = equals(Y(3.14), X(B, 1));
  bool res4 = equals(X(C, 1), X(B, 1));
  bool res5 = equals(X(A, 2), X(A, 4));
  bool res6 = equals(Y(3.14), Y(6.28));
  return !(res1 && res2 && !res3 && !res4 && !res5 && !res6);
}
