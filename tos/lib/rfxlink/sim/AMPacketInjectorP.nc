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
 * @date   December 22 2010
 */

module AMPacketInjectorP {

  provides {
    interface Receive[am_id_t id];
  }

  uses {
    interface Receive as SubReceive[am_id_t id];
    interface AMPacket;
    interface Packet;
  }

} implementation {

  message_t injectionBuffer;
  message_t* injectionMsg = &injectionBuffer;

  /***************** Radio Stack Receive ****************/

  event message_t* SubReceive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive[id](msg, payload, len);
  }

  /***************** AM Injection Handling ****************/
    
  void active_message_deliver_handle(sim_event_t* evt) {
    message_t* m = (message_t*)evt->data;
    dbg("Packet", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());

    memcpy(injectionMsg, m, sizeof(message_t));
    injectionMsg = signal Receive.receive[call AMPacket.type(injectionMsg)](injectionMsg, call Packet.getPayload(injectionMsg, call Packet.maxPayloadLength()), call Packet.payloadLength(injectionMsg));
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

  /***************** Defaults ****************/

  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

}
