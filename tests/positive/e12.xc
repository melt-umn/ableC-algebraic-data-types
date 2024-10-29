#include <arena.h>
#include <assert.h>
#include <string.xh>

datatype Foo {
  FooThing(int x);
};

datatype Bar {
  BarThing(int, datatype Foo*);
};

typedef datatype Foo* Foo;

size_t max_len_Foo(datatype Foo x) {
  return 4;
}

size_t show_Foo(char *buf, datatype Foo x) {
  return sprintf(buf, "Foo!");
}

show datatype Foo with max_len_Foo, show_Foo;

int main(void) {
  with_arena a {
    Foo x = new FooThing(5);
    datatype Bar* y = new BarThing(42, x);
    printf("%s\n", show(x).text);
    printf("%s\n", show(y).text);

    assert(show(x) == "&Foo!");
    assert(show(y) == "&BarThing(42, &Foo!)");
  }
}
