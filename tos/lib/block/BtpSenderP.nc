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

module BtpSenderP @safe() {

  provides {
    interface Init;
    interface BlockSend;
  }

  uses {
    interface Random;

    interface Packet;
    interface AMPacket;
    interface BlockPacket;

    interface AMSend as SubSend;
    interface Packet as SubPacket;
    interface PacketAcknowledgements as Acks;
#ifndef TOSSIM
    interface RadioBackoff;
#endif
    interface CC2420PacketBody;
    interface PacketLink;

    //      interface Queue<message_t*> as SendQueue;
    interface Timer<TMilli> as AbortTimer;
    interface BitVector as Received;

    interface Receive as AckReceive;

    interface TimeMeasure<uint32_t> as BlockTime;
    interface TimeMeasure<uint32_t> as PacketTime;
  }

} implementation {

  uint8_t seqno;
  uint8_t current;
  uint8_t granted;
  bool first;
  bool reliable;

  //uint32_t received;
  bool sending;
  bool ackReceived;

  message_t** ONE_NOK messages;
  uint8_t size;
  uint8_t length;

  void signal_done(error_t error);
  uint8_t next_to_send(uint8_t c);
  bool is_last_to_send(uint8_t c);
  inline void request_ack(message_t* ONE msg);
  inline void no_ack(message_t* ONE msg);

  uint8_t count_received();
  void all_sent();

  //bool test = FALSE;

  /***************** Init ****************/

  command error_t Init.init() {
    seqno = 0;
    current = 0;
    granted = 0;
    reliable = TRUE;
    first = FALSE;
    sending = FALSE;
    ackReceived = FALSE;
    messages = NULL;
    size = 0;
    length = 0;
    atomic call Received.clearAll();
    return SUCCESS;
  }

  /***************** BlockSend ****************/

  task void sendTask() {
    error_t error;

    if(messages==NULL) {
      dbgerror("Btp.error", "sendTask messages==NULL\n");
      return;
    }

    // happens sometimes when ACK response comes before sendDone event
    // or maybe if abort timer fires before sendDone?
    // and now also if a second ack is received as we dont discard them if abort
    // timer is not running
    if(sending) {
      //dbg("Btp.debug", "sendTask already sending, ackReceived=%hhu\n", ackReceived);
      // ackReceived will be set to TRUE, so sendTask is posted again
      // whenever sendDone event fires.
      return;
    }

    call PacketTime.start();

    if(granted==0) {
      call BlockPacket.setRequest(messages[0], size);

      request_ack(messages[0]);

      //dbg("Btp.debug", "%hhu: first %hhu\n",TOS_NODE_ID, call BlockPacket.getSequenceNumber(messages[0]));

      error = call SubSend.send(call AMPacket.destination(messages[0]), messages[0], length);
      if(error!=SUCCESS) {
        dbg("Btp.debug,SUBSEND_FAIL", "Failed sending first %hhu\n", error);
        signal_done(error);
      } else {
        sending = TRUE;
        ackReceived = FALSE;
        //dbg("Btp.debug", "%i sending first, r: %hhu, s: %hhu\n", TOS_NODE_ID, call BlockPacket.getRequest(messages[0]), call BlockPacket.getSequenceNumber(messages[0]));
      }

    } else {
      //dbg("Btp.debug", "%i send grant:%hhu, request:%hhu, seqno:%hhu\n", TOS_NODE_ID, granted, call BlockPacket.getRequest(messages[current]), call BlockPacket.getSequenceNumber(messages[current]));
      //dbg("Btp.debug", "send %hhu\n", call BlockPacket.getSequenceNumber(messages[current]));

      if(is_last_to_send(current)) {
        //dbg("Btp.debug", "last seqno %hhu\n", call BlockPacket.getSequenceNumber(messages[current]));
        request_ack(messages[current]);
        time_start();
      } else {
        //dbg("Btp.debug", "next seqno %hhu\n", call BlockPacket.getSequenceNumber(messages[current]));
        no_ack(messages[current]);
      }

      error = call SubSend.send(call AMPacket.destination(messages[current]), messages[current], length);
      if(error!=SUCCESS) {
        dbg("Btp.debug,DEBUG_SUBSEND_FAIL", "Failed sending current error=%hhu, sending=%hhu\n", error, sending);
        signal_done(error);
      } else {
        sending = TRUE;
        ackReceived = FALSE;
      }

    }

  }

  command error_t BlockSend.send(am_addr_t addr, message_t** msgs, uint8_t s, uint8_t len) {
    uint8_t i;

    if(addr==AM_BROADCAST_ADDR || s==0) {
      dbg("Btp.debug,SEND_EINVAL", "Cannot broadcast block or send block with size 0\n");
      return EINVAL;
    }

    if(s>call BlockSend.maxBufferSize() || len>call BlockSend.maxPayloadLength()) {
      dbgerror("Btp.error,SEND_ESIZE", "Exceeding max block size %hhu>%hhu or max payload length %hhu>%hhu\n", s, call BlockSend.maxBufferSize(), len, call BlockSend.maxPayloadLength());
      return ESIZE;
    }

    // messages can be null while still sending if final ack is received before sendDone
    // event.  without this check BTP will enter a deadlock if next send is called after
    // the ack is received but before the pending sendDone event happen.
    if(messages==NULL) {
      current = 0;
      granted = 0;

      messages = msgs;
      size = s;
      length = len + sizeof(block_header_t);
      atomic call Received.clearAll();

      for(i=0; i<size; i++) {
        call BlockPacket.setRequest(messages[i], 0);
        call BlockPacket.setSequenceNumber(messages[i], seqno++);
        call AMPacket.setDestination(messages[i], addr);
      }

      //test = TRUE;

      //dbg("Btp.debug", "%i send, size %hhu, len %hhu, seqno:%hhu-%hhu\n", TOS_NODE_ID, size, length, call BlockPacket.getSequenceNumber(messages[0]), call BlockPacket.getSequenceNumber(messages[size-1]));

      dbg("Btp.debug,SEND_INIT", "Init block send seqno %hhu to %hhu\n", call BlockPacket.getSequenceNumber(messages[0]), call BlockPacket.getSequenceNumber(messages[size-1]));
      call BlockTime.start();

      post sendTask();

      return SUCCESS;
    } else {
      dbg("Btp.debug,SEND_BUSY", "Send is busy!\n");
      return EBUSY;
    }

  }

  command error_t BlockSend.cancel(message_t* msg) {
    return FAIL;
  }

  command uint8_t BlockSend.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command uint8_t BlockSend.maxBufferSize() {
    return BLOCK_MAX_BUFFER_SIZE;
  }

  command void* BlockSend.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  /***************** SubSend ****************/

  event void SubSend.sendDone(message_t* msg, error_t error) {
    //bool s = sending;
    uint16_t t;

    time_stop();

    sending = FALSE;

    call PacketTime.stop();

    t = call PacketTime.get();

    if(ackReceived) {

      dbg("Btp.debug,SENDDONE_FASTACK", "Fastack, no wait on %hhu\n", call BlockPacket.getSequenceNumber(msg));

      // if still messages to send, send next
      if(current<granted) {
        atomic first = TRUE;
        post sendTask();
        // else signal all done now cause ack has been received
      } else {
        all_sent();
      }

    } else if (messages==NULL) {
      dbgerror("Btp.error,SENDDONE_IGNORE", "SubSend.sendDone but messages==NULL\n");

    } else if(error!=SUCCESS) {

      dbgerror("Btp.error,SENDDONE_FAIL", "sendDone fail\n");
      signal_done(error);

    } else if(granted==0 || is_last_to_send(current)) {

      atomic first = FALSE;

      if(call Acks.wasAcked(msg)) {
        //dbg("Btp.debug", "%i **** wait r:%hhu, s:%hhu, rtx:%hu\n", TOS_NODE_ID, call BlockPacket.getRequest(messages[current]), call BlockPacket.getSequenceNumber(messages[current]), call PacketLink.getRetries(msg));
        //printfflush();

        /*if(is_last_to_send(current) && test) {
          post sendTask();
          test = FALSE;
          }*/

        //dbg("Btp.debug", "sent %lu\n", call PacketTime.get());

        call AbortTimer.startOneShot(BLOCK_RESPONSE_TIME);

        if(granted==0) {
          dbg("Btp.debug,SENDDONE_FIRST_ACK", "First packet acked time %lu, seqno %hhu\n", t, call BlockPacket.getSequenceNumber(messages[current]));
        } else {
          dbg("Btp.debug,SENDDONE_LAST_ACK", "Last packet acked time %lu, seqno %hhu\n", t, call BlockPacket.getSequenceNumber(messages[current]));
        }

      } else {

        //dbg("Btp.debug", "%i dont expect resp r: %hhu, s: %hhu\n", TOS_NODE_ID, call BlockPacket.getRequest(messages[current]), call BlockPacket.getSequenceNumber(messages[current]));

        if(granted==0) {
          dbg("Btp.debug,SENDDONE_FIRST_NOACK", "First packet NOT acked time %lu, seqno %hhu\n", t, call BlockPacket.getSequenceNumber(messages[current]));
        } else {
          dbg("Btp.debug,SENDDONE_LAST_NOACK", "Last packet NOT acked time %lu, seqno %hhu\n", t, call BlockPacket.getSequenceNumber(messages[current]));
        }

        signal_done(ENOACK);
      }

    } else {

      dbg("Btp.debug,SENDDONE_NEXT", "sendDone, sending next.. time %lu, wasAcked %hhu\n", t, call Acks.wasAcked(msg));

      current = next_to_send(current);

      atomic first = FALSE;

      post sendTask();

    }
  }

  /***************** AckReceive ****************/

  event message_t* AckReceive.receive(message_t* msg, void* payload, uint8_t len) {
    block_ack_t* ack = (block_ack_t*) payload;

    // aborttimer condition removed due to later acks now being allowed to change grant.
    if(!sending && (messages==NULL/* || !call AbortTimer.isRunning()*/)) {
      dbg("Btp.debug,SEND_UNEXPECTEDACK", "Unexpected ACK, ignoring.. sending: %hhu, messages?: %hhu, running: %hhu\n", sending, messages!=NULL, call AbortTimer.isRunning());
      return msg;
    }

    /*dbg("Btp.debug", "%i: ", TOS_NODE_ID);
      {
      uint8_t i;
      atomic call Received.clearAll();
      for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
      dbg("Btp.debug", "%hhu",((ack->received[i/8]>>(i%8)) & 1));
      }
      }
      dbg("Btp.debug", "\n");*/

    if(call AMPacket.destination(messages[0])!=call AMPacket.source(msg) || call BlockPacket.getSequenceNumber(messages[0])!=ack->start) {
      dbg("Btp.debug,SEND_BADACK", "Bad ack received src: %hhu, mystart:%hhu, ackstart:%hhu\n", call AMPacket.source(msg), call BlockPacket.getSequenceNumber(messages[0]), ack->start);
      return msg;
    }

    call AbortTimer.stop();

    if(granted==0 && ack->grant==0) {
      call BlockTime.stop();
      dbg("Btp.debug,SEND_ENOMEM", "Receiver out of buffer space, time %lu, size %hhu\n", call BlockTime.get(), size);
      signal_done(ENOMEM);
      return msg;
    } else if(granted!=ack->grant) {
      //dbg("Btp.debug", "got %hhu granted\n", ack->grant);
      granted = ack->grant>size? size : ack->grant;
    }

    dbg("Btp.debug,SEND_ACKRECEIVED", "Recieved ACK with grant %hhu and start %hhu\n", ack->grant, ack->start);

    //received = ack->received;
    {
      uint8_t i;
      atomic call Received.clearAll();
      for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
        atomic call Received.assign(i, ((ack->received[i/8]>>(i%8)) & 1));
      }
    }

    //dbg("Btp.debug", "ack %hhu with received %hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu%hhu\n", (call CC2420PacketBody.getHeader(msg))->dsn, call Received.get(0),call Received.get(1),call Received.get(2),call Received.get(3),call Received.get(4),call Received.get(5),call Received.get(6),call Received.get(7),call Received.get(8),call Received.get(9),call Received.get(10));

    current = 0;
    current = next_to_send(current);

    if(sending) {
      dbg("Btp.debug,SEND_CANCELSEND", "Cancel send due to received ack.\n");
      ackReceived = TRUE;
      call SubSend.cancel(messages[current]);

    } else {

      if(current<granted) {
        atomic first = TRUE;
        //atomic cca = TRUE;
        post sendTask();

      } else {

        /*// if we are still sending all_sent will be called from the sendDone event to come.
          if(!sending) {*/
        all_sent();
        //}
      }
    }

    return msg;
  }

  /***************** AbortTimer ****************/

  event void AbortTimer.fired() {
    post sendTask();
    dbg("Btp.debug,SEND_ABORT", "Abort timer fired after %hhu, sending: %hhu\n", BLOCK_RESPONSE_TIME, sending);
    //signal_done(FAIL);
  }

  /***************** RadioBackoff ****************/

