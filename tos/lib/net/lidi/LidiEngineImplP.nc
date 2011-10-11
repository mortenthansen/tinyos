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
 * @date   October 20 2011
 */

#include <Lidi.h>

generic module LidiEngineImplP(uint8_t numDisseminators) {

  provides {
    interface Init;
    interface StdControl;
  }

  uses {
    interface LidiCache[uint8_t id];
    interface TrickleTimer;
    interface AMSend as Send;
    interface Receive;
    interface Packet;
    interface AMPacket;
  }

} implementation {

  message_t message;
  bool running;
  bool busy;

  task void sendTask();
  void send();
  void store(message_t* msg);

  void print_message(message_t* msg) {
    uint8_t* payload = call Packet.getPayload(msg, call Packet.maxPayloadLength());
    uint8_t i;
    dbg("Lidi.trace", "payload: ");
    for(i=0; i<call Packet.maxPayloadLength(); i++) {
      dbg_clear("Lidi.trace", "%hhu ", *(payload+i));
    }
    dbg_clear("Lidi.trace","\n");
  }

  /***************** Init ****************/

  command error_t Init.init() {
    running = FALSE;
    busy = FALSE;
    return SUCCESS;
  }

  /***************** StdControl ****************/

  command error_t StdControl.start() {
    dbg("Lidi.trace", "Lidi: start\n");
    call TrickleTimer.start();
    running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    dbg("Lidi.trace", "Lidi: stop\n");
    call TrickleTimer.stop();
    running = FALSE;
    return SUCCESS;
  }

  /***************** LidiCache ****************/

  event void LidiCache.newData[uint8_t id]() {
    send();
    call TrickleTimer.reset();
  }

  /***************** TrickleTimer ****************/

  event void TrickleTimer.fired() {
    send();
  }

  /***************** Send ****************/

  event void Send.sendDone( message_t* msg, error_t error ) {
    busy = FALSE;
  }

  /***************** Receive ****************/

  event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len ) {

    if (!running) { 
      return msg; 
    }

    dbg("Lidi.debug", "Lidi: received broadcast from %hu\n", call AMPacket.source(msg));

    store(msg);

    return msg;
  }

  /***************** Tasks ****************/

  task void sendTask() {
    send();
  }

  /***************** Functions ****************/

  void send() {
    uint8_t i;
    lidi_message_t* lmsg;
    uint8_t length = 0;

    if ( !running || busy ) { return; }

    lmsg = (lidi_message_t*) call Packet.getPayload( &message, sizeof(lidi_message_t) );

    if(lmsg != NULL) {

      for(i=0; i<numDisseminators; i++) {
        
        if(length+sizeof(lidi_message_t)+call LidiCache.getDataLength[i]() > call Packet.maxPayloadLength()) {
          dbgerror("Lidi.error", "Lidi: cannot fit all disseminators in packet, abort send...\n");
          return;
        }
        
        lmsg->len = sizeof(lidi_message_t)+call LidiCache.getDataLength[i]();
        lmsg->key = call LidiCache.getKey[i]();
        lmsg->seqno = call LidiCache.getSequenceNumber[i]();
        memcpy(lmsg->data, call LidiCache.getData[i](), call LidiCache.getDataLength[i]());
        
        //dbg("Lidi.trace","client %hhu, length %hhu\n", i, lmsg->len);

        length += lmsg->len;
        lmsg = (lidi_message_t*) ( ((uint8_t*)lmsg)+lmsg->len );
        
      }

      //print_message(&message);
      
      if(call Send.send(AM_BROADCAST_ADDR, &message, length)==SUCCESS) {
        busy = TRUE;
        dbg("Lidi.debug", "Lidi: sending broadcast with length %hhu\n", length);
      } else {
        dbgerror("Lidi.error", "Lidi: failed to send broadcast\n");
      }
      
    }
  }
  
  void store(message_t* msg) {
    uint8_t d;
    uint8_t length;
    lidi_message_t* lmsg;
    bool changed = FALSE;

    length = call Packet.payloadLength(msg);
    lmsg = (lidi_message_t*) call Packet.getPayload( msg, sizeof(lidi_message_t) );

    print_message(msg);

    for(d=0; d<numDisseminators; d++) {

      if(length<sizeof(lidi_message_t) || length<lmsg->len || call LidiCache.getDataLength[d]()!=lmsg->len-sizeof(lidi_message_t) || call LidiCache.getKey[d]()!=lmsg->key) {

        dbgerror("Lidi.error", "Lidi: got unproperly formatted message at client %hhu with length left %hhu, length %hhu, key %hu vs %hu exiting..\n", d, length, lmsg->len, call LidiCache.getKey[d](), lmsg->key);
        return;
            
      } else if(call LidiCache.getSequenceNumber[d]()==LIDI_SEQNO_UNKNOWN && lmsg->seqno!=LIDI_SEQNO_UNKNOWN) {
        
        dbg("Lidi.debug", "Lidi: got first data with key %hu for client %hhu\n", lmsg->key, d);
        call LidiCache.putData[d](lmsg->data, lmsg->len-sizeof(lidi_message_t), lmsg->seqno);
        call TrickleTimer.reset();
        changed = TRUE;
        
      } else if (lmsg->seqno==LIDI_SEQNO_UNKNOWN && call LidiCache.getSequenceNumber[d]()!=LIDI_SEQNO_UNKNOWN) {
        
        dbg("Lidi.debug", "Lidi: update neighbor without data with key %hu\n", lmsg->key);
        call TrickleTimer.reset();
        changed = TRUE;
        
      } else if ( (int32_t)( lmsg->seqno - call LidiCache.getSequenceNumber[d]() ) > 0 ) {
        
        dbg("Lidi.debug", "Lidi: got new data with key %hu for client %hhu\n", lmsg->key, d);
        call LidiCache.putData[d](lmsg->data, lmsg->len-sizeof(lidi_message_t), lmsg->seqno);
        call TrickleTimer.reset();
        changed = TRUE;        

      } else if ( (int32_t)( lmsg->seqno - call LidiCache.getSequenceNumber[d]() ) == 0 ) {
        
        dbg("Lidi.debug", "Lidi: got dublicate data with key %hu for client %hhu\n", lmsg->key, d);
        
      } else {
        
        dbg("Lidi.debug", "Lidi: update neighbor with new data with key %hu\n", lmsg->key);
        post sendTask();
        //call TrickleTimer.reset();
        changed = TRUE;

      }

      length -= lmsg->len;
      lmsg = (lidi_message_t*) ( ((uint8_t*)lmsg)+lmsg->len );
      
    }

    // If nothing changed, i.e. incomming were identical to current
    if(!changed) { 
      call TrickleTimer.incrementCounter();
    }
    
  }
  
  default command void* LidiCache.getData[uint8_t id]() { return NULL; }
  default command uint8_t LidiCache.getDataLength[uint8_t id]() { return 0; }
  default command uint16_t LidiCache.getKey[uint8_t id]() { return 0; }
  default command uint32_t LidiCache.getSequenceNumber[uint8_t id]() { return LIDI_SEQNO_UNKNOWN; }
  default command void LidiCache.putData[uint8_t id]( void* newData, uint8_t length, uint32_t seqno ) {}

}
