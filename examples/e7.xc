#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Foo {
  Bar(int x);
};

allocate datatype Foo with malloc prefix baz;

int main() {
  datatype Foo* x = bazBar(42);
  if(show(x) != "&Bar(42)")
    return 1;
  return 0;
}
