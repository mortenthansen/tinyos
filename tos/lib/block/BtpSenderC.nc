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

#include "Block.h"

configuration BtpSenderC {

  provides {
    interface BlockSend;
  }

} implementation {

  /*
    #ifndef PLATFORM_TELOSB
    #error "Platform not supported!"
    #endif
  */

  components
    MainC,
    RandomC,
    ActiveMessageC,
    CC2420PacketC,
    CC2420ActiveMessageC,
    new AMSenderC(AM_BLOCK_DATA_MSG),
    new AMReceiverC(AM_BLOCK_ACK_MSG),
    //      new QueueC(message_t*, BLOCK_MAX_BUFFER_SIZE) as SendQueue,
    new TimerMilliC(),
    new BitVectorC(BLOCK_MAX_BUFFER_SIZE) as Received,
    BlockPacketC,
    BtpSenderP;

  MainC.SoftwareInit -> BtpSenderP;

  BtpSenderP.Random -> RandomC;
  BtpSenderP.Packet -> BlockPacketC;
  BtpSenderP.AMPacket -> ActiveMessageC;
  BtpSenderP.BlockPacket -> BlockPacketC;
  BtpSenderP.SubSend -> AMSenderC;
  BtpSenderP.Acks -> ActiveMessageC;
#ifndef TOSSIM
  BtpSenderP.RadioBackoff -> CC2420ActiveMessageC.RadioBackoff[AM_BLOCK_DATA_MSG];
#endif
  BtpSenderP.CC2420PacketBody -> CC2420PacketC;
  BtpSenderP.PacketLink -> CC2420ActiveMessageC;

  //BtpSenderP.SendQueue -> SendQueue;
  BtpSenderP.AbortTimer -> TimerMilliC;
  BtpSenderP.Received -> Received;

  BtpSenderP.AckReceive -> AMReceiverC;

  components
    new TimeMeasureMicroC() as BlockTime,
    new TimeMeasureMicroC() as PacketTime;
  BtpSenderP.BlockTime -> BlockTime;
  BtpSenderP.PacketTime -> PacketTime;

  BtpSenderP.SubPacket -> ActiveMessageC;
  BlockSend = BtpSenderP;

}
