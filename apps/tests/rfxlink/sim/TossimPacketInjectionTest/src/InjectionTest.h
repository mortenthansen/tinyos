#ifndef INJECTIONTEST_H
#define INJECTIONTEST_H

#include "message.h"
#include "AM.h"

enum {
  AM_INJECTIONTEST_MSG = 10,
};

typedef nx_struct injectiontest_msg {
  nx_uint8_t data[TOSH_DATA_LENGTH];
} injectiontest_msg_t;

#endif


