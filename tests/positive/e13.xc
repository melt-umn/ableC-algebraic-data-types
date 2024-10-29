#include <alloca.h>
#include <assert.h>
#include <string.xh>

typedef datatype Bar* Bar;

size_t max_len_Bar(Bar x) {
  return 4;
}

size_t show_Bar(char *buf, Bar x) {
  return sprintf(buf, "Bar!");
}

show Bar with max_len_Bar, show_Bar;

datatype Foo {
  FooBar(Bar);
};

allocate_using stack;

int main(void) {
  datatype Foo* y = new FooBar(NULL);
  assert(show(y) == "&FooBar(Bar!)");
}
