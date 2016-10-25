#include <stdio.h>
#include <stdlib.h>


typedef  datatype Tree  Tree;
datatype Tree {
    Fork (Tree*, Tree*, const char*);
    Leaf (const char*);
};

int count_matches (Tree *t) {
  match (t) {
     Fork(t1,t2,str) -> {
        int res_t1, res_t2;
        res_t1 = count_matches(t1);
	res_t2 = count_matches(t2);
        res_str = 1;
        return res_t1 + res_t2 + res_str;
	}


    Leaf(s) -> { cilk return 1; }
   } ;
}

int main (int argc, char **argv) {
    Tree *tree;  // then, read in a tree
    printf ("Number of matches = %d\n",
            count_matches(tree));
    return 0;
}

