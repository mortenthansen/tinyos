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
 * @date   November 13 2010
 */

#include <Tasklet.h>
#include <message.h>

module AckDataTestP {

  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    interface Timer<TMilli> as DelayTimer;

    interface SplitControl as RadioControl;

    interface AMSend as Send;
    interface Receive;

    interface AMPacket;
    interface PacketAcknowledgements as Acks;
    interface AckData<ack_msg_t>;
  }

} implementation {

  message_t message;

  uint8_t counter;

  void print_packet(message_t* msg) {
    uint8_t i;
    dbg("App.debug", "packet:");
    for(i=0; i<sizeof(message_t); i++) {
      dbg_clear("App.debug", " %hhu", *((uint8_t*)msg+i));
    }
    dbg_clear("App.debug", "\n");
  }

  /***************** Boot ****************/

  event void Boot.booted() {
    dbg("App.debug", "Booted!\n");
    memset(message.data, 17, TOSH_DATA_LENGTH);
    call RadioControl.start();
  }

  /***************** RadioControl ****************/

  event void RadioControl.startDone(error_t error) {
    if(error==SUCCESS) {
      dbg("App.debug", "Radio Started!\n");
      call Timer.startPeriodic(PERIOD);
    } else {
      dbgerror("App.error", "Failed to start radio, trying again\n");
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t error) {}


  /***************** Send ****************/

  task void sendTask() {
    call Acks.requestAck(&message);
    if (call Send.send(TOS_NODE_ID+1, &message, sizeof(data_msg_t)) != SUCCESS) {
      dbgerror("App.error", "Failed to send0!\n");
      //post send0Task();
    } else {
      dbg("App.debug", "Send0 is sending!\n");
    }
  }

  task void broadcastTask() {
    call Acks.requestAck(&message);
    if (call Send.send(TOS_NODE_ID-1, &message, sizeof(data_msg_t)) != SUCCESS) {
      dbgerror("App.error", "Failed to broadcast0!\n");
    }
  }

  event void Send.sendDone(message_t* msg, error_t error) {
    if((TOS_NODE_ID%2) == 0) {
      if(call Acks.wasAcked(msg)) {
        dbg("App.debug", "ACKED!\n");
      } else {
        dbg("App.debug", "NOT ACKED!\n");
      }
    } else {
#ifdef RECEIVER_BROADCAST
      //post broadcast0Task();
#endif
    }
  }

  /***************** Timer ****************/

  event void Timer.fired() {
    if((TOS_NODE_ID%2) == 0) {
      dbg("App.debug", "Timer fired!\n");   
      post sendTask();
    } else {
#ifdef RECEIVER_BROADCAST_DELAY
      if(RECEIVER_BROADCAST_DELAY==0) {
        post broadcastTask();
      } else {
        call DelayTimer.startOneShot(RECEIVER_BROADCAST_DELAY);
      }
#endif
    }
  }

  event void DelayTimer.fired() {
    dbg("App.debug", "Timer fired!\n");   
    post broadcastTask();
  }

  /***************** Receive ****************/

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if(call AMPacket.destination(msg)!=AM_BROADCAST_ADDR) {
      dbg("App.debug", "Received!\n");
    } else {
      dbg("App.debug", "Beacon received!\n");
    }
    //print_packet(bufPtr);
    return msg;
  }

  /***************** AckData ****************/

  tasklet_async event void AckData.requestData(uint16_t destination) {
    ack_msg_t* data = call AckData.getData();
    atomic {
      data->counter = counter++;
      //dbg("App.debug", "### Request data for radio %hhu!\n", radio);
    }
  }

  tasklet_async event void AckData.dataAvailable(uint16_t source, ack_msg_t* data) {
    atomic {
      dbg("App.debug", "### Available data with counter %hhu!\n", data->counter);
    }
  }

  /***************** Defaults ****************/

  default command error_t RadioControl.start() { return FAIL; };
  default async command error_t Acks.requestAck(message_t* msg) { return FAIL; }
  default async command bool Acks.wasAcked(message_t* msg) { return FALSE; }

  default tasklet_async command ack_msg_t* AckData.getData() { return NULL; }

  default command am_addr_t AMPacket.destination(message_t* msg) { return AM_BROADCAST_ADDR; }

}

