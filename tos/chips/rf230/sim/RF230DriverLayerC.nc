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
 * @date   November 20 2010
 */

configuration RF230DriverLayerC {
  
  provides {
    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioCCA;
    interface RadioPacket;
    
    interface PacketField<uint8_t> as PacketTransmitPower;
    interface PacketField<uint8_t> as PacketRSSI;
    interface PacketField<uint8_t> as PacketTimeSyncOffset;
    interface PacketField<uint8_t> as PacketLinkQuality;
    
    interface LocalTime<TRadio> as LocalTimeRadio;
    interface Alarm<TRadio, tradio_size>;

    interface PacketAcknowledgements;
  }
  
  uses {
    interface Ieee154PacketLayer;
    interface PacketTimeStamp<TRadio, uint32_t>;
    //interface PacketFlag as TransmitPowerFlag;
    interface PacketFlag as RSSIFlag;
    interface PacketFlag as TimeSyncFlag;
    interface PacketFlag as AckReceivedFlag;
    //interface RadioAlarm;
  }  
  
} implementation {

  components
    MainC,
    new HplTossimRadioC() as Hpl,
#ifdef RF230_HARDWARE_ACK
    new TossimDriverLayerP(TRUE, TRUE) as Driver,
#else
    new TossimDriverLayerP(FALSE, FALSE) as Driver,
#endif
    CpmModelC as Model;

  MainC.SoftwareInit -> Driver;
  Driver.RSSIFlag = RSSIFlag;
  Driver.TimeSyncFlag = TimeSyncFlag;
  Driver.Ieee154PacketLayer = Ieee154PacketLayer;
  Driver.PacketTimeStamp = PacketTimeStamp;
  Driver.LocalTime -> Hpl;
  Driver.Model -> Model;
  Driver.AckReceivedFlag = AckReceivedFlag;

#ifdef SOFTWAREENERGY
  components 
    new SoftwareEnergyStateC(3000, 15500) as ReceiveEnergyState,
    new SoftwareEnergyStateC(3000, 16500) as TransmitEnergyState;
  Driver.ReceiveEnergyState -> ReceiveEnergyState;
  Driver.TransmitEnergyState -> TransmitEnergyState;
#endif

  RadioState = Driver;
  RadioSend = Driver;
  RadioReceive = Driver;
  RadioCCA = Driver;
  RadioPacket = Driver;

  PacketTransmitPower = Driver.PacketTransmitPower;
  PacketRSSI = Driver.PacketRSSI;
  PacketTimeSyncOffset = Driver.PacketTimeSyncOffset;
  PacketLinkQuality = Driver.PacketLinkQuality;

  LocalTimeRadio = Hpl;
  Alarm = Hpl;

  PacketAcknowledgements = Driver;

}
