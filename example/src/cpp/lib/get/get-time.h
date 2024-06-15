#ifndef LIB_GET_TIME_H_
#define LIB_GET_TIME_H_

#include <string.h>

const char* get_localtime_impl();

inline char* get_localtime() {
    const char* time = get_localtime_impl();
    char timebuf[20];
    strcpy(timebuf, time);
    return timebuf;
}

#endif
