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

generic module BlockingUdpSenderP() {

  provides {
    interface Init;
    interface BlockingUdpSend;
  }

  uses {
    interface UDP;
    interface UdpPacket;
    interface SystemCall;
    interface Mutex;
  }

} implementation {

  typedef struct params {
    udpmessage_t* msg;
    error_t error;
  } params_t;

  syscall_t* syscall = NULL;
  mutex_t mutex;

  command error_t Init.init() {
    call Mutex.init(&mutex);
    return SUCCESS;
  }

  void startTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call UDP.sendto(call UdpPacket.getDestination(p->msg), call UdpPacket.getPayload(p->msg), call UdpPacket.payloadLength(p->msg));
    call SystemCall.finish(s);
  }


  command error_t BlockingUdpSend.send(struct sockaddr_in6 *dest, udpmessage_t* msg) {
    syscall_t s;
    params_t p;

    call Mutex.lock(&mutex);

    if (syscall == NULL) {
      syscall = &s;
      call UdpPacket.setDestination(msg, dest);
      p.msg = msg;
      call SystemCall.start(&startTask, &s, INVALID_ID, &p);
      syscall = NULL;
    } else {
      p.error = EBUSY;
    }

    atomic {
      call Mutex.unlock(&mutex);
      return p.error;
    }

  }

  event void UDP.recvfrom(struct sockaddr_in6 *src, void *payload, uint16_t len, struct ip_metadata *meta) {}


}
