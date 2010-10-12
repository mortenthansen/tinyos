#ifndef STATICROUTETEST_H
#define STATICROUTETEST_H

enum {
  AM_TEST_MSG = 0x10,
};

typedef nx_struct test_msg {
  nx_uint32_t value;
} test_msg_t;

#endif
