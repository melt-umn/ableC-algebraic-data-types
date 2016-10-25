#include <stdio.h>
#include <stdlib.h>

int main () {
    int a = 3 ;
    int x = 0;

    // a match statment
    match (a) {
      1   -> { x = 1; }
      2   -> { x = 2; }
      v   -> { x = v; }
    }

    printf ("x is %d\n", x);

    int b = 1;
    int y = 0;

    // a match expression
    y = match(b) (
          1 -> 3 ;
 	  v -> v ;
	);
	
    printf ("y is %d\n", y);

    if (x == 3 && y == 3) 
       return 0;
    else 
       return 1;
}

