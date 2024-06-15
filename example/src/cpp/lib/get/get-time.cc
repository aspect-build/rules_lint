#include "get-time.h"
#include <ctime>
#include <string>

// Some deliberately bad code
const char* get_localtime_impl() {
  std::time_t result = std::time(nullptr);
  std::string result_str = std::asctime(std::localtime(&result));
  return strdup(result_str.c_str());
}
