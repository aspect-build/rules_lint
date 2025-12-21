#ifndef LIB_GET_TIME_H_
#define LIB_GET_TIME_H_

#include <string.h>

const char* get_localtime_impl();

// Deliberately bad code
inline char* get_localtime() {
  const char* time = get_localtime_impl();
  char timebuf[20];
  strcpy(timebuf, time);
  // warning: Address of stack memory associated with local variable 'timebuf'
  // returned to caller [clang-analyzer-core.StackAddressEscape]
  return timebuf;
}

#endif
