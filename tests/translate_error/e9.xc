#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

struct Foo {int a; float b;};

datatype Bar {
  A(struct Foo foo);
};

allocate datatype Bar with malloc;

datatype Baz {
  B(datatype Bar *bar);
};

int main () {
  datatype Baz b = B(malloc_A((struct Foo){42, 3.14}));
  
  string s = show(b); // Showing datatype with non-showable field
}

