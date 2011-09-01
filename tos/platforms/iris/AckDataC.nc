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
 * @date   December 29 2010
 */

generic configuration AckDataC(typedef data_t) {

  provides {
    interface AckData<data_t>;
  }

} implementation {

  enum {
    RF230_OFFSET = uniqueN(UQ_RF230_ACKDATA_BYTES, sizeof(data_t)),
    RF230_MAX_OFFSET = uniqueCount(UQ_RF230_ACKDATA_BYTES),
  };

  /*
#if !defined(RF230_HARDWARE_ACK) && defined(RF230_DATA_ACK)
  components  RF230RadioC as DataAckC;
#else
  components new DummyDataAckLayerC(data_t) as DataAckC;
#endif
  */

#if !defined(RF230_HARDWARE_ACK) && defined(RF230_DATA_ACK)
  components  RF230RadioC;
  components 
    new AckDataP(data_t, RF230_OFFSET, RF230_MAX_OFFSET);
  AckDataP.DataAck -> RF230RadioC;
#else
  components new DummyAckDataP(data_t) as AckDataP;
#endif

  AckData = AckDataP;

}
