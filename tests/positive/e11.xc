#include <stdio.h>
#include <stdlib.h>

template<typename a>
struct foo {
  a x;
};

int main() {
  match (0)
    (x -> (foo<int>){x};);
}
