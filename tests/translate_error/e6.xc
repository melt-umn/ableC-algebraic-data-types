#include <stdio.h>
#include <stdlib.h>

int main () {
  int a = 3;
  int x = 0;

  // a match statment
  match (a) {
    1     -> { x = 1; }
    2     -> { x = 2; }
    v @ v -> { x = v; } // Redeclaration of v
  }

}

