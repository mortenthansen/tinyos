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

configuration LlaReceiverC {

  provides {
    interface BlockReceive;
  }

} implementation {

  components
    LedsC,
    new AMReceiverC(AM_BLOCK_DATA_MSG),
    CC2420PacketC,
    ActiveMessageC,
    BlockPacketC,
    NeighborTableC,
    BlockNeighborC,
    new PoolC(message_t, BLOCK_MAX_BUFFER_SIZE) as ReceivePool,
    LlaReceiverP;

  LlaReceiverP.Leds -> LedsC;

  LlaReceiverP.SubReceive -> AMReceiverC;
  LlaReceiverP.CC2420PacketBody -> CC2420PacketC;
  LlaReceiverP.Packet -> BlockPacketC;
  LlaReceiverP.AMPacket -> ActiveMessageC;
  LlaReceiverP.BlockPacket -> BlockPacketC;

  LlaReceiverP.NeighborTable -> NeighborTableC;
  LlaReceiverP.Neighbor -> NeighborTableC;
  LlaReceiverP.BlockNeighbor -> BlockNeighborC;
  LlaReceiverP.ReceivePool -> ReceivePool;

  BlockReceive = LlaReceiverP;

}
