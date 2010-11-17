#ifndef LPLTEST_H
#define LPLTEST_H

#include "message.h"
#include "AM.h"

enum {
  AM_LPLTEST_MSG = 10,
};

typedef nx_struct lpltest_msg {
  nx_uint8_t data[TOSH_DATA_LENGTH];
} lpltest_msg_t;

#endif


