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
#include "CollectionDebugMsg.h"

generic module CollectionDebugToDebugP() {

  provides {
    interface CollectionDebug;
  }

} implementation {

  void log(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
    switch(type) {
    case NET_C_FE_MSG_POOL_EMPTY:
      debug("Collection,FE_MSG_POOL_EMPTY", "FE message pool empty\n");
      break;
    case NET_C_FE_SEND_QUEUE_FULL:
      debug("Collection,FE_SEND_QUEUE_FULL", "FE queue full\n");
      break;
    case NET_C_FE_NO_ROUTE:
      debug("Collection,FE_NO_ROUTE", "FE no route\n");
      break;
    case NET_C_FE_SUBSEND_OFF:
      debug("Collection,FE_SUBSEND_OFF", "FE subsend OFF\n");
      break;
    case NET_C_FE_SUBSEND_BUSY:
      debug("Collection,FE_SUBSEND_BUSY", "FE subsend BUSY\n");
      break;
    case NET_C_FE_BAD_SENDDONE:
      debug("Collection,FE_BAD_SENDDONE", "FE bad senddone\n");
      break;
    case NET_C_FE_QENTRY_POOL_EMPTY:
      debug("Collection,FE_QENTRY_POOL_EMPTY", "FE qentry pool empty\n");
      break;
    case NET_C_FE_SUBSEND_SIZE:
      debug("Collection,FE_SUBSEND_SIZE", "FE subsend size\n");
      break;
    case NET_C_FE_LOOP_DETECTED:
      debug("Collection,FE_LOOP_DETECTED", "FE loop detected\n");
      break;
    case NET_C_FE_SEND_BUSY:
      debug("Collection,FE_SEND_BUSY", "FE send BUSY\n");
      break;

    case NET_C_FE_SENT_MSG:
      debug("Collection,FE_SENT_MSG", "FE sent msg: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;
    case NET_C_FE_RCV_MSG:
      debug("Collection,FE_RECEIVED_MSG", "FE received msg: %hhu, %hu, %hhu\n", (uint8_t)arg1, arg2, (uint8_t)arg3);
      break;
    case NET_C_FE_FWD_MSG:
      debug("Collection,FE_FORWARD_MSG", "FE forward msg: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;
    case NET_C_FE_DST_MSG:
      debug("Collection,FE_ARRIVED_MSG", "FE arrived msg: %hhu, %hu, %hhu\n", (uint8_t)arg1, arg2, (uint8_t)arg3);
      break;

    case NET_C_FE_SENDDONE_FAIL:
      debug("Collection,FE_SENDDONE_FAIL", "FE senddone FAIL: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;
    case NET_C_FE_SENDDONE_WAITACK:
      debug("Collection,FE_SENDDONE_WAITACK", "FE senddone WAITACK: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;
    case NET_C_FE_SENDDONE_FAIL_ACK_SEND:
      debug("Collection,FE_SENDDONE_FAIL_ACK_SEND", "FE senddone FAIL ack send: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;
    case NET_C_FE_SENDDONE_FAIL_ACK_FWD:
      debug("Collection,FE_SENDDONE_FAIL_ACK_FWD", "FE senddone FAIL ack fwd: %hhu, %hu, %hu\n", (uint8_t)arg1, arg2, arg3);
      break;

    case NET_C_FE_DUPLICATE_CACHE:
    case NET_C_FE_DUPLICATE_CACHE_AT_SEND:
      debug("Collection,FE_DUPLICATE_CACHE", "FE duplicate cache\n");
      break;
    case NET_C_FE_DUPLICATE_QUEUE:
      debug("Collection,FE_DUPLICATE_QUEUE", "FE duplicate queue\n");
      break;

    case NET_C_TREE_NO_ROUTE:
      debug("Collection,TREE_NO_ROUTE", "TREE no route\n");
      break;
    case NET_C_TREE_SENT_BEACON:
      debug("Collection,TREE_SENT_BEACON", "TREE sent beacon\n");
      break;
    case NET_C_TREE_RCV_BEACON:
      debug("Collection,TREE_RECEIVED_BEACON", "TREE receive beacon: %hu\n", arg1);
      break;

    case NET_C_TREE_NEW_PARENT:
      debug("Collection,TREE_NEW_PARENT", "TREE new parent: %hu, %hu, %hu\n", arg1, arg2, arg3);
      break;

    case NET_C_FE_SENDQUEUE_EMPTY:
      debug("Collection,FE_SEND_QUEUE_EMPTY", "FE send queue empty\n");
      break;

    default:
      //dbgerror("Debug", "%s: Type: %x\n", __FUNCTION__, type);
    }
  }

  command error_t CollectionDebug.logEvent(uint8_t type) {
    log(type, 0, 0, 0);
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
    log(type, arg, 0, 0);
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
    log(type, arg1, arg2, arg3);
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
    log(type, msg, origin, node);
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
    log(type, parent, hopcount, metric);
    return SUCCESS;
  }

  }
