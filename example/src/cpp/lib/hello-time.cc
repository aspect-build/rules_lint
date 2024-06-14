#include "hello-time.h"
#include <ctime>
#include <iostream>

void print_localtime() {
  std::time_t result = std::time(nullptr);
  std::string result_str = std::asctime(std::localtime(&result));
  printf("%s\n", result_str.c_str());
}