#ifndef TOSSIM
  async event void RadioBackoff.requestInitialBackoff(message_t * msg) {

#ifdef NO_INITIAL_BACKOFF
    dbg("Btp.trace", "NO INITIAL\n");
    call RadioBackoff.setInitialBackoff(0);
#elif NO_NORMAL_INITIAL_BACKOFF
    if(reliable /*|| first*/) {
      dbg("Btp.trace", "INITIAL BACKOFF %hhu\n",first);
      //call RadioBackoff.setInitialBackoff ( call Random.rand16() % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
    } else {
      dbg("Btp.trace", "NO INITIAL\n");
      call RadioBackoff.setInitialBackoff(0);
    }
#else
    //call RadioBackoff.setInitialBackoff ( call Random.rand16() % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
    dbg("Btp.trace", "INITIAL BACKOFF\n");
#endif

  }

  async event void RadioBackoff.requestCongestionBackoff(message_t * msg) {

  }

  async event void RadioBackoff.requestCca(message_t * ONE msg) {
#ifdef NO_BACKOFF
    call RadioBackoff.setCca(FALSE);
    dbg("Btp.trace", "NO BACKOFF\n");
#elif NO_NORMAL_BACKOFF
    if(reliable /*|| first*/) {
      dbg("Btp.trace", "BACKOFF %hhu\n", first);
    } else {
      call RadioBackoff.setCca(FALSE);
      dbg("Btp.trace", "NO BACKOFF\n");
    }
#else
    dbg("Btp.trace", "BACKOFF\n");
#endif
  }
