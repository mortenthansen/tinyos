/**
 * @author Morten Tranberg Hansen (mth@daimi.au.dk)
 * @date   May 30 2008
 */

#ifndef SELECTIVETEST_H
#define SELECTIVETEST_H

#ifdef TOSSIM
#warning "Tossim defined"
#define MHZ 8 // missing when compiling with Counter32khz32C
#endif

enum {
  AM_DATA_MSG = 0x10,
};

typedef nx_struct data_msg {
	nx_uint32_t value;
} data_msg_t;

#endif
