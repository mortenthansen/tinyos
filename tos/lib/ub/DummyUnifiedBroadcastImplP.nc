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
 * @author Morten Tranberg Hansen <mth at cs dot au dot dk>
 * @date   May 18 2010
 */

generic module DummyUnifiedBroadcastImplP() {

  provides {
    interface Send[uint8_t client];
    interface Receive[am_id_t id];
    interface UnifiedBroadcast[uint8_t client];
  }

  uses {
    interface Send as SubSend[uint8_t client];
    interface Receive as SubReceive[am_id_t id];

    interface AMPacket;
    interface LocalTime<TMilli>;
  }

} implementation {

  command error_t Send.send[uint8_t client](message_t* msg, uint8_t len) {
    error_t err;

    if(call AMPacket.destination(msg)==AM_BROADCAST_ADDR) {
      dbg("UB.debug", "sending broadcast %hu\n", call AMPacket.type(msg));
      dbg("UB.stats", "UB_STATS_SEND_SENDING type %hhu @ %lu\n", call AMPacket.type(msg), call LocalTime.get());
    }

    err = call SubSend.send[client](msg, len);
    
    if(err!=SUCCESS) {
      dbg("UB.stats", "UB_STATS_SEND_SUBSEND_FAIL @ %lu\n", call LocalTime.get());
    }

    return err;
  }

  command error_t Send.cancel[uint8_t client](message_t* msg) {
    return call SubSend.cancel[client](msg);
  }

  command uint8_t Send.maxPayloadLength[uint8_t client]() {
    return call SubSend.maxPayloadLength[client]();
  }

  command void* Send.getPayload[uint8_t client](message_t* m, uint8_t len) {
    return call SubSend.getPayload[client](m, len);
  }

  event void SubSend.sendDone[uint8_t client](message_t* msg, error_t err) {

    if(call AMPacket.destination(msg)==AM_BROADCAST_ADDR) {
      if(err==SUCCESS) {
        dbgerror("UB.debug", "broadcast sent\n");
        dbg("UB.stats", "UB_STATS_SEND_SENDDONE @ %lu\n", call LocalTime.get());
      } else {
        dbgerror("UB.error", "broadcast senddone fail with %hhu\n", err);
        dbg("UB.stats", "UB_STATS_SEND_SENDDONE_FAIL @ %lu\n", call LocalTime.get());
      }
    }
    
    signal Send.sendDone[client](msg, err);
  }

  message_t* handle_receive(am_id_t id, message_t* msg, void* payload, uint8_t len, bool snooped) {

  }

  event message_t* SubReceive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    if(call AMPacket.destination(msg)==AM_BROADCAST_ADDR) {
      dbg("UB.debug", "receiving broadcast %hu\n", call AMPacket.type(msg));
      dbg("UB.stats", "UB_STATS_RECEIVE_BROADCAST @ %lu\n", call LocalTime.get());
      dbg("UB.stats", "UB_STATS_RECEIVE type %hhu @ %lu\n", call AMPacket.type(msg), call LocalTime.get());
    }
    return signal Receive.receive[id](msg, payload, len);
  }

  command void UnifiedBroadcast.disableDelay[uint8_t client]() {}

  command void UnifiedBroadcast.enableDelay[uint8_t client]() {}

 default event void Send.sendDone[uint8_t client](message_t* msg, error_t err) {}

 default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

  }
