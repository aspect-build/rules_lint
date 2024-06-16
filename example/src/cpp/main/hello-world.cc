#include "hello-time.h"
#include "hello-greet.h"
#include <iostream>
#include <string>

int main(int argc, char** argv) {
  std::string who = "world";
  if (argc > 1) {
    who = argv[1];
  }
  // warning: do not use 'std::endl' with streams; use '\n' instead [performance-avoid-endl]
  std::cout << get_greet(who) << std::endl;
  print_localtime();
  return 0;
}
