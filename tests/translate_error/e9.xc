#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

struct Foo;

datatype Bar {
  A(struct Foo *foo);
};

allocate_using heap;

datatype Baz {
  B(datatype Bar *bar);
};

int main () {
  datatype Baz b = B(new A(NULL));
  
  string s = show(b); // Showing datatype with non-showable field
}

