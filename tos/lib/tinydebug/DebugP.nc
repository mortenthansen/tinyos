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

#include "Debug.h"

#ifdef __STDC__
#include <stdarg.h>
#else
#include <varargs.h>
#endif

module DebugP {

  provides {
    interface Init;
  }

  uses {
    interface DebugListen;
    interface DebugLog @atmostonce();
    interface LocalTime<TMilli>;
  }

}
implementation {

  uint8_t buffer[DEBUG_BUFFER_SIZE];
  uint16_t size;
  uint16_t flushing;
  uint8_t seqno;

  task void flushTask();
  void check_buffer();

  /***************** Init ****************/

  command error_t Init.init() {
    size = 0;
    seqno = 0;
    flushing = 0;
    return SUCCESS;
  }

  /***************** DebugLog ****************/

  event void DebugLog.flushDone() {
    uint8_t i;
    dbg("Debug.debug", "Flush done with size: %hu and flushing: %hu\n", size, flushing);
    atomic {
      // Can't use memcpy as areas can overlap
      for(i=0; i<size-flushing; i++) {
        buffer[i] = buffer[flushing+i];
      }
      size = size - flushing;
      flushing = 0;
    }
    check_buffer();
  }

  /***************** debug functions ****************/

#ifdef DEBUG_FILTER_LIST
  bool in_filter(const char* id) {
    char* list[]={DEBUG_FILTER_LIST};
    uint8_t i;
    for(i=0; i<sizeof(list)/sizeof(char*); i++) {
      if(strncmp(id,list[i],strlen(list[i]))==0) {
        return TRUE;
      }
    }
    return FALSE;
  }
#endif

#ifdef DEBUG_IGNORE_LIST
  bool in_ignore(const char* id) {
    char* list[]={DEBUG_IGNORE_LIST};
    uint8_t i;
    for(i=0; i<sizeof(list)/sizeof(char*); i++) {
      if(strncmp(id,list[i],strlen(list[i]))==0) {
        return TRUE;
      }
    }
    return FALSE;
  }
#endif

  void debug_buffer_full() {
    debug("BUFFER_FULL", "Buffer is FULL, debug messages lost\n");
  }

#define __DEBUG_ADD(TYPE, VALUE)                                        \
  if(size+dbg->len+sizeof(TYPE)<DEBUG_BUFFER_SIZE-sizeof(debug_msg_t)) { \
    nx_##TYPE value;                                                    \
    value = VALUE;                                                      \
    memcpy(&buffer[size+dbg->len], &value, sizeof(TYPE));               \
    dbg("Debug.debug", "Adding type "#TYPE" to debug message at %hhu\n", dbg->len); \
    dbg->len += sizeof(TYPE);                                           \
  } else {                                                              \
    if(strcmp(id,"BUFFER_FULL")!=0) {                                   \
      debug_buffer_full();                                              \
    }                                                                   \
    dbgerror("Debug.error", "%s: buffer full with type "#TYPE", discarding debug\n", __FUNCTION__); \
    return;                                                             \
  }

  void tinydebug(const uint8_t uid, const char* id, const char* format, ...) @C() @spontaneous()  {
    uint32_t timestamp = call LocalTime.get();
    char *p;
    va_list argp;
    debug_msg_t* dbg;

    dbg("Debug.debug", "%s: debugging uid %hhu @ %lu\n", __FUNCTION__, uid, timestamp);

    atomic {

#ifdef DEBUG_FILTER_LIST
#warning "*** SOME DEBUG MESSAGES ARE FILTERED ***"
      if(!in_filter(id)) {
        dbg("Debug.debug", "%s: Id \"%s\" is not in filter list.\n", __FUNCTION__, id);
        return;
      }
#endif
#ifdef DEBUG_IGNORE_LIST
#warning "*** SOME DEBUG MESSAGES ARE IGNORED ***"
      if(in_ignore(id)) {
        dbg("Debug.debug", "%s: Id \"%s\" is in ignore list.\n", __FUNCTION__, id);
        return;
      }
#endif

      if(size+sizeof(debug_msg_t)>=DEBUG_BUFFER_SIZE-sizeof(debug_msg_t)) {
        // if not BUFFER_FULL message, report error
        if(strcmp(id,"BUFFER_FULL")!=0) {
          dbgerror("Debug.error", "%s: init buffer full, discarding debug: %hu >= %hu\n", __FUNCTION__, size+sizeof(debug_msg_t), DEBUG_BUFFER_SIZE-sizeof(debug_msg_t));
          debug_buffer_full();
          return;
        } else if(size+sizeof(debug_msg_t)>=DEBUG_BUFFER_SIZE) {
          dbgerror("Debug.error", "no room for BUFFER_FULL message, but one has already been added anyway");
          return;
        }
      }

      dbg = (debug_msg_t*) &buffer[size];
      dbg->len = sizeof(debug_msg_t);
      dbg->seqno = seqno;
      dbg->timestamp = timestamp;
      dbg->uid = uid;

      va_start(argp, format);

      for(p = (char *)format; *p != '\0'; p++) {
        if(*p != '%') {
          //dbg("Debug.debug", "---- continue with %s\n", p);
          continue;
        }

        switch(*++p) {

          // Handle h*
        case 'h':
          switch(*++p) {
          case 'h':
            switch(*++p) {
            case 'i':
            case 'd':
              __DEBUG_ADD(int8_t, (int8_t) va_arg(argp, int))
                break;
            case 'u':
              __DEBUG_ADD(uint8_t, (uint8_t) va_arg(argp, unsigned int))
                break;
            case 'x':
              __DEBUG_ADD(uint8_t, (uint8_t) va_arg(argp, unsigned int))
                break;
            }
            break;
          case 'i':
          case 'd':
            __DEBUG_ADD(int16_t, (int16_t) va_arg(argp, int))
              break;
          case 'u':
            __DEBUG_ADD(uint16_t, (uint16_t) va_arg(argp, unsigned int))
              break;
          case 'x':
            __DEBUG_ADD(uint16_t, (uint16_t) va_arg(argp, unsigned int))
              break;
          }
          break;


          // Use of non length specified int's is discouraged.
        case 'i':
        case 'd':
          __DEBUG_ADD(int16_t, (int16_t) va_arg(argp, int))
            break;
        case 'u':
          __DEBUG_ADD(uint16_t, (uint16_t) va_arg(argp, unsigned int))
            break;
        case 'x':
          __DEBUG_ADD(uint16_t, (uint16_t) va_arg(argp, unsigned int))
            break;

          // Handle l*
        case 'l':
          switch(*++p) {
          case 'l':
            switch(*++p) {
            case 'i':
            case 'd':
              __DEBUG_ADD(int64_t, (int64_t) va_arg(argp, long long int))
                break;
            case 'u':
              __DEBUG_ADD(uint64_t, (uint64_t) va_arg(argp, unsigned long long int))
                break;
            }
            break;
          case 'i':
          case 'd':
            __DEBUG_ADD(int32_t, (int32_t) va_arg(argp, long int))
              break;
          case 'u':
            __DEBUG_ADD(uint32_t, (uint32_t) va_arg(argp, unsigned long int))
              break;
          case 'x':
            __DEBUG_ADD(uint32_t, (uint32_t) va_arg(argp, unsigned long int))
              break;
          }
          break;

        case 'f':
#ifdef TOSSIM
          // TOSSIM float is in small endian so we convert it to big endian
          // to be compatible with nx_float and Java's Float.intBitsToFloat
          if(size+dbg->len+sizeof(float)<DEBUG_BUFFER_SIZE-sizeof(debug_msg_t)) {
            float value = (float) va_arg(argp, double);
            memcpy(&buffer[size+dbg->len+3], (uint8_t*)&value, 1);
            memcpy(&buffer[size+dbg->len+2], (uint8_t*)&value+1, 1);
            memcpy(&buffer[size+dbg->len+1], (uint8_t*)&value+2, 1);
            memcpy(&buffer[size+dbg->len], (uint8_t*)&value+3, 1);
            dbg->len += sizeof(float);
            dbg("Debug.debug", "Adding type float to debug message\n");
          } else {
            dbgerror("Debug.error", "%s: buffer full with type float, discarding debug\n", __FUNCTION__);
            return;
          }
#else
          __DEBUG_ADD(float, (float) va_arg(argp, double))
#endif
            break;

          // If not recognized, fall through and ignore.

        }
      }

      va_end(argp);

      size += dbg->len;
      seqno++;
      dbg("Debug.debug", "%s: Done passing args.\n", __FUNCTION__);
      call DebugListen.handle(id, dbg);

    }

    if(strcmp(id, "FORCE_FLUSH")!=0) {
      check_buffer();
    }
  }

  inline void debug_flush() @C() @spontaneous() __attribute__ ((always_inline)) {
    post flushTask();
  }

  inline bool debug_isflushing() @C() @spontaneous() __attribute__ ((always_inline)) {
    return flushing>0 ? TRUE : FALSE;
  }


  /***************** Tasks ****************/

  task void flushTask() {
    uint16_t s;
    atomic s = size;

    if(s==0) {
      dbg("Debug.debug", "%s: no message to flush\n", __FUNCTION__);
      return;
    }

    if(flushing>0) {
      dbg("Debug.debug", "%s: already flushing\n", __FUNCTION__);
      return;
    }

    dbg("Debug.debug", "%s: flushTask size: %hu.\n", __FUNCTION__, size);

    atomic {
      flushing = size;
      call DebugLog.flush(buffer, s);
    }
    //debug("WHAT", "HEJ MED DIG\n");
  }

  task void forceFlushTask() {
    uint16_t s;
    atomic s = size;
    debug("FORCE_FLUSH", "Force flush with size %hu\n", s);
  }

  /***************** Functions ****************/

  void check_buffer() {
    uint16_t s;
    atomic s = size;

    if(s==0) {
      return;
    }

#ifdef DEBUG_NO_AUTO_FLUSH
#warning "*** DEBUG AUTO FLUSH IS DEACTIVATED ***"
    if(s>=(DEBUG_BUFFER_SIZE/4)*3) {
      dbg("Debug.debug", "%s: Force flush with size %hu.!\n", __FUNCTION__, s);
      post forceFlushTask();
      post flushTask();
    }
#else
    post flushTask();
#endif
  }

  /***************** Defaults ****************/

 default async command void DebugListen.handle(const char* id, debug_msg_t* debug) {}

 default command void DebugLog.flush(uint8_t* buf, uint16_t len) {
   signal DebugLog.flushDone();
 }

}
