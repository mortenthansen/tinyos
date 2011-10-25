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

module BtpReceiverP @safe() {

  provides {
    interface Init;
    interface BlockReceive;
  }

  uses {
    interface Random;
    interface Leds;
    interface Packet;

    interface Receive as SubReceive;
    interface Packet as SubPacket;

    interface AMSend as AckSend;
    interface AMPacket;
    interface BlockPacket;
    interface PacketAcknowledgements as Acks;

#ifndef TOSSIM
    interface RadioBackoff;
#endif
    interface PacketLink;

    interface NeighborTable;
    interface Neighbor;
    interface BlockNeighbor;
    interface Timer<TMilli>;

    interface Pool<message_t> as ReceivePool;
    interface Pool<block_ack_queue_entry_t> as AckPool;
    interface Queue<block_ack_queue_entry_t*> as AckQueue;

    interface TimeMeasure<uint32_t> as PacketTime;
  }

} implementation {

  message_t ackMessage;
  uint8_t poolSize;
  am_addr_t ackDestination;
  bool ackCancelled;

  void set_timeout(neighbor_t* n, uint32_t timeout);
  void clean_neighbor(neighbor_t* ONE n);
  void clear_ack(am_addr_t addr);
  void send_ack(neighbor_t* ONE n/*, uint8_t grant*/);
  void send_next_ack();
  void check_receive_done(neighbor_t* ONE n);
  bool is_last(neighbor_t* ONE n, uint8_t number);
  uint8_t get_number(neighbor_t* n, uint8_t seqno);

  /***************** Init ****************/

  command error_t Init.init() {
    poolSize = BLOCK_MAX_BUFFER_SIZE;
    ackDestination = AM_BROADCAST_ADDR;
    ackCancelled = FALSE;
    return SUCCESS;
  }

  /***************** SubReceive ****************/

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    //block_header_t* header = (block_header_t*)call SubPacket.getPayload(msg, sizeof(block_header_t));
    //block_header_t* header = get_header(msg);//(block_header_t*)payload;

    neighbor_t* n = call NeighborTable.get(call AMPacket.source(msg));
    dbg("Btp.debug", "Received from %hhu seqno %hhu reserved %hhu\n", call AMPacket.source(msg), call BlockPacket.getSequenceNumber(msg), call BlockNeighbor.getReserved(n));

    if(n==NULL) {
      dbg("Btp.debug,RECEIVE_UNKNOWNNEIGHBOR", "Rejecting packet from neighbor %hu not in neighbor table\n", call AMPacket.source(msg));
      return msg;
    }

    // clear pending acks
    clear_ack(call AMPacket.source(msg));

    // reset timeout from ack
    set_timeout(n, 0);

    if(call BlockPacket.getRequest(msg)!=0) {

      clean_neighbor(n);

      if(poolSize>=call BlockPacket.getRequest(msg)) {
        call BlockNeighbor.setReserved(n, call BlockPacket.getRequest(msg));
        poolSize -= call BlockPacket.getRequest(msg);
      } else if(poolSize>0) {
        call BlockNeighbor.setReserved(n, poolSize);
        poolSize = 0;
      }

      if(call BlockNeighbor.getReserved(n)>0) {
        //dbg("Btp.debug", "reserved %hhu for %hu out of wanted %hhu and remaining %hhu\n", call BlockNeighbor.getReserved(n), call AMPacket.source(msg), call BlockPacket.getRequest(msg), poolSize);
        //dbg("Btp.debug", "init %hhu for %hu\n", call BlockNeighbor.getReserved(n), call AMPacket.source(msg));

        dbg("Btp.debug,RECEIVE_INIT", "Init receive addr %hu\n", call Neighbor.getAddress(n));

        call BlockNeighbor.setMessage(n, 0, msg);
        call BlockNeighbor.setReceived(n, 0);
        call BlockNeighbor.setStartSequenceNumber(n, call BlockPacket.getSequenceNumber(msg));

        send_ack(n/*, call BlockNeighbor.getReserved(n)*/);

        return call ReceivePool.get();

      } else {
        dbg("Btp.debug,RECEIVE_INIT_FAILED", "Receive init failed, not able to reserve %hhu for %hu\n", call BlockPacket.getRequest(msg), call AMPacket.source(msg));

        call BlockNeighbor.setStartSequenceNumber(n, call BlockPacket.getSequenceNumber(msg));
        send_ack(n/*, 0*/);
        return msg;
      }

    } else if (call BlockNeighbor.getReserved(n)>0) {

      uint8_t number = get_number(n, call BlockPacket.getSequenceNumber(msg));

      dbg("Btp.debug,RECEIVE_RECEIVED", "Received from %hu, seqno %hhu\n", call AMPacket.source(msg), call BlockPacket.getSequenceNumber(msg));

      if(number>0) {

        // if we seen it before an earlier ack must have been lost
        // so we resend the ack.  this handles the case where reserved
        // and grant on receiver and sender, respectively, is not synced
        if(call BlockNeighbor.getReceived(n,number)) {

          send_ack(n);

          // else we store the new message
        } else {

          call BlockNeighbor.setReceived(n, number);
          call BlockNeighbor.setMessage(n, number, msg);
          msg = call ReceivePool.get();

          //dbg("Btp.debug", "received packet number %hhu from %hu with seqno %hhu\n",number, call Neighbor.getAddress(n), call BlockPacket.getSequenceNumber(msg));
          //dbg("Btp.debug", "received %hhu %hhu\n", call BlockPacket.getSequenceNumber(msg), call BlockNeighbor.countReceived(n));

          if(is_last(n, number)) {
            //dbg("Btp.debug", "is last: from: %hhu, seqno %hhu\n", call Neighbor.getAddress(n), call BlockPacket.getSequenceNumber(msg));
            send_ack(n/*, 0*/);
          }

          if(msg==NULL) {
            dbgerror("Btp.error", "ALLLLLLLLLLLLLLLLLLLLLLLLLAAARRMMM\n");
            call Leds.led0On();
            call Leds.led1On();
            call Leds.led2On();
            while(1);//morten
          }

        }

        return msg;

      } else {
        dbg("Btp.debug,RECEIVE_RECEIVED_WRONGNUMBER", "Received wrong number %hhu from %hu with seqno %hhu and start %hhu\n", number, call AMPacket.source(msg), call BlockPacket.getSequenceNumber(msg), call BlockNeighbor.getStartSequenceNumber(n));
        call Leds.led0Toggle();
        return msg;
      }

    } else {

      dbg("Btp.debug,RECEIVE_RECEIVED_NORMAL", "Received normal req: %hhu, res: %hhu\n", call BlockPacket.getRequest(msg), call BlockNeighbor.getReserved(n));
      call Leds.led1Toggle();

      return msg;//signal Receive.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));

    }

  }

  /***************** AckSend ****************/

  event void AckSend.sendDone(message_t* msg, error_t error) {
    neighbor_t* n = call NeighborTable.get(call AMPacket.destination(msg));

    //dbg("Btp.debug", "ack %hhu\n", call AMPacket.destination(msg));

    call PacketTime.stop();

    if(ackCancelled) {
      dbg("Btp.debug,RECEIVE_ACKDONE_CANCEL", "Cancel ack!\n");
    } else if(error==SUCCESS) {

      /*if(call PacketLink.wasDelivered(msg)) {
        dbg("Btp.debug", "ack sent %lu\n",time_get());
        } else {
        dbg("Btp.debug", "ack fail %lu\n",time_get());
        }*/
      //printfflush();

      if(call PacketLink.wasDelivered(msg)) {
        dbg("Btp.debug,RECEIVE_ACKDONE_ACK", "Response acked, time %lu\n", call PacketTime.get());
      } else {
        dbg("Btp.debug,RECEIVE_ACKDONE_NOACK", "Response not ACKED time %lu\n", call PacketTime.get());
      }

      check_receive_done(n);

      //#warning "MORTEN INSERT IF SO TIMER ONLY SET WHEN NOT RECEIVED"
      //set_timeout(n, BLOCK_RESPONSE_TIME);

      if(error==SUCCESS && n!=NULL && call BlockNeighbor.getReserved(n)>0) {
        //call BlockNeighbor.setTimeout(n, call Timer.getNow() + BLOCK_RESPONSE_TIME + (call BlockNeighbor.getReserved(n)-call BlockNeighbor.countReceived(n))*BLOCK_INTER_PACKET_ARRIVAL);

      }

    } else {
      dbgerror("Btp.error,ACKDONE_FAIL", "Failed to send response!\n");
    }

    ackDestination = AM_BROADCAST_ADDR;
    ackCancelled = FALSE;

    send_next_ack();

  }


  /***************** Timer ****************/

  event void Timer.fired() {
    uint8_t i;
    dbg("Btp.debug", "*** timeout fired\n");

    for(i=0; i<call NeighborTable.numNeighbors(); i++) {
      neighbor_t* n = call NeighborTable.getById(i);
      uint32_t t = call BlockNeighbor.getTimeout(n);
      if(t!=0 && t<=call Timer.getNow()) {

        /*
          #ifdef BLOCK_RECEIVE_TIMEOUT
          dbg("Btp.debug", DEBUG_RECEIVE_ABORT);

          //dbg("Btp.debug", "*** timeout neighbor %hu with %lu at %lu\n", call Neighbor.getAddress(n), t, call Timer.getNow());
          dbg("Btp.debug", "TIMEOUT\n");
          printfflush();
          clean_neighbor(n);
          #else
          #warning "*** BLOCK RECEIVE NEVER TIMES OUT ***"
          #endif*/

        dbg("Btp.debug", "######## TIMEOUT %hhu\n", call Neighbor.getAddress(n));
        //printfflush();
        send_ack(n);

        call BlockNeighbor.setTimeout(n, 0);

      }
    }

    set_timeout(NULL, 0);

  }

  /***************** RadioBackoff ****************/

