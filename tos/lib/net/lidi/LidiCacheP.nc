/*
 * Copyright (c) 2011 Aarhus University
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
 * @date   October 20 2011
 */

generic module LidiCacheP(typedef data_t, uint16_t key) {
  
  provides { 
    interface DisseminationValue<data_t>;
    interface DisseminationUpdate<data_t>;
    interface LidiCache;
  }

} implementation {

  data_t data;

  // A sequence number is 32 bits. The top 16 bits are an incrementing
  // counter, while the bottom 16 bits are a unique node identifier.
  uint32_t seqno = LIDI_SEQNO_UNKNOWN;

  /***************** DisseminationValue ****************/
  
  command const data_t* DisseminationValue.get() {
    return &data;
  }

  command void DisseminationValue.set(const data_t* val) {
    if (seqno == LIDI_SEQNO_UNKNOWN) {
      data = *val;
    }
  }

  /***************** DisseminationUpdate ****************/

  command void DisseminationUpdate.change(data_t* newVal) {
    memcpy( &data, newVal, sizeof(data_t) );
    /* Increment the counter and append the local node ID. */
    seqno = seqno >> 16;
    seqno++;
    if ( seqno == LIDI_SEQNO_UNKNOWN ) { 
      seqno++; 
    }
    seqno = seqno << 16;
    seqno += TOS_NODE_ID;
    signal LidiCache.newData();
    signal DisseminationValue.changed();
  }

  /***************** LidiCache ****************/

  command void* LidiCache.getData() {
    return &data;
  }

  command uint8_t LidiCache.getDataLength() {
    return sizeof(data_t);
  }

  command uint16_t LidiCache.getKey() {
    return key;
  }

  command uint32_t LidiCache.getSequenceNumber() {
    return seqno;
  }

  command void LidiCache.putData(void* newData, uint8_t length, uint32_t newSeqno) {
    memcpy( &data, newData, length < sizeof(data_t) ? length : sizeof(data_t) );
    seqno = newSeqno;
    // We need to signal here and can't go through a task to
    // ensure that the update and changed event are atomic.
    // Otherwise, it is possible that storeData is called,
    // but before the task runs, the client calls set(). -pal
    signal DisseminationValue.changed();
  }

  default event void DisseminationValue.changed() { }

}
