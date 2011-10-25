/*
 * Copyright (c) 2009 Aarhus University
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
 * @date   October 18 2009
 */

module LlaReceiverP @safe() {

  provides {
    interface Init;
    interface BlockReceive;
  }

  uses {
    interface Leds;

    interface Receive as SubReceive;
    interface CC2420PacketBody;
    interface Packet;
    interface AMPacket;
    interface BlockPacket;

    interface NeighborTable;
    interface Neighbor;
    interface BlockNeighbor;

    interface Pool<message_t> as ReceivePool;
  }

} implementation {

  uint8_t get_number(neighbor_t* n, uint8_t seqno);
  void init(neighbor_t* n, uint8_t start, uint8_t size);
  message_t* add(neighbor_t* n, uint8_t number, message_t* msg);
  void arrive(neighbor_t* n);

  /***************** Init ****************/

  command error_t Init.init() {
    return SUCCESS;
  }

  /***************** BlockReceive ****************/

  command void BlockReceive.receiveDone(message_t** ONE msgs, uint8_t size) {
    uint8_t i;
    for(i=0; i<size; i++) {
      if(msgs[i]!=NULL) {
        call ReceivePool.put(msgs[i]);
      }
    }
  }

  /***************** SubReceive ****************/

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    neighbor_t* n = call NeighborTable.get(call AMPacket.source(msg));
    uint8_t seqno = (call CC2420PacketBody.getHeader(msg))->dsn;
    uint8_t number;

    if(n==NULL) {
      uint8_t i;
      dbgerror("Lla.error", "NEIGHBOR %hhu IS NULL!!!\n", call AMPacket.source(msg));

      dbgerror("Lla.error", "Table: ");
      for(i=0; i<call NeighborTable.numNeighbors(); i++) {
        dbg("Lla.error", "%hu, ", call Neighbor.getAddress(call NeighborTable.getById(i)));
      }
      dbg("Lla.error", "\n");

      call Leds.led0On();
      call Leds.led1On();
      call Leds.led2On();
      return msg;
    }

    if(call BlockNeighbor.getIsReceived(n)) {
      dbg("Lla.debug", "Receive init %hhu\n", call Neighbor.getAddress(n));
      init(n, call BlockPacket.getSequenceNumber(msg), call BlockPacket.getRequest(msg));
    }

    number = get_number(n, seqno);

    dbg("Lla.debug", "receive number:%hhu, r:%hhu\n", number, call BlockNeighbor.getReserved(n));

    while(number>=call BlockNeighbor.getReserved(n)) {
      dbg("Lla.debug", "Recieved late %hhu, seqno:%hhu, start:%hhu\n", call Neighbor.getAddress(n), seqno, call BlockNeighbor.getStartSequenceNumber(n));
      arrive(n);
      init(n, call BlockPacket.getSequenceNumber(msg), call BlockPacket.getRequest(msg));
      number = get_number(n, seqno);
    }

    msg = add(n, number, msg);

    if(number==(call BlockNeighbor.getReserved(n)-1)) {
      dbg("Lla.debug", "normal %hhu, seqno:%hhu, start:%hhu\n", call Neighbor.getAddress(n), seqno, call BlockNeighbor.getStartSequenceNumber(n));
      arrive(n);
    }

    return msg;

  }

  /***************** NeighborTable ****************/

  event void NeighborTable.evicted(am_addr_t addr) {

    dbg("Lla.debug", "************** EVICTED\n");

  }

  /***************** Functions ****************/

  uint8_t get_number(neighbor_t* n, uint8_t seqno) {
    uint8_t start = call BlockNeighbor.getStartSequenceNumber(n);
    if(seqno>=start) {
      return seqno-start;
    } else {
      return seqno + (256 - start);
    }
  }

  void init(neighbor_t* n, uint8_t start, uint8_t size) {
    call BlockNeighbor.setStartSequenceNumber(n, start);
    call BlockNeighbor.setReserved(n, size);
    call BlockNeighbor.clearReceived(n);
    call BlockNeighbor.setIsReceived(n, FALSE);
    call BlockNeighbor.setTimeout(n, 0); // setTimeout is used as full counter
    dbg("Lla.debug,RECEIVE_INIT", "Init receive for %hu\n", call Neighbor.getAddress(n));
  }

  message_t* add(neighbor_t* n, uint8_t number, message_t* msg) {
    message_t* empty = call ReceivePool.get();
    if(empty!=NULL) {
      dbg("Lla.debug,RECEIVE_AM", "Received packet from %hhu\n", call Neighbor.getAddress(n));
      call BlockNeighbor.setMessage(n, number, msg);
      call BlockNeighbor.setReceived(n, number);
      return empty;
    } else {
      call BlockNeighbor.setTimeout(n, 1 + call BlockNeighbor.getTimeout(n));
      return msg;
    }
  }

  void arrive(neighbor_t* n) {

    if(!call BlockNeighbor.getIsReceived(n)) {
      uint8_t i;
      uint8_t c = 0;
      message_t* ONE_NOK msgs[call BlockNeighbor.countReceived(n)];

      for(i=0; i<call BlockNeighbor.getReserved(n); i++) {
        message_t* m = call BlockNeighbor.getMessage(n, i);
        if(m!=NULL) {
          msgs[c] = m;
          c++;
        } else {
          dbgerror("Lla.error", "LOST\n");
          //debug_event1(DEBUG_RECEIVE_AM_LOST, call Neighbor.getAddress(n));
        }
        call BlockNeighbor.setMessage(n, i, NULL);
      }

      if(c!=call BlockNeighbor.countReceived(n)) {
        dbg("Lla.debug", "**** RX c:%hhu, count:%hhu\n", c, call BlockNeighbor.countReceived(n));
      }

      dbg("Lla.debug", "arrive %hhu\n", call BlockNeighbor.countReceived(n));

      signal BlockReceive.receive(msgs, call BlockNeighbor.countReceived(n), call Packet.payloadLength(msgs[0]));
      call BlockNeighbor.setIsReceived(n, TRUE);
      dbg("Lla.debug,RECEIVE_ARRIVED", "Block received from %hu, reserved %hhu, received %hhu, timeout %lu\n", call Neighbor.getAddress(n), call BlockNeighbor.getReserved(n), call BlockNeighbor.countReceived(n), call BlockNeighbor.getTimeout(n));

    }

  }

}