#endif

  /***************** Functions ****************/

  void signal_done(error_t error) {
    uint8_t i;
    message_t** temp;

    // set acked status
    for(i=0; i<size; i++) {
      //if(((received>>i) & 1)) {
      bool b;
      atomic b = call Received.get(i);
      if(b) {
        //#ifndef TOSSIM
        (call CC2420PacketBody.getMetadata(messages[i]))->ack = TRUE;
        /*#else
          ((tossim_metadata_t* ONE)(messages[i]->metadata))->ack = TRUE;
          #endif*/
      } else {
        //#ifndef TOSSIM
        (call CC2420PacketBody.getMetadata(messages[i]))->ack = FALSE;
        /*#else
          ((tossim_metadata_t* ONE)(messages[i]->metadata))->ack = FALSE;
          #endif*/
      }

    }

    // cancel abort timer if running
    call AbortTimer.stop();

    // reset messages
    temp = messages;
    messages = NULL;

    //dbg("Btp.debug", "%i %s: signal done\n", TOS_NODE_ID, __FUNCTION__);
    signal BlockSend.sendDone(temp, size, error);
  }

  uint8_t next_to_send(uint8_t c) {
    bool b;

    while(c<granted) {
      c++;
      //if(!(received & (((uint32_t)1) << c))) {
      atomic b = !call Received.get(c);
      if(b) {
        break;
      }
    }

    return c;

  }

  bool is_last_to_send(uint8_t c) {
    return next_to_send(c)==granted;
  }

  inline void request_ack(message_t* ONE msg) {

    //#if !defined(TOSSIM) || defined(TOSSIM_PACKETLINK)
    call PacketLink.setRetries(msg, BLOCK_MAX_RETRANSMISSIONS);
#ifdef BLOCK_RANDOM_RETRY_DELAY
    call PacketLink.setRetryDelay(msg, call Random.rand16() % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
#else
    call PacketLink.setRetryDelay(msg, BLOCK_DELAY_RETRANSMISSIONS);
#endif

    atomic reliable = TRUE;
    //call Acks.requestAck(msg);
    /*#else

      #endif*/
  }

  inline void no_ack(message_t* ONE msg) {
    //#if !defined(TOSSIM) || defined(TOSSIM_PACKETLINK)
    call PacketLink.setRetries(msg, 0);
    call PacketLink.setRetryDelay(msg, 0);

    atomic reliable = FALSE;
    //#endif
    // TODO: noAck needs to be called even though setRetries is set to
    // zero as packet link layer does not set this by itself.
    // (email sent to tinyos-devel 2 Feb 2009 reporting this issue)
    call Acks.noAck(msg);
  }


  uint8_t count_received() {
    uint8_t count = 0;
    uint8_t i;
    bool b;
    for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
      atomic b = call Received.get(i);
      if(b) {
        count++;
      }
    }
    return count;
  }

  void all_sent() {
    call BlockTime.stop();
    //dbg("Btp.debug", "all done\n");

    if(granted<size) {

      dbg("Btp.debug,SEND_SOMESENT", "Some of all sent, time %lu, size %hhu, granted %hhu\n", call BlockTime.get(), size, granted);
      signal_done(ENOMEM);

    } else {
      dbg("Btp.debug,SEND_ALLSENT", "All sent, time %lu, size %hhu, granted %hhu\n", call BlockTime.get(), size, granted);
      signal_done(SUCCESS);

    }
  }

}
