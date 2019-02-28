#include <stdio.h>
#include <stdlib.h>

template<a>
struct foo {
  a x;
};

int main() {
  match (0)
    (x -> (foo<int>){x};);
}
