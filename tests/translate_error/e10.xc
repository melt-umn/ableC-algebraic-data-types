#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Foo {
  A(Bar); // Bar is undefined
};

int main () {
  datatype Foo f = A(0);
}

