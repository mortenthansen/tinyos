#ifndef COLLECTIONTEST_H
#define COLLECTIONTEST_H

#include "AM.h"
#include "Collection.h"

#ifndef ROOT_NODE
#define ROOT_NODE COLLECTION_ROOT
#endif

enum collection_constants {
	DATA_COLLECTION_ID = 0xEE,
	AM_COLLECTION_MSG = 0xFD,
};

// Note: AM_COLLECTIONDEBUGMSG is added to lib/net/ctp/CtpDebug.h
// TOSH_DATA_LENGTH = 28, CTP_HEADER = 8  ==> MAX_SIZE = 20 bytes
// TOSH_DATA_LENGTH = 28, GEO_HEADER = 9  ==> MAX_SIZE = 19 bytes
typedef nx_struct collection_msg {
	nx_uint16_t value1;
	nx_uint16_t value2;
	nx_uint16_t value3;
	nx_uint16_t value4;
} collection_msg_t;

#endif
