#include <assert.h>
#include <string.xh>

typedef datatype Foo* Foo;

int main(void) {
  Foo x = NULL;
  assert(show(x) == "Foo!");
}
