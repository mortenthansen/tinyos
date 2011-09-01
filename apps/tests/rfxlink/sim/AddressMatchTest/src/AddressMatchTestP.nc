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
 * @author Morten Tranberg Hansen
 * @date   March 30 2011
 */

#include <message.h>

module AddressMatchTestP {

  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    interface SplitControl as RadioControl;

    interface AMSend as Send;
    interface Receive;
    interface Receive as Snoop;
    interface AMPacket;
    interface PacketAcknowledgements as Acks;
  }

} implementation {

  typedef struct packet_payload {
    nx_uint8_t data[TOSH_DATA_LENGTH];
  } test_msg_t;

  message_t message;
  bool sending;

  /***************** Boot ****************/

  event void Boot.booted() {
    dbg("App.debug", "App: Booted!\n");
    memset(message.data, 17, TOSH_DATA_LENGTH);
    sending = FALSE;
    call RadioControl.start();
    if(TOS_NODE_ID!=RECEIVER) {
      call Timer.startPeriodic(PERIOD);
    }
  }

  /***************** RadioControl ****************/

  event void RadioControl.startDone(error_t error) {}

  event void RadioControl.stopDone(error_t error) {}

  /***************** Send ****************/

  inline void resend() {
  }

  event void Send.sendDone(message_t* msg, error_t error) {

    if(call Acks.wasAcked(msg)) {
      dbg("App.trace", " ---- ACKED!\n");
    } else {
      dbg("App.trace", " ---- NO ACK!\n");
    }

    sending = FALSE;
  }

  /***************** Timer ****************/

  event void Timer.fired() {
    dbg("App.trace", "App: Timer fired @ %lu\n", call Timer.getNow());

    if(sending) {
      dbgerror("App.error", "App: Already sending!\n");
      return;
    }

    call Acks.requestAck(&message);

    if (call Send.send(RECEIVER, &message, sizeof(test_msg_t)) != SUCCESS) {
      dbgerror("App.error", "App: Failed to send!\n");
    } else {
      dbg("App.trace", "App: Sending..\n");
      sending = TRUE;
    }  
  }

  /***************** Receive ****************/

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("App.debug", "App: Received from %hu\n", call AMPacket.source(msg));
    return msg;
  }

  /***************** Snoop ****************/

  event message_t* Snoop.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("App.debug", "App: Snooped from %hu\n", call AMPacket.source(msg));
    return msg;
  }

}

