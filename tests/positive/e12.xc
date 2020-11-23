#include <alloca.h>
#include <assert.h>
#include <string.xh>

datatype Foo {
  FooThing(int x);
};

datatype Bar {
  BarThing(int, datatype Foo*);
};

allocate datatype Foo with alloca;
allocate datatype Bar with alloca;

typedef datatype Foo* Foo;

string show_Foo(datatype Foo x) {
  (void) x;
  return str("Foo!");
}

show datatype Foo with show_Foo;

int main(void) {
  Foo x = alloca_FooThing(5);
  datatype Bar* y = alloca_BarThing(42, x);
  assert(show(x) == "&Foo!");
  assert(show(y) == "&BarThing(42, &Foo!)");
}
