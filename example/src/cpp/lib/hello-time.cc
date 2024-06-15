#include "hello-time.h"
#include <ctime>
#include <iostream>
#include <get/get-time.h>

// Deliberately bad code
void print_localtime() {
  char* localtime = get_localtime();
  printf("%s\n", localtime);
}
