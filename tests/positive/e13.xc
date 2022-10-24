#include <alloca.h>
#include <assert.h>
#include <string.xh>

typedef datatype Bar* Bar;

string show_Bar(Bar x) {
  (void) x;
  return str("Bar!");
}

show Bar with show_Bar;

datatype Foo {
  FooBar(Bar);
};

allocate datatype Foo with alloca;

int main(void) {
  datatype Foo* y = alloca_FooBar(NULL);
  assert(show(y) == "&FooBar(Bar!)");
}
