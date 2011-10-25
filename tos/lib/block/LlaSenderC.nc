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

configuration LlaSenderC {

  provides {
    interface BlockSend;
  }

} implementation {

  components
    MainC,
    ActiveMessageC,
    BlockPacketC,
    CC2420ActiveMessageC,
    CC2420PacketC,
    new AMSenderC(AM_BLOCK_DATA_MSG),
    LlaSenderP;

  MainC.SoftwareInit -> LlaSenderP;

  LlaSenderP.Packet -> BlockPacketC;
  LlaSenderP.CC2420PacketBody -> CC2420PacketC;
  LlaSenderP.AMPacket -> ActiveMessageC;
  LlaSenderP.BlockPacket -> BlockPacketC;
  LlaSenderP.SubSend -> AMSenderC;
  LlaSenderP.Acks -> ActiveMessageC;
#ifndef TOSSIM
  LlaSenderP.RadioBackoff -> CC2420ActiveMessageC.RadioBackoff[AM_BLOCK_DATA_MSG];
#endif
  LlaSenderP.PacketLink -> CC2420ActiveMessageC;

  components
    new TimeMeasureMicroC() as BlockTime,
    new TimeMeasureMicroC() as PacketTime;
  LlaSenderP.BlockTime -> BlockTime;
  LlaSenderP.PacketTime -> PacketTime;

  BlockSend = LlaSenderP;

}
