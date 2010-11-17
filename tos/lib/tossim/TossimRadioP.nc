// $Id: TossimActiveMessageC.nc,v 1.7 2010-06-29 22:07:51 scipio Exp $
/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * The basic TOSSIM radio layer that provides Send, Receive and Packet
 * to upper layers.
 *
 * @author Philip Levis
 * @author Morten Tranberg Hansen (ported from old TossimActiveMessageC)
 * @date October 2 2010
 */

module TossimRadioP {

  provides {
    interface Send;
    interface Receive;
    interface TossimPacket;
    interface Packet;
  }

  uses {
    interface TossimPacketModel as Model;
    command am_addr_t amAddress();
  }

} implementation {

  message_t buffer;
  message_t* bufferPointer = &buffer;
  
  tossim_header_t* getHeader(message_t* amsg) {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }
  
  tossim_metadata_t* getMetadata(message_t* amsg) {
    return (tossim_metadata_t*)(&amsg->metadata);
  }
  
  command error_t Send.send(message_t* amsg, uint8_t len) {
    error_t err;
    tossim_header_t* header = getHeader(amsg);
    header->length = len;
    err = call Model.send((int)header->dest, amsg, len + sizeof(tossim_header_t) + sizeof(tossim_footer_t));
    return err;
  }
  
  command error_t Send.cancel(message_t* msg) {
    return call Model.cancel(msg);
  }
  
  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }
  
  command void* Send.getPayload(message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  command int8_t TossimPacket.strength(message_t* msg) {
    return getMetadata(msg)->strength;
  }

  event void Model.sendDone(message_t* msg, error_t result) {
    signal Send.sendDone(msg, result);
  }

  /* Receiving a packet */
  
  event void Model.receive(message_t* msg) {
    uint8_t len;
    void* payload;
    
    memcpy(bufferPointer, msg, sizeof(message_t));
    len = call Packet.payloadLength(bufferPointer);
    payload = call Packet.getPayload(bufferPointer, call Packet.maxPayloadLength());
    
    bufferPointer = signal Receive.receive(bufferPointer, payload, len);
  }
  
  event bool Model.shouldAck(message_t* msg) {
    tossim_header_t* header = getHeader(msg);
    if (header->dest == call amAddress()) {
      dbg("Acks", "Received packet addressed to me so ack it\n");
      return TRUE;
    }
    return FALSE;
  }
  
  command void Packet.clear(message_t* msg) {}
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return getHeader(msg)->length;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getHeader(msg)->length = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return msg->data;
    }
    else {
      return NULL;
    }
  }
  
  default command error_t Model.send(int node, message_t* msg, uint8_t len) {
    return FAIL;
  }

  default command error_t Model.cancel(message_t* msg) {
    return FAIL;
  }

  default command am_addr_t amAddress() {
    return 0;
  }
  
  void active_message_deliver_handle(sim_event_t* evt) {
    message_t* m = (message_t*)evt->data;
    dbg("Packet", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());
    signal Model.receive(m);
  }
  
  sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t) {
    sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
    evt->mote = node;
    evt->time = t;
    evt->handle = active_message_deliver_handle;
    evt->cleanup = sim_queue_cleanup_event;
    evt->cancelled = 0;
    evt->force = 0;
    evt->data = msg;
    return evt;
  }
  
  void active_message_deliver(int node, message_t* msg, sim_time_t t) @C() @spontaneous() {
    sim_event_t* evt = allocate_deliver_event(node, msg, t);
    sim_queue_insert(evt);
  }
  
}
