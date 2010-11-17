#ifndef PACKETLINKTEST_H
#define PACKETLINKTEST_H

#include "message.h"
#include "AM.h"

enum {
  AM_TEST_MSG = 10,
};

typedef nx_struct test_msg {
  nx_uint8_t data[TOSH_DATA_LENGTH];
} test_msg_t;

#endif


