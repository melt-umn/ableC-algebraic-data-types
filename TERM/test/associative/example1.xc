#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <string.xh>
#include <vector.xh>
#include <rewrite.xh>

typedef datatype Catter Catter;

datatype Catter {
  Group(vector(Catter*));
  Elem (string);
};

string get_cat(Catter *c) {
  newstrategy cat {
    innermost {
      sequence {
        print("%s\n", show((Catter*)term));
        visit (Catter*) {
          // TODO: Use vector pattern
          Group(elems) -> ({
              printf("length: %d\n", elems->length);
              string res = "";
              int i;
              for (i = 0; i < elems->length; i++) {
                res += match (elems[i]) (Elem(s) -> s;);
              }
              printf("res: %s\n", res);
              Elem(res);});
        }
      }
    }
  }

  Catter *res = c @ cat;
  if (c == NULL) {
    printf("Error: strategy failed\n");
    exit(3);
  }
  match (res) {
    Elem(s) -> {return s;}
    _ -> {printf("Error: match failed\n"); exit(2);}
  }
}

int main() {
  Catter *test1 =
    Group(new_vector(Catter*) [Elem("a"),
                               Elem("b"),
                               Group(new_vector(Catter*) [Elem("c"),
                                                          Elem("d")]),
                               Elem("e")]);
  string res = get_cat(test1);
  printf("res: %s\n", res);
  if (res != "abcde")
    return 1;
  return 0;
}
