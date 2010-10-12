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
 * @date   October 10 2010
 */

#include "Debug.h"

generic module StaticRouteP(uint8_t maxRetries) {
  
  provides {
    interface Init;
    interface Send;
    interface Receive;
    interface Intercept;
    interface Packet;
  }

  uses {
    interface AMSend as SubSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
    interface Pool<message_t> as MessagePool;
    interface Queue<message_t*> as SendQueue;

    interface PacketLink;
    interface StaticRoute;
  }

} implementation {

  typedef nx_struct route_header {
  } route_header_t;

  message_t* ONE_NOK mine;
  bool sending;

  message_t loopbackMsgBuffer;
  message_t* ONE_NOK loopbackMsg;

  /***************** Init ****************/

  command error_t Init.init() {
    mine = NULL;
    sending = FALSE;
    loopbackMsg = &loopbackMsgBuffer;
    return SUCCESS;
  }

  /***************** Send ****************/

  task void sendTask() {
    message_t* msg;

    if(sending || call SendQueue.empty()) {
      return;
    }

    msg = call SendQueue.dequeue();
    call PacketLink.setRetries(msg, maxRetries);
    call PacketLink.setRetryDelay(msg, 0);

    // loop back handling 
    if(call StaticRoute.arrived(msg)) {
      memcpy(loopbackMsg, msg, sizeof(message_t));
      loopbackMsg = signal Receive.receive(loopbackMsg, call Packet.getPayload(loopbackMsg, call Packet.payloadLength(loopbackMsg)), call Packet.payloadLength(loopbackMsg));
      signal SubSend.sendDone(msg, SUCCESS);
      return;
    }

    // check if route exists
    if(!call StaticRoute.hasRoute(msg)) {
      debug("StaticRoute", "No route for packet!\n");
      goto next;
    }

    // check if we should forward
    if(!signal Intercept.forward(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg))) {
      debug("StaticRoute", "Discarding packet!\n");
      goto next;
    }

    // send message
    if(call SubSend.send(call StaticRoute.nextHop(msg), msg, call Packet.payloadLength(msg))==SUCCESS) {
      debug("StaticRoute", "sending packet\n");
      sending = TRUE;
      return;
    } else {
      debug("StaticRoute", "Error: Subsend FAILED\n");
      goto next;
    }
    
  next:
    if(mine!=NULL && msg==mine) {
      mine = NULL;
      signal Send.sendDone(msg, FAIL);
    } else {
      call MessagePool.put(msg);
    }
    post sendTask();
  }
  
  command error_t Send.send(message_t* msg, uint8_t len) {
    if(mine!=NULL) {
      debug("StaticRoute", "Busy, already sending\n");
      return EBUSY;
    } else {
      error_t result = call SendQueue.enqueue(msg);
      if(result==SUCCESS) {
        debug("StaticRoute", "Enqueued own\n");
        mine = msg;
        post sendTask();
      }
      return result;
    }
  }
  
  command error_t Send.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }
    
  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }
  
  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  event void SubSend.sendDone(message_t* msg, error_t error) {
    if(mine!=NULL && msg==mine) {
      mine = NULL;
      signal Send.sendDone(msg, error);
    } else {
      call MessagePool.put(msg);
    }
    sending = FALSE;
    post sendTask();
  }

  /***************** Receive ****************/
  
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if(call StaticRoute.arrived(msg)) {
      debug("StaticRoute", "Deliver packet!\n");
      return signal Receive.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));
    } else {
      if(call MessagePool.empty()) {
        debug("StaticRoute", "Message pool empty, so cannot forward!\n");
        return msg;
      } else {
        debug("StaticRoute", "Forward packet!\n");
        call SendQueue.enqueue(msg);
        post sendTask();
        return call MessagePool.get();
      }      
    }
  }
  
  /***************** Packet ****************/
  
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(route_header_t);
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(route_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(route_header_t);
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    void* payload = call SubPacket.getPayload(msg, len + sizeof(route_header_t));
    if (payload != NULL) {
      payload += sizeof(route_header_t);
    }
    return payload;
  }

  /***************** Defaults ****************/
  
  default event bool Intercept.forward(message_t* msg, void* payload, uint8_t len) {
    return TRUE;
  }

  default command bool StaticRoute.arrived(message_t* msg) {
    return TOS_NODE_ID==0;
  }

  default command bool StaticRoute.hasRoute(message_t* msg) {
    return TOS_NODE_ID!=0;
  }

  default command am_addr_t StaticRoute.nextHop(message_t* msg) {
    return TOS_NODE_ID-1;
  }

}
