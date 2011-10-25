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

module LlaSenderP {

  provides {
    interface Init;
    interface BlockSend;
  }

  uses {
    interface Packet;
    interface AMPacket;
    interface BlockPacket;
    interface CC2420PacketBody;

    interface AMSend as SubSend;
#ifndef TOSSIM
    interface RadioBackoff;
#endif
    interface PacketLink;
    interface PacketAcknowledgements as Acks;

    interface TimeMeasure<uint32_t> as BlockTime;
    interface TimeMeasure<uint32_t> as PacketTime;
  }

} implementation {

  message_t** ONE_NOK messages;
  uint8_t size;
  uint8_t length;
  uint8_t lastSeqno;
  uint8_t current;
  uint8_t sent;
  error_t result;
  //bool initialBackoff;

  task void sendTask();
  void signal_done(error_t error);

  /***************** Init ****************/

  command error_t Init.init() {
    messages = NULL;
    size = 0;
    length = 0;
    lastSeqno = 0xFF;
    current = BLOCK_MAX_BUFFER_SIZE;
    sent = 0;
    result = SUCCESS;
    //initialBackoff = TRUE;
    return SUCCESS;
  }

  /********** Send **********/

  command error_t BlockSend.send(am_addr_t addr, message_t** msgs, uint8_t s, uint8_t len) {
    uint8_t i;

    if(addr==AM_BROADCAST_ADDR || s==0) {
      dbgerror("Lla.error,SEND_EINVAL", "Cannot broadcast block or send block with size 0\n");
      return EINVAL;
    }

    if(s>call BlockSend.maxBufferSize() || len>call BlockSend.maxPayloadLength()) {
      dbgerror("Lla.error,SEND_ESIZE", "Exceeding max block size %hhu>%hhu or max payload length %hhu>%hhu\n", s, call BlockSend.maxBufferSize(), len, call BlockSend.maxPayloadLength());
      return ESIZE;
    }

    if(messages==NULL) {
      current = 0;
      sent = 0;
      messages = msgs;
      size = s;
      length = len;
      result = SUCCESS;
      //atomic initialBackoff = TRUE;

      for(i=0; i<size; i++) {
        call BlockPacket.setRequest(messages[i], size);
        call BlockPacket.setSequenceNumber(messages[i], lastSeqno+1);
        call AMPacket.setDestination(messages[i], addr);
      }

      dbg("Lla.debug,SEND_INIT", "Init block send\n");
      call BlockTime.start();

      post sendTask();

      return SUCCESS;
    } else {
      dbg("Lla.debug,SEND_BUSY", "Send is busy!\n");
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

  event void SubSend.sendDone(message_t* msg, error_t error) {

    lastSeqno = (call CC2420PacketBody.getHeader(msg))->dsn;

    call PacketTime.stop();

    if(error!=SUCCESS) {
      dbg("Lla.debug,SENDDONE_FAIL", "Failed to send!\n");
      signal_done(error);
      return;
    }

    current++;

    if(call PacketLink.wasDelivered(msg)) {
      dbg("Lla.debug,SENDDONE_AM_ACK", "Packet acknowledged, time %lu\n", call PacketTime.get());
      sent++;
    } else {
      result = ENOACK;
      dbg("Lla.debug,SENDDONE_AM_NOACK", "Packet NOT acknowledged, time %lu\n", call PacketTime.get());
    }

    if(current>=size) {

      call BlockTime.stop();

      if(result==SUCCESS) {
        dbg("Lla.debug,SEND_ALLSENT", "Block sent with time %lu, size %hhu, sent %hhu\n", call BlockTime.get(), size, sent);
      } else {
        dbg("Lla.debug,SEND_SOMESENT", "Some of block sent with time %lu, size %hhu, sent %hhu\n", call BlockTime.get(), size, sent);
      }

      signal_done(result);

    } else {
      post sendTask();
    }
  }

  /***************** RadioBackoff ****************/

#ifndef TOSSIM
  async event void RadioBackoff.requestInitialBackoff(message_t * msg) {
#if defined(NO_INITIAL_BACKOFF) || defined(NO_NORMAL_INITIAL_BACKOFF)
    dbg("Lla.trace", "NO INITIAL\n");
    call RadioBackoff.setInitialBackoff(0);
#else
    dbg("Lla.trace", "INITIAL BACKOFF\n");
#endif
  }

  async event void RadioBackoff.requestCongestionBackoff(message_t * msg) {

  }

  async event void RadioBackoff.requestCca(message_t * ONE msg) {
#if defined(NO_BACKOFF) || defined(NO_NORMAL_BACKOFF)
    dbg("Lla.trace", "NO BACKOFF\n");
    call RadioBackoff.setCca(FALSE);
#else
    dbg("Lla.trace", "BACKOFF\n");
#endif
  }
#endif

  /********** Tasks **********/

  task void sendTask() {
    if(current>=size) {
      dbgerror("Lla.error", "NOOOO. Cannot send current %hhu higher than size %hhu\n", current, size);
      return;
    }

    call PacketTime.start();

    call PacketLink.setRetries(messages[current], BLOCK_MAX_RETRANSMISSIONS);
    call PacketLink.setRetryDelay(messages[current], BLOCK_DELAY_RETRANSMISSIONS);

    if(call SubSend.send(call AMPacket.destination(messages[current]), messages[current], length)!=SUCCESS) {
      dbg("Lla.debug,SUBSEND_FAIL", "Subsend failed, cannot send\n");
      signal_done(FAIL);
    }
  }

  /********** Functions **********/

  void signal_done(error_t error) {
    message_t** tempMsg;
    uint8_t tempSize;

    current = BLOCK_MAX_BUFFER_SIZE;

    // reset message
    tempMsg = messages;
    messages = NULL;

    // reset size
    tempSize = size;
    size = 0;

    signal BlockSend.sendDone(tempMsg, tempSize, error);
  }

  }
