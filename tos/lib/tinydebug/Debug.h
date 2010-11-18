/*
 * Copyright (c) 2010 Aarhus University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Aarhus University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL AARHUS
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Morten Tranberg Hansen
 * @date   September 12 2010
 */

#ifndef DEBUG_H
#define DEBUG_H

typedef nx_struct debug_msg {
  nx_uint8_t len;
  nx_uint8_t seqno;
  nx_uint32_t timestamp;
  nx_uint8_t uid;
  nx_uint8_t args[0];
} debug_msg_t;

#ifdef DEBUG

#include "message.h"

#warning "*** DEBUG IS ACTIVATED ***"

#ifndef DEBUG_BUFFER_SIZE
#define DEBUG_BUFFER_SIZE 1000
#endif

enum {
  AM_DEBUG_MSG = 0xFE,
};

#ifndef TOSSIM
#define debug(...) tinydebug(unique("UNIQUE_TINYDEBUG"), __VA_ARGS__)
void __attribute__ ((__format__(printf, 3, 4))) tinydebug(const uint8_t uid, const char* id, const char* format, ...);
#else
#define debug(...)                                      \
  tinydebug(unique("UNIQUE_TINYDEBUG"), __VA_ARGS__);   \
  dbg(__VA_ARGS__)

// Format warnings on PC is not compatible with warnings on motes, so
// we disable it for TOSSIM.
void tinydebug(const uint8_t uid, const char* id, const char* format, ...);
#endif /* TOSSIM */

inline void debug_flush();
inline bool debug_isflushing();

#else /* DEBUG */

/*#ifdef TOSSIM
  #warning "*** DEBUG IS CONVERTED TO TOSSIM ***"
  #define debug(...) dbg(__VA_ARGS__)
  #else*/
#warning "*** DEBUG IS DISABLED ***"
#define debug(...) for(;0;)
//#endif

#define debug_flush() for(;0;)
#define debug_isflushing() FALSE

#endif /* DEBUG */

#endif /* DEBUG_H */
