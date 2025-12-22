#ifndef LIB_HELLO_TIME_H_
#define LIB_HELLO_TIME_H_

#include <stdio.h>
#include <xhello-time.h>

#include <string>

void print_localtime();

inline void print_localtime2() {
  std::string a = "time";
  for (int i = 0; i < a.size(); ++i) {
    printf("%s", a.c_str()[i]);
  }
}
#endif

