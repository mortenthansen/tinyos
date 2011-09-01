#ifndef ACKDATATEST_H
#define ACKDATATEST_H

#include <message.h>

typedef struct data_msg {
  nx_uint8_t data[TOSH_DATA_LENGTH];
} data_msg_t;

typedef struct ack_msg {
  uint8_t counter;
} ack_msg_t;

#endif
