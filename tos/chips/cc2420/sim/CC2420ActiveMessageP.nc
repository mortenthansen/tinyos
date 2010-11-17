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
 * @date   February 08 2010
 */

module CC2420ActiveMessageP {

	provides {
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface AMPacket;
		interface Packet;
	}

	uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    command am_addr_t amAddress();
	}

} implementation {

  tossim_header_t* get_header(message_t* msg) {
    return (tossim_header_t*)(msg->data - sizeof(tossim_header_t));
  }

  tossim_metadata_t* get_metadata(message_t* msg) {
    return (tossim_metadata_t*)(&msg->metadata);
  }

  command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
    tossim_header_t* header = getHeader(msg);
    header->type = id;
    header->dest = addr;
    header->src = call AMPacket.address();
    header->length = len;
		dbg("CC2420ActiveMessage", "Sending\n");
    return call SubSend.send(msg, len);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }
  
  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
		dbg("CC2420ActiveMessage", "sendDone\n");
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		dbg("CC2420ActiveMessage", "receive\n");
    if (call AMPacket.isForMe(msg)) {
			dbg("CC2420ActiveMessage", "receive for me\n");
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
    }
    else {
			dbg("CC2420ActiveMessage", "snoop from %hu\n", call AMPacket.source(msg));
			return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
    }
  }

  command am_addr_t AMPacket.address() {
    return call amAddress();
  }
 
  command am_addr_t AMPacket.destination(message_t* msg) {
    return get_header(msg)->dest;
  }

  command void AMPacket.setDestination(message_t* msg, am_addr_t addr) {
    get_header(msg)->dest = addr;
  }

  command am_addr_t AMPacket.source(message_t* msg) {
    return get_header(msg)->src;
  }

  command void AMPacket.setSource(message_t* msg, am_addr_t addr) {
    get_header(msg)->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* msg) {
    return (call AMPacket.destination(msg) == call AMPacket.address() ||
						call AMPacket.destination(msg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* msg) {
    return get_header(msg)->type;
  }

  command void AMPacket.setType(message_t* msg, am_id_t t) {
    get_header(msg)->type = t;
  }


  command am_group_t AMPacket.group(message_t* msg) {
    return get_header(msg)->group;
  }
  
  command void AMPacket.setGroup(message_t* msg, am_group_t group) {
    get_header(msg)->group = group;
  }

  command am_group_t AMPacket.localGroup() {
    return TOS_AM_GROUP;
  }

  command void Packet.clear(message_t* msg) {}
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return getHeader(msg)->length;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    get_header(msg)->length = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
		return call SubSend.getPayload(msg, len);
  }

  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t err) {

  }


}
