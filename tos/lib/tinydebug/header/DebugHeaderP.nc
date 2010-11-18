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
 * @date   September 14 2010
 */

generic module DebugHeaderP(typedef debug_header_t) {

	provides {
		interface DebugHeader<debug_header_t>;

		interface Init;
		interface Send;
		interface Receive;
		interface Receive as Snoop;
		interface Packet;
	}

	uses {
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface Receive as SubSnoop;
		interface Packet as SubPacket;
	}

} implementation {

	inline debug_header_t* get_header(message_t* msg);

	/***************** Init ****************/

	command error_t Init.init() {
		return SUCCESS;
	}

	/***************** Send ****************/

	command error_t Send.send(message_t* msg, uint8_t len) {
		signal DebugHeader.sendHeader(get_header(msg), msg);
		return call SubSend.send(msg, len+sizeof(debug_header_t));
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

	/***************** SubSend ****************/

  event void SubSend.sendDone(message_t* msg, error_t error) {
		signal Send.sendDone(msg, error);
	}

	/***************** Receive ****************/

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		signal DebugHeader.receiveHeader(get_header(msg), msg);
		return signal Receive.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));
	}

	/***************** Snoop ****************/

  event message_t* SubSnoop.receive(message_t* msg, void* payload, uint8_t len) {
		signal DebugHeader.snoopHeader(get_header(msg), msg);
		return signal Snoop.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));
	}

	/***************** Packet ****************/

	command void Packet.clear(message_t* msg) {
		call SubPacket.clear(msg);
	}

  command uint8_t Packet.payloadLength(message_t* msg) {
		return call SubPacket.payloadLength(msg)-sizeof(debug_header_t);
	}

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
		call SubPacket.setPayloadLength(msg, len+sizeof(debug_header_t));
	}

  command uint8_t Packet.maxPayloadLength() {
		return call SubPacket.maxPayloadLength()-sizeof(debug_header_t);
	}

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
		void* payload = call SubPacket.getPayload(msg, len + sizeof(debug_header_t));
		if (payload != NULL) {
      payload += sizeof(debug_header_t);
    }
    return payload;
	}


	/***************** Functions ****************/

	inline debug_header_t* get_header(message_t* msg) {
    return (debug_header_t*)call SubPacket.getPayload(msg, sizeof(debug_header_t));
	}

}
