#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// deliberately bad code to trigger clang-tidy warning
int string_to_int( const char *num) { return atoi(num); }

// deliberately insecure code to trigger clang-tidy warning
void ls() { system("ls"); }

static int compare(int x, int y) {
  if (x < y)
    ;
  { x++; }
  return x;
}

int main() {
  printf("Hello, world!\n");
  compare(3, 4);
  char *a = NULL;
  char *b = 0;
}
