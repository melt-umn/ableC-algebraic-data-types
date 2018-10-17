#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

int main () {
  int a = 3;
  int x = 0;

  // a match statment
  match (a) {
    1   -> { x = 1; }
    2   -> { x = 2; }
    v   -> { x = v; }
  }

  int b = 1;
  int y = 0;

  // a match expression
  y = match (&b) (&1 -> 3;
                  v    -> *v;);

  // multiple patterns
  int *c = &a;
  int z = match (b, c) (4, _            -> 5;
                        _, (!NULL) @ &v -> 42;
                        _, NULL         -> 35;);

  bool w = false;
  match ("a", true) {
    "a", true -> { w = true; }
    _, _ -> { }
  }
  
  if (x == 3 && y == 3 && z == 42 && w)
    return 0;
  else 
    return 1;
}

