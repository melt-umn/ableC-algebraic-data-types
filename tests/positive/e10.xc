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

allocate_using heap;

int main() {
  datatype Bar b = F(B(new F(B(new F(B(NULL))))));

  string res = show(b);
  printf("b: %s\n", res.text);
  if (res != "F(B(&F(B(&F(B(<datatype Bar *  at (nil)>))))))") {
    return 1;
  }

  return 0;
}
