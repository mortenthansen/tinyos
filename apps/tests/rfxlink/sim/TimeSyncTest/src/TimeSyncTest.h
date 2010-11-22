#ifndef TIMESYNCTEST_H
#define TIMESYNCTEST_H

enum {
  AM_TIMESYNCTEST_MSG = 3,
};

typedef nx_struct timesynctest_msg {
  nx_uint16_t seqno;
  nx_uint32_t localtime;
} timesynctest_msg_t;

#endif
