#ifndef BLOCKTEST_H
#define BLOCKTEST_H

#include "message.h"
#include "Block.h"

typedef nx_struct blocktest_msg {
  nx_uint8_t data[TOSH_DATA_LENGTH-sizeof(block_header_t)];
} blocktest_msg_t;

#endif
