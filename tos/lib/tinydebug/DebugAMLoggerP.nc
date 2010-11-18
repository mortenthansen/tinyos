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

generic module DebugAMLoggerP() {

  provides {
    interface Init;
    interface DebugLog;
  }

  uses {
    interface AMSend;
    interface Packet;
    interface AMPacket;
    interface LocalTime<TMilli>;
  }

} implementation {

  enum {
    IGNORE_BYTES = 1, // we do not send the length
  };

  typedef nx_struct fragment_header {
    nx_uint8_t fragment;
    nx_uint8_t data[0];
  } fragment_header_t;

  uint8_t* buffer;
  uint8_t length;
  uint8_t current;
  uint8_t fragment;

  message_t debugMsg;

  task void sendTask();

  /***************** Init ****************/

  command error_t Init.init() {
    buffer = NULL;
    length = 0;
    current = 0;
    fragment = 0;
    return SUCCESS;
  }

  /***************** DebugLog ****************/

  command void DebugLog.flush(uint8_t* buf, uint16_t len) {
    dbg("DebugSender.debug", "%s: Flush %hhu\n", __FUNCTION__, len);
    buffer = buf;
    length = len;
    current = 0;
    fragment = 0;

    {
      uint8_t i;
      dbg("DebugSender.debug", "buffer: ");
      for(i=0; i<len; i++) {
        dbg_clear("DebugSender.debug", "%hhu ", buffer[i]);
      }
      dbg_clear("DebugSender.debug", "\n");
    }

    post sendTask();
  }

  /***************** Send ****************/

  event void AMSend.sendDone(message_t *msg, error_t error) {
    uint8_t maxpayload = call AMSend.maxPayloadLength() - sizeof(fragment_header_t);
    debug_msg_t* dbg;
    uint8_t fragments;

    dbg("DebugSender.debug", "%s: fragment %hhu of message sent\n", __FUNCTION__, fragment);

#ifdef TOSSIM
    {
      uint8_t i;
      uint8_t* payload = call Packet.getPayload(msg, call Packet.payloadLength(msg));
      dbg("DebugSender.debug", "sent %hhu: ", call Packet.payloadLength(msg));
      for(i=0; i<call Packet.payloadLength(msg); i++) {
        dbg_clear("DebugSender.debug", "%hhu ", payload[i]);
      }
      dbg_clear("DebugSender.debug", "\n");
    }
#endif

    dbg = (debug_msg_t*) &buffer[current];
    fragments = (dbg->len-IGNORE_BYTES+maxpayload-1)/maxpayload;

    // advance to next fragment
    fragment++;

    // if all fragments sent, advance to next message
    if(fragment>=fragments) {
      current += dbg->len;
      fragment = 0;
    }

    post sendTask();

  }

  /***************** Task ****************/

  task void sendTask() {
    uint8_t maxpayload = call AMSend.maxPayloadLength() - sizeof(fragment_header_t);
    debug_msg_t* dbg = (debug_msg_t*) &buffer[current];
    uint8_t fragments;
    uint8_t len;
    fragment_header_t* header;

    dbg("DebugSender.debug", "%s: sendTask.\n", __FUNCTION__);

    if(current>=length) {
      dbg("DebugSender.debug", "%s: Send queue is empty, flush done.\n", __FUNCTION__);
      buffer = NULL;
      length = 0;
      signal DebugLog.flushDone();
      return;
    } else if(dbg->len==0) {
      dbgerror("DebugSender.error", "%s: Length of debug msg is 0, flush done.\n", __FUNCTION__);
      buffer = NULL;
      length = 0;
      signal DebugLog.flushDone();
      return;
    }

    // set timestamp to ms since event
    if(fragment==0) {
      dbg->timestamp = call LocalTime.get() - dbg->timestamp;
    }

    fragments = (dbg->len-IGNORE_BYTES+maxpayload-1)/maxpayload;
    len = fragment==fragments-1 ? dbg->len-IGNORE_BYTES - (fragments-1)*maxpayload : maxpayload;
    header = (fragment_header_t*) call AMSend.getPayload(&debugMsg, len + sizeof(fragment_header_t));
    memcpy(header->data, &buffer[IGNORE_BYTES+current+fragment*maxpayload], len);

    // we set the fragment header byte where [1:4] is number of
    // fragments, and byte [5:8] is the current fragment
    header->fragment = (fragments & 0x0F) << 4 | (fragment & 0x0F);

    call AMPacket.setSource(&debugMsg, TOS_NODE_ID);

    dbg("DebugSender.debug", "%s: sending length %hhu.\n", __FUNCTION__, len);

    if (call AMSend.send(AM_BROADCAST_ADDR, &debugMsg, len + sizeof(fragment_header_t))!=SUCCESS) {
      dbgerror("DebugSender.error", "%s: Could not send debug message.\n", __FUNCTION__);
      current += dbg->len;
      fragment = 0;
      post sendTask();
    }
  }


}
