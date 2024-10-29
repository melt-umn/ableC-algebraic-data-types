#include <stdio.h>
#include <stdlib.h>

typedef  datatype Tree  Tree;
datatype Tree {
  Fork (Tree*, Tree*, const char*);
  Leaf (const char*);
};

allocate_using heap;

int count_matches (Tree *t) {
  match (t) {
    &Fork(t1,t2,s) -> {
      int res_t1, res_t2, res_s;
      res_t1 = count_matches(t1);
      res_t2 = count_matches(t2);
      res_s = 1;
      return res_t1 + res_t2 + res_s;
    }
    &Leaf(s) -> { return 1; }
  }
}

int main (int argc, char **argv) {
  Tree *tree = new Fork(new Fork(new Leaf("b"), new Leaf("c"), "x"), new Leaf("a"), "y");

  int result = count_matches(tree);

  printf ("Number of matches = %d\n", result);

  return (result == 5) ? 0 : 1;
}
