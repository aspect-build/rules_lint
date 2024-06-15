#include <stdio.h>
#include <stdlib.h>

// deliberately bad code to trigger clang-tidy warning
int string_to_int(const char *num) {
  return atoi(num);
}

// deliberately insecure code to trigger clang-tidy warning
void ls() {
  system("ls");
}

int main() { printf("Hello, world!\n"); }
