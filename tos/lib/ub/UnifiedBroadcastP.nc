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
 * @date   May 18 2010
 */

#include "UnifiedBroadcast.h"

configuration UnifiedBroadcastP @safe() {

  provides {
    interface Send[uint8_t client];
    interface Receive[am_id_t id];
    interface UnifiedBroadcast[uint8_t client];
  }

} implementation {

  enum {
    NUM_CLIENTS = uniqueCount(UQ_AMQUEUE_SEND)
  };

  components
    ActiveMessageC,
    AMQueueP;

#ifdef UNIFIED_BROADCAST

#warning "*** UNIFIED BROADCAST IS ENABLED ***"

  components
    new UnifiedBroadcastImplP(NUM_CLIENTS) as UB,
    MainC,
    new AMSenderC(AM_UNIFIEDBROADCAST_MSG),
    new BitVectorC(NUM_CLIENTS) as PendingVector,
    new BitVectorC(NUM_CLIENTS) as SendingVector,
    new BitVectorC(NUM_CLIENTS) as UrgentVector,
    LocalTimeMilliC;

  MainC.SoftwareInit -> UB;
  UB.RadioControl -> ActiveMessageC;
  UB.PendingVector -> PendingVector;
  UB.SendingVector -> SendingVector;
  UB.UrgentVector -> UrgentVector;
  UB.BroadcastSend -> AMSenderC;
  UB.Packet -> ActiveMessageC;
  UB.LocalTime -> LocalTimeMilliC;

#ifndef UB_NO_TIMESTAMP
  components CC2420PacketC;
  UB.PacketTimeSyncOffset -> CC2420PacketC;
#endif

#else

#warning "*** UNIFIED BROADCAST IS NOT USED ***"

  components
    new DummyUnifiedBroadcastImplP() as UB,
    LocalTimeMilliC;;
  UB.LocalTime -> LocalTimeMilliC;

#endif

  UB.AMPacket -> ActiveMessageC;
  UB.SubSend -> AMQueueP.Send;
  UB.SubReceive -> ActiveMessageC.Receive;

  UB.Send = Send;
  UB.Receive = Receive;
  UB.UnifiedBroadcast = UnifiedBroadcast;

}
