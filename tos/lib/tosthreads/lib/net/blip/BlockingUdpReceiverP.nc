/*
 * Copyright (c) 2011 Aarhus University
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
 * @author Morten Tranberg Hansen <mth at cs dot au dot dk>
 * @date   February 8 2011
 */

#include "Udp.h"

generic module BlockingUdpReceiverP() {

  provides {
    interface Init;
    interface BlockingUdpReceive;
  }

  uses {
    interface UDP;
    interface UdpPacket;
    interface SystemCall;
    interface Mutex;
    interface Timer<TMilli>;
  }

} implementation {

  typedef struct bindparams {
    error_t error; // error needs to be first
    uint16_t port;
  } bindparams_t;

  typedef struct receiveparams {
    error_t error; // error needs to be first
    udpmessage_t* msg;
    uint32_t* timeout;
  } receiveparams_t;

  syscall_t* syscall = NULL;
  mutex_t mutex;

  command error_t Init.init() {
    call Mutex.init(&mutex);
    return SUCCESS;
  }

  void bindTask(syscall_t* s) {
    bindparams_t* p = s->params;
    p->error = call UDP.bind(p->port);
    call SystemCall.finish(s);
  }

  void timerTask(syscall_t* s) {
    receiveparams_t* p = s->params;
    call Timer.startOneShot(*(p->timeout));  
  }

  command error_t BlockingUdpReceive.bind(uint16_t port) {
    syscall_t s;
    bindparams_t p;

    call Mutex.lock(&mutex);

    if (syscall == NULL) {
      syscall = &s;
      p.port = port;
      call SystemCall.start(&bindTask, &s, INVALID_ID, &p);
      syscall = NULL;
    } else {
      p.error = EBUSY;
    }

    atomic {
      call Mutex.unlock(&mutex);
      return p.error;
    }
  }

  command error_t BlockingUdpReceive.receive(udpmessage_t* msg, uint32_t timeout) {
    syscall_t s;
    receiveparams_t p;

    call Mutex.lock(&mutex);

    if (syscall == NULL) {
      syscall = &s;
      p.error = EBUSY;
      p.msg = msg;
      p.timeout = &timeout;
      if(timeout != 0) {
        call SystemCall.start(&timerTask, &s, INVALID_ID, &p);
      } else {
        call SystemCall.start(SYSCALL_WAIT_ON_EVENT, &s, INVALID_ID, &p);
      }
      syscall = NULL;
    } else {
      p.error = EBUSY;
    }

    atomic {
      call Mutex.unlock(&mutex);
      return p.error;
    }
  }

  event void UDP.recvfrom(struct sockaddr_in6 *src, void *payload, uint16_t len, struct ip_metadata *meta) {
    receiveparams_t* p;
    
    if(len>UDP_MAX_PAYLOAD_LENGTH || syscall==NULL) {
      return;
    }

    p = syscall->params;
    if( (p->error == EBUSY) ) {
      call Timer.stop();
      call UdpPacket.setSource(p->msg, src);
      memcpy(call UdpPacket.getPayload(p->msg), payload, len);
      call UdpPacket.setPayloadLength(p->msg, len);
      memcpy(call UdpPacket.getMetadata(p->msg), meta, sizeof(struct ip_metadata));
      p->error = SUCCESS;
      call SystemCall.finish(syscall);
    }

  }

  event void Timer.fired() {
    if(syscall!=NULL) {
      receiveparams_t* p = syscall->params;
      if( (p->error == EBUSY) ) {
        p->error = FAIL;
        call SystemCall.finish(syscall);
      }
    }
  }

}
