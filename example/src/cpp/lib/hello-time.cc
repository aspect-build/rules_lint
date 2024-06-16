#include "hello-time.h"
// warning: included header ctime is not used directly [misc-include-cleaner]
#include <ctime>
#include <iostream>
#include <get/get-time.h>

// Deliberately bad code
void print_localtime() {
  char* localtime = get_localtime();
  // warning: do not call c-style vararg functions [cppcoreguidelines-pro-type-vararg,hicpp-vararg]
  printf("%s\n", localtime);
}
