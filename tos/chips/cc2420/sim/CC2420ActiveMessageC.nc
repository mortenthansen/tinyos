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
 * @date   February 08 2010
 */

#include "CC2420.h"

configuration CC2420ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;
    //interface LinkPacketMetadata;
    //interface RadioBackoff[am_id_t amId];
    interface LowPowerListening;
    interface PacketLink;
    //interface SendNotifier[am_id_t amId];
    interface RadioInfo;
    interface LplInfo;
  }
} implementation {

  components TossimActiveMessageC as AM;
  components TossimRadioC as Radio;

  components ActiveMessageAddressC as Address;

  components MainC;

#ifdef PACKET_LINK
  components PacketLinkC as LinkC;
#else
  components PacketLinkDummyC as LinkC;
#endif
	
	components UniqueSendC;
  components UniqueReceiveC;

#ifdef LOW_POWER_LISTENING
  components DefaultLplC as LplC;
#else
  components DummyLplC as LplC;
#endif

  components CC2420PacketC;
  components CC2420CsmaC;
  components CC2420TransmitC;

  MainC.SoftwareInit -> CC2420CsmaC;
  CC2420CsmaC.CC2420PacketBody -> CC2420PacketC;
  
  CC2420TransmitC.CC2420PacketBody -> CC2420PacketC;
  CC2420TransmitC.ChannelAccess -> Radio;
  CC2420TransmitC.SubSend -> Radio;
  
  AM.amAddress -> Address;
  
  // Control Layers
  SplitControl = LplC;
  LplC.SubControl -> CC2420CsmaC;
  CC2420CsmaC.SubControl -> Radio;
  
  // Send layers
  AM.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC;
  LplC.SubSend -> CC2420CsmaC;
  CC2420CsmaC.CC2420Transmit -> CC2420TransmitC;
  
  // Receive Layers
  AM.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive -> Radio;
  
  AMSend = AM.AMSend;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  Packet = Radio;
  CC2420Packet = CC2420PacketC;

  PacketAcknowledgements = CC2420PacketC;
  LowPowerListening = LplC;
  PacketLink = LinkC;

  RadioInfo = CC2420CsmaC;
  RadioInfo = LplC;
  LplInfo = LplC;
  
}
