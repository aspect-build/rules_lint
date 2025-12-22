#include "get-time.h"

#include <ctime>
#include <string>

// Some deliberately bad code
const char* get_localtime_impl() {
  // warning: variable 'result' of type 'std::time_t' (aka 'long long') can be
  // declared 'const' [misc-const-correctness]
  std::time_t result = std::time(nullptr);
  // warning: function 'asctime' is not bounds-checking and non-reentrant;
  // 'strftime' should be used instead
  // [bugprone-unsafe-functions,cert-msc24-c,cert-msc33-c]
  std::string result_str = std::asctime(std::localtime(&result));
  // rules_lint author: note the memory leak is not detected
  return strdup(result_str.c_str());
}

