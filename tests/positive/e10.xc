#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Bar;

datatype Foo {
  B(datatype Bar *);
};

datatype Bar {
  F(datatype Foo);
};

allocate datatype Bar with malloc;

int main() {
  datatype Bar b = F(B(malloc_F(B(malloc_F(B(NULL))))));

  string res = show(b);
  printf("b: %s\n", res.text);
  if (res != "F(B(&F(B(&F(B(<datatype Bar *  at 0x0>))))))") {
    return 1;
  }

  return 0;
}
