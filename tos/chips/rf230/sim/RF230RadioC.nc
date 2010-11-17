/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

#include <RadioConfig.h>
#include "RF230Radio.h"

configuration RF230RadioC
{
	provides 
	{
		interface SplitControl;

#ifndef IEEE154FRAMES_ENABLED
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface SendNotifier[am_id_t id];

		// for TOSThreads
		interface Receive as ReceiveDefault[am_id_t id];
		interface Receive as SnoopDefault[am_id_t id];

		interface AMPacket;
		interface Packet as PacketForActiveMessage;
#endif

#ifndef TFRAMES_ENABLED
		interface Ieee154Send;
		interface Receive as Ieee154Receive;
		interface SendNotifier as Ieee154Notifier;

		interface Resource as SendResource[uint8_t clint];

		interface Ieee154Packet;
		interface Packet as PacketForIeee154Message;
#endif

		interface PacketAcknowledgements;
		interface LowPowerListening;

#ifdef PACKET_LINK
		interface PacketLink;
#endif
#ifdef TRAFFIC_MONITOR
		interface TrafficMonitor;
#endif

		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation 
{

  components TossimRadioC as RadioC;
  
  SplitControl = RadioC;

#ifndef IEEE154FRAMES_ENABLED  
  AMSend = RadioC;
  Receive = RadioC.Receive;
  Snoop = RadioC.Snoop;
  SendNotifier = RadioC.SendNotifier;
  
  ReceiveDefault = RadioC.ReceiveDefault;
  SnoopDefault = RadioC.SnoopDefault;
  
  AMPacket = RadioC;
  PacketForActiveMessage = RadioC.PacketForActiveMessage;
#endif 

#ifndef TFRAMES_ENABLED
  Ieee154Send = RadioC;
  Ieee154Receive = RadioC;
  Ieee154Notifier = RadioC.Ieee154Notifier;
  
  SendResource = RadioC.SendResource;

  Ieee154Packet = RadioC;
  PacketForIeee154Message = RadioC.PacketForIeee154Message;
#endif

  PacketAcknowledgements = RadioC;
  LowPowerListening = RadioC;

#ifdef PACKET_LINK
  PacketLink = RadioC;
#endif

#ifdef TRAFFIC_MONITOR
  TrafficMonitor = RadioC;
#endif

  RadioChannel = RadioC;
  PacketLinkQuality = RadioC.PacketLinkQuality;
  PacketTransmitPower = RadioC.PacketTransmitPower;
  PacketRSSI = RadioC.PacketRSSI;

  LocalTimeRadio = RadioC;
  PacketTimeStampRadio = RadioC.PacketTimeStampRadio;
  PacketTimeStampMilli = RadioC.PacketTimeStampMilli;

}