#ifndef TOSSIM
  async event void RadioBackoff.requestInitialBackoff(message_t * msg) {
#ifdef NO_INITIAL_BACKOFF
    call RadioBackoff.setInitialBackoff(0);
#else
    //call RadioBackoff.setInitialBackoff ( call Random.rand16() % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
#endif
  }

  async event void RadioBackoff.requestCongestionBackoff(message_t * msg) {

  }

  async event void RadioBackoff.requestCca(message_t * ONE msg) {
#ifdef NO_BACKOFF
    call RadioBackoff.setCca(FALSE);
#endif
  }
#endif

  /***************** BlockReceive ****************/

  command void BlockReceive.receiveDone(message_t** ONE msgs, uint8_t size) {
    uint8_t i;
    for(i=0; i<size; i++) {
      call ReceivePool.put(msgs[i]);
    }
    poolSize += size;
    //dbg("Btp.debug", "poolSize %hhu vs %hhu\n",poolSize, call ReceivePool.size());
    //printfflush();
  }

  /***************** NeighborTable ****************/

  event void NeighborTable.evicted(am_addr_t addr) {

  }

  /***************** Tasks ****************/

  task void sendAckTask() {
    if(call AckQueue.empty()) {
      return;
    }

    if(ackDestination==AM_BROADCAST_ADDR) {
      block_ack_t* ack = (block_ack_t*) call SubPacket.getPayload(&ackMessage, sizeof(block_ack_t));
      block_ack_queue_entry_t* entry = call AckQueue.head();
      neighbor_t* n = call NeighborTable.get(entry->addr);

      if(n==NULL) {
        dbgerror("Btp.error", "MUST NOT HAPPEN!\n");
        send_next_ack();
        return;
      }

      //dbg("Btp.debug", "sending ack %hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu\n", call BlockNeighbor.getReceived(n,0),call BlockNeighbor.getReceived(n,1),call BlockNeighbor.getReceived(n,2),call BlockNeighbor.getReceived(n,3),call BlockNeighbor.getReceived(n,4),call BlockNeighbor.getReceived(n,5),call BlockNeighbor.getReceived(n,6),call BlockNeighbor.getReceived(n,7),call BlockNeighbor.getReceived(n,8),call BlockNeighbor.getReceived(n,9),call BlockNeighbor.getReceived(n,10));

      ack->grant = entry->grant;
      {
        uint8_t i;
        for(i=0; i<BLOCK_RECEIVED_ARRAY_SIZE; i++) {
          ack->received[i] = 0;
        }
        for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
          ack->received[i/8] |= ((uint8_t)call BlockNeighbor.getReceived(n,i))<<(i%8);
        }
      }
      ack->start = call BlockNeighbor.getStartSequenceNumber(n);

      //dbg("Btp.debug", "ack %hhu %hhu\n",entry->addr, entry->grant);

      call PacketLink.setRetries(&ackMessage, BLOCK_MAX_RETRANSMISSIONS);
#ifdef BLOCK_RANDOM_RETRY_DELAY
#warning "RANDOM RETRY DELAY USED"
      call PacketLink.setRetryDelay(&ackMessage, call Random.rand16() % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
#else
      call PacketLink.setRetryDelay(&ackMessage, BLOCK_DELAY_RETRANSMISSIONS);
#endif

      call PacketTime.start();

      if(call AckSend.send(call Neighbor.getAddress(n), &ackMessage, sizeof(block_ack_t))==SUCCESS) {
        ackDestination = call Neighbor.getAddress(n);
        ackCancelled = FALSE;

        if(ack->grant>0) {
          dbg("Btp.debug", "Response sent with grant %hhu and r %hhu - %hhu\n", ack->grant, call BlockNeighbor.countReceived(n), call PacketLink.wasDelivered(&ackMessage));
        } else {
          dbg("Btp.debug", "Response sent with no grant and r %hhu - %hhu\n", call BlockNeighbor.countReceived(n), call PacketLink.wasDelivered(&ackMessage));
        }

      } else {
        dbgerror("Btp.error,RECEIVE_ACK_FAIL", "Failed to send response, retry..\n");
        post sendAckTask();
      }
    } else {
      dbg("Btp.debug,RECEIVE_ACK_BUSY", "Already sending response..\n");
      //post sendAckTask();
    }
  }


  /***************** Functions ****************/

  void set_timeout(neighbor_t* n, uint32_t timeout) {
    uint8_t i;
    uint32_t smallest = 0xFFFFFFFF;
    uint32_t now = call Timer.getNow();

    // set timeout of specific neighbor
    if(n!=NULL) {
      call BlockNeighbor.setTimeout(n, timeout!=0?now+timeout:0);
    }

    // find the next timeout
    for(i=0; i<call NeighborTable.numNeighbors(); i++) {
      uint32_t t = call BlockNeighbor.getTimeout(call NeighborTable.getById(i));
      if(t>now && t<smallest) {
        smallest = t;
      }
    }

    // set timer to next timeout
    call Timer.stop();
    if(smallest!=0xFFFFFFFF) {
      //uint32_t t1 = call BlockNeighbor.getTimeout(call NeighborTable.get(2));
      //uint32_t t2 = call BlockNeighbor.getTimeout(call NeighborTable.get(4));
      call Timer.startOneShot(smallest - now);
      //dbg("Btp.debug", "set%hhu %lu from %lu %lu\n", n!=NULL?call Neighbor.getAddress(n):0, smallest - now, t1!=0?t1-now:0, t2!=0?t2-now:0);
      //dbg("Btp.debug", "*** new timeout %lu with time %lu\n", smallest, call Timer.getNow());
    }/* else {
        dbg("Btp.debug", "cancel\n");
        }*/

  }

  void clean_neighbor(neighbor_t* ONE n) {
    uint8_t i;

    // check receive done in case next request is received before
    // ack sendDone event arrives
    check_receive_done(n);

    //dbg("Btp.debug", "clean\n");

    if(!call BlockNeighbor.getIsReceived(n) && call BlockNeighbor.getReserved(n)>0) {

      for(i=0; i<call BlockNeighbor.getReserved(n); i++) {
        message_t* m = call BlockNeighbor.getMessage(n, i);
        if(m!=NULL) {
          call ReceivePool.put(m);
        }
        call BlockNeighbor.setMessage(n, i, NULL);
      }

      poolSize += call BlockNeighbor.getReserved(n);
      //dbg("Btp.debug", "clean %hhu vs. %hhu\n",poolSize, call ReceivePool.size());
      //printfflush();

      dbg("Btp.debug,RECEIVE_ABORT", "Abort receive addr %hu, reserved %hhu, received %hhu\n", call Neighbor.getAddress(n), call BlockNeighbor.getReserved(n), call BlockNeighbor.countReceived(n));
    }

    call BlockNeighbor.setReserved(n, 0);

    call BlockNeighbor.clearReceived(n);

    set_timeout(n, 0);

    call BlockNeighbor.setIsReceived(n, FALSE);

    //clear_ack(call Neighbor.getAddress(n));

    //dbg("Btp.debug", "clean %hu, timeout %lu\n", call Neighbor.getAddress(n), call BlockNeighbor.getTimeout(n));
  }

  void clear_ack(am_addr_t addr) {
    uint8_t i;
    bool print = FALSE;//call AckQueue.size()>1;

    if(print) {
      dbg("Btp.trace", "queue (%hhu): ", addr);
      for(i=0; i<call AckQueue.size(); i++) {
        dbg_clear("Btp.trace", "%hhu, ", (call AckQueue.element(i))->addr);
      }
      dbg_clear("Btp.trace", "\n");
    }

    // cancel if current ack
    if(ackDestination==addr) {
      dbg("Btp.debug,RECEIVE_CANCELACK", "Cancel ACK!\n");
      ackCancelled = TRUE;
      if(call AckSend.cancel(&ackMessage)==SUCCESS) {
        //dbg("Btp.debug", "SHOULD CANCEL ACK %hhu\n", call AckQueue.size());
      } else {
        //dbg("Btp.debug", "CANNOT CANCEL ACK %hhu\n", call AckQueue.size());
      }
      //printfflush();
      i = 1;
    } else {
      i = 0;
    }

    {
      uint8_t j;
      uint8_t size = call AckQueue.size();
      block_ack_queue_entry_t* queue[size];
      for(j=0; j<size; j++) {
        queue[j] = call AckQueue.dequeue();
      }

      if(i==1) {
        call AckQueue.enqueue(queue[0]);
      }

      for(j=i; j<size; j++) {
        if(queue[j]->addr!=addr) {
          call AckQueue.enqueue(queue[j]);
        } else {
          dbg("Btp.trace", "rm %hhu %hhu\n",queue[j]->addr, queue[j]->grant);
          call AckPool.put(queue[j]);
        }
      }

      if(print) {
        dbg("Btp.trace", "after (%hhu): ", addr);
        for(i=0; i<call AckQueue.size(); i++) {
          dbg_clear("Btp.trace", "%hhu, ", (call AckQueue.element(i))->addr);
        }
        dbg_clear("Btp.trace", "\n");
      }

    }

    /*      // clear ack from queue
    // TODO: code has not been tested
    #warning "BLOCK RECEIVER CLEAR ACK FROM QUEUE NOT TESTED!"
    for(; i<call AckQueue.size(); i++) {
    block_ack_queue_entry_t* entry = call AckQueue.element(i);
    dbg("Btp.debug", "TESTING\n");
    if(entry->addr==addr) {
    uint8_t j;
    uint8_t size = call AckQueue.size();

    dbg("Btp.debug", DEBUG_RECEIVE_CANCELACK);

    for(j=0; j<size; j++) {

    if(j!=i) {
    call AckQueue.enqueue(call AckQueue.dequeue());
    } else {
    call AckPool.put(call AckQueue.dequeue());
    }

    }

    }
    dbg("Btp.debug", "DONE\n");
    printfflush();
    }*/

  }

  void send_ack(neighbor_t* ONE n/*, uint8_t grant*/) {
    block_ack_queue_entry_t* entry = call AckPool.get();
    if(entry!=NULL) {
      entry->addr = call Neighbor.getAddress(n);
      entry->grant = call BlockNeighbor.getReserved(n);//grant;
      call AckQueue.enqueue(entry);
      dbg("Btp.debug,RECEIVE_ACK_ENQUEUE", "Enqueue ACK addr: %hhu, size: %hhu\n", TOS_NODE_ID, entry->addr, call AckQueue.size());
      if(ackDestination==AM_BROADCAST_ADDR) {
        post sendAckTask();
      }
    } else {
      dbgerror("Btp.error,RECEIVE_ACK_QUEUEFULL", "Ack queue full!\n");
    }

  }

  void send_next_ack() {
    call AckPool.put(call AckQueue.dequeue());
    //dbg("Btp.debug", "send_next_ack %hhu\n", call AckQueue.size());
    if(!call AckQueue.empty()) {
      post sendAckTask();
    }
  }

  void check_receive_done(neighbor_t* ONE n) {
    if(!call BlockNeighbor.getIsReceived(n) && call BlockNeighbor.getReserved(n)>0 && call BlockNeighbor.countReceived(n)==call BlockNeighbor.getReserved(n)) {
      uint8_t i;
      message_t* ONE_NOK msgs[call BlockNeighbor.getReserved(n)];

      for(i=0; i<call BlockNeighbor.getReserved(n); i++) {
        msgs[i] = call BlockNeighbor.getMessage(n, i);
        call BlockNeighbor.setMessage(n, i, NULL);
      }

      call BlockNeighbor.setIsReceived(n, TRUE);
      signal BlockReceive.receive(msgs, call BlockNeighbor.getReserved(n), call Packet.payloadLength(msgs[0]));

      //signal Receive.receive(m, call Packet.getPayload(m, call Packet.payloadLength(m)), call Packet.payloadLength(m));

      dbg("Btp.debug,RECEIVE_ARRIVED", "Arrived addr %hu, reserved %hhu, received %hhu\n", call Neighbor.getAddress(n), call BlockNeighbor.getReserved(n), call BlockNeighbor.countReceived(n));
      //dbg("Btp.debug", "done %hhu for %hhu\n",call BlockNeighbor.countReceived(n),call Neighbor.getAddress(n));

      // clean removed so that a prober response will be sent if
      // sender is pulling for final response. if clean is done these pulling
      // will be ignored as "normal" messages and sender will enter an infinite
      // loop with the new abort timer that resends last packet
      //clean_neighbor(n);
    }

  }

  bool is_last(neighbor_t* ONE n, uint8_t number) {
    uint8_t i;
    for(i=number; i<call BlockNeighbor.getReserved(n); i++) {
      //if( !(call BlockNeighbor.getReceived(n) & (((uint32_t)1) << i)) ) {
      if( !call BlockNeighbor.getReceived(n,i) ) {
        //dbg("Btp.debug", "%hhu %hhu\n", number, (uint8_t)( (call BlockNeighbor.getReceived(n) >> 16) & 0x000000FF) );
        return FALSE;
      }
    }

    //dbg("Btp.debug", "LAST %hhu\n", number);

    return TRUE;

  }

  uint8_t get_number(neighbor_t* n, uint8_t seqno) {
    uint8_t start = call BlockNeighbor.getStartSequenceNumber(n);
    uint8_t max = call BlockNeighbor.getStartSequenceNumber(n) + call BlockNeighbor.getReserved(n);
    uint8_t number = 0;

    if(max > start && seqno>start && seqno<max) {
      number = seqno - start;
    } else if(start > max && seqno<max) {
      number = seqno + (256 - start);
      //dbg("Btp.debug", "2 seqno %hhu, start %hhu, max %hhu, number %hhu\n", seqno, start, max, number);
    } else if(start > max && seqno>start) {
      number = seqno - start;
      //dbg("Btp.debug", "3 seqno %hhu, start %hhu, max %hhu, number %hhu\n", seqno, start, max, number);
    }

    return number;
  }

 }

