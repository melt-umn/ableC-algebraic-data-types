#include <string.h>
#include <stdio.h>

struct bar;

datatype baz {
  A(struct bar*);
  B(int);
};

struct foo {
  int a;
  float b;
  datatype baz c;
};

struct bar {
  struct foo x;
  char *y;
};

int main () {
  struct bar b1 = {{1, 3.14f, B(14)}, "abcd"};
  struct bar b2 = {{12, 2.27f, A(&b1)}, "defg"};

  match (b2) {
    {{.c = A(&b), 12, .b = 2.27f}, "defg"} -> {
      if (b.x.c.tag != baz_B) {
        return 1;
      }
    }
    _ -> { return 2; }
  }

  return 0;
}

