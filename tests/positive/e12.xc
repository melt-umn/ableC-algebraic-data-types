#include <assert.h>
#include <string.xh>

typedef datatype Foo* Foo;

string show_Foo(datatype Foo x) {
  (void) x;
  return str("Foo!");
}

show datatype Foo with show_Foo;

int main(void) {
  Foo x = NULL;
  assert(show(x) == "Foo!");
}
