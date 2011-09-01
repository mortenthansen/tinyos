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

#include <TimeSyncMessageLayer.h>

generic module TossimDriverLayerP(bool tossimHardwareAddressMatch, bool tossimHardwareAck) {

  provides {
    interface Init;

    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioCCA;
    interface RadioPacket;
    
    interface PacketField<uint8_t> as PacketTransmitPower;
    interface PacketField<uint8_t> as PacketRSSI;
    interface PacketField<uint8_t> as PacketTimeSyncOffset;
    interface PacketField<uint8_t> as PacketLinkQuality;

    interface PacketAcknowledgements;

  }

  uses {

    interface PacketFlag as AckReceivedFlag;
    interface PacketFlag as RSSIFlag;
    interface PacketFlag as TimeSyncFlag;

    interface Ieee154PacketLayer;

    interface PacketTimeStamp<TRadio, uint32_t>;
    interface LocalTime<TRadio>;

    interface GainRadioModel as Model;

#ifdef SOFTWAREENERGY
    interface SoftwareEnergyState as ReceiveEnergyState;
    interface SoftwareEnergyState as TransmitEnergyState;
#endif
  }

} implementation {

  bool running;

  bool transmitting = FALSE;
  message_t* sending;
  sim_event_t sendEvent;

  message_t buffer;
  message_t* bufferPointer = &buffer;
  
  tossim_header_t* getHeader(message_t* amsg) {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }
  
  tossim_metadata_t* getMetadata(message_t* amsg) {
    return (tossim_metadata_t*)(&amsg->metadata);
  }

  void dbg_message(message_t* msg) {
    uint8_t i;
    dbg("Driver.trace", " - message (rssi: %hhu, ack: %hhu):", call RSSIFlag.get(msg), tossimHardwareAck && call AckReceivedFlag.get(msg));
    for(i=0; i<sizeof(message_t); i++) {
      dbg_clear("Driver.trace", " %hhu", *((uint8_t*)msg + i));
    }
    dbg_clear("Driver.trace", "\n");
  }

  /***************** Init ****************/

  command error_t Init.init() {
    running = FALSE;
    return SUCCESS;
  }


  /***************** RadioState ****************/

  task void stateDoneTask() {
    signal RadioState.done();
  }

  tasklet_async command error_t RadioState.turnOff() {

    if(!running) {
      dbgerror("Driver.error", "Driver: already OFF\n");
      return EALREADY;
    } else {
#ifdef SOFTWAREENERGY
      if(!transmitting) {
        call ReceiveEnergyState.off();
      }
#endif
      running = FALSE;
      dbg("Driver.debug", "Driver: turning radio OFF @ %lu\n", (call LocalTime.get()*1000UL)/(1024UL*1024UL));
      post stateDoneTask();
      return SUCCESS;
    }

  }

  tasklet_async command error_t RadioState.standby() {
    return call RadioState.turnOff();
  }

  tasklet_async command error_t RadioState.turnOn() {

    if(running) {
      dbgerror("Driver.error", "Driver: already ON\n");
      return EALREADY;
    } else {
#ifdef SOFTWAREENERGY
      call ReceiveEnergyState.on();
#endif
      running = TRUE;
      dbg("Driver.debug", "Driver: turning radio ON @ %lu\n", (call LocalTime.get()*1000UL)/(1024UL*1024UL));
      post stateDoneTask();
      return SUCCESS;
    }

  }

  tasklet_async command error_t RadioState.setChannel(uint8_t channel) {
    return FAIL;
  }

  tasklet_async command uint8_t RadioState.getChannel() {
    return 0;
  }


  /***************** RadioSend ****************/
  
  void transmit_done(sim_event_t* evt) {
    sending = NULL;
    transmitting = FALSE;
    dbg("Driver.debug", "Driver: Transmission DONE @ %lu\n", (call LocalTime.get()*1000UL)/(1024UL*1024UL));
#ifdef SOFTWAREENERGY
    call TransmitEnergyState.off();
    if(running) {
      call ReceiveEnergyState.on();
    }
#endif
    signal RadioSend.sendDone(running ? SUCCESS : EOFF);
  }

  void transmit_start(sim_event_t* evt) {
    sim_time_t duration;

    duration = 8 * getHeader(sending)->length;
    duration /= sim_csma_bits_per_symbol();
    duration += sim_csma_preamble_length();

#ifdef TOSSIM_HARDWARE_ACK    
    if (call Ieee154PacketLayer.getAckRequired(sending)) {
      duration += sim_csma_ack_time();
    }
#endif
    duration *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());

    evt->time += duration;
    evt->handle = transmit_done;

    if(call Ieee154PacketLayer.isDataFrame(sending)) {
      dbg("Driver.debug", "Driver: Transmitting packet to %hu with ACK? %hhu\n", call Ieee154PacketLayer.getDestAddr(sending), call Ieee154PacketLayer.getAckRequired(sending));
    } else {
      dbg("Driver.debug", "Driver: Transmitting ACK to %hu\n", call Ieee154PacketLayer.getDestAddr(sending));
    }

    if(call PacketTimeSyncOffset.isSet(sending)) {
      void* timesync =  ((void*)sending) + call PacketTimeSyncOffset.get(sending);
      dbg("Driver.trace", "Driver: Updateing event time based on offset %hhu\n", call PacketTimeSyncOffset.get(sending));
      *(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - call LocalTime.get();      
    }

    call Model.putOnAirTo(call Ieee154PacketLayer.getDestAddr(sending), sending, call Ieee154PacketLayer.getAckRequired(sending), evt->time, 0.0, 0.0);

    evt->time += (sim_csma_rxtx_delay() *  (sim_ticks_per_sec() / sim_csma_symbols_per_sec()));

    dbg("Driver.debug", "Driver: Transmission time %llu us...\n", (duration*1000000ULL)/sim_ticks_per_sec() );

#ifdef SOFTWAREENERGY
    call ReceiveEnergyState.off();
    call TransmitEnergyState.on();
#endif

    sim_queue_insert(evt);
  }

  tasklet_async command error_t RadioSend.send(message_t* msg) {
    sim_time_t delay;

    if(!running) {
      dbgerror("Driver.error", "Driver: sending when radio is OFF\n");
      return EOFF;
    }

    if(sending!=NULL) {
      dbgerror("Driver.error", "Driver: already sending\n");
      return EBUSY;
    }

    dbg("Driver.debug", "Driver: Send to %hu @ %lu\n", call Ieee154PacketLayer.getDestAddr(msg), (call LocalTime.get()*1000UL)/(1024UL*1024UL));

    sending = msg;

    call RSSIFlag.clear(sending);
    if(tossimHardwareAck) {
      call AckReceivedFlag.clear(sending);
    }

    delay = sim_csma_rxtx_delay();
    delay *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());

    sendEvent.mote = sim_node();
    sendEvent.time = sim_time() + delay;
    sendEvent.force = 0;
    sendEvent.cancelled = 0;
    sendEvent.handle = transmit_start;
    sendEvent.cleanup = sim_queue_cleanup_none;

    transmitting = TRUE;
    call Model.setPendingTransmission();
    call PacketTimeStamp.set(msg, call LocalTime.get());

    dbg("Driver.debug", "Driver: Starting transmission in %llu us...\n", (delay*1000000ULL)/sim_ticks_per_sec() );
    dbg_message(msg);

    sim_queue_insert(&sendEvent);

    return SUCCESS;
  }


  /***************** RadioReceive ****************/

  event void Model.receive(message_t* msg) {
    tossim_header_t* header = getHeader(msg);

    if (running && !transmitting && (!(tossimHardwareAddressMatch || tossimHardwareAck) || !call Ieee154PacketLayer.isDataFrame(msg) || header->dest==TOS_NODE_ID || header->dest==TOS_BCAST_ADDR)) {

      memcpy(bufferPointer, msg, sizeof(message_t));

      call RSSIFlag.set(bufferPointer); // strength is always set from CpmModel
      call PacketTimeStamp.set(bufferPointer, call LocalTime.get());

      if(call Ieee154PacketLayer.isDataFrame(bufferPointer)) {
        dbg("Driver.debug", "Driver: receiving packet from %hu\n", call Ieee154PacketLayer.getSrcAddr(bufferPointer));
      } else {
        dbg("Driver.debug", "Driver: receiving ACK\n");
      }
      dbg_message(bufferPointer);

      if(signal RadioReceive.header(bufferPointer)) {
        bufferPointer = signal RadioReceive.receive(bufferPointer);
      }

    } else {

      if(!running) {
        dbg("Driver.debug", "Driver: discarding packet from %hu as radio is OFF\n", call Ieee154PacketLayer.getSrcAddr(msg));
      } else if(transmitting) {
        dbg("Driver.debug", "Driver: discarding packet from %hu as we are TRANSMITTING\n", call Ieee154PacketLayer.getSrcAddr(msg));
      } else {
        dbg("Driver.debug", "Driver: discarding packet from %hu due to TOSSIM hardware addr recognition\n", call Ieee154PacketLayer.getSrcAddr(msg));
      }
    }

  }

  event void Model.acked(message_t* msg) {

    if(!tossimHardwareAck) {
      dbgerror("Driver.error", "Driver: should never receive ACKs\n");
      return;
    }

    if (running) {
      dbg("Driver.debug", "Driver: ACK received from %hu\n", call Ieee154PacketLayer.getDestAddr(msg));
      call AckReceivedFlag.set(msg);
    } else {
      dbg("Driver.debug", "Driver: discarding ACK from from %hu as radio is OFF\n", call Ieee154PacketLayer.getDestAddr(msg));
    }

  }

  event bool Model.shouldAck(message_t* msg) {
    return tossimHardwareAck && running && !transmitting && call Ieee154PacketLayer.getDestAddr(msg)==TOS_NODE_ID;
  }  



  /***************** RadioCCA ****************/

  task void ccaDoneTask() {
    bool clear = call Model.clearChannel();
    dbg("Driver.trace", "Driver: Is channel clear? %hhu\n", clear);
    signal RadioCCA.done( clear ? SUCCESS : FAIL );
  }

  tasklet_async command error_t RadioCCA.request() {
    post ccaDoneTask();
    return SUCCESS;
  }


  /***************** RadioPacket ****************/
  
  async command uint8_t RadioPacket.headerLength(message_t* msg) {
    return 1;
  }

  async command uint8_t RadioPacket.payloadLength(message_t* msg) {
    return getHeader(msg)->length;
  }

  async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
    getHeader(msg)->length = length;
  }
  
  async command uint8_t RadioPacket.maxPayloadLength() {
    return sizeof(tossim_header_t) + TOSH_DATA_LENGTH;
  }

  async command uint8_t RadioPacket.metadataLength(message_t* msg) {
    return 0;
  }

  async command void RadioPacket.clear(message_t* msg) {}


  /***************** PacketTransmitPower ****************/

  async command bool PacketTransmitPower.isSet(message_t* msg) {
    return FALSE;
  }
  
  async command uint8_t PacketTransmitPower.get(message_t* msg) {
    return 0;
  }

  async command void PacketTransmitPower.clear(message_t* msg) {}
  async command void PacketTransmitPower.set(message_t* msg, uint8_t value) {}


  /***************** PacketRSSI ****************/

  async command bool PacketRSSI.isSet(message_t* msg) {
    return call RSSIFlag.get(msg);
  }

  async command uint8_t PacketRSSI.get(message_t* msg) {
    return getMetadata(msg)->strength;
  }

  async command void PacketRSSI.clear(message_t* msg) {
    call RSSIFlag.clear(msg);
  }

  async command void PacketRSSI.set(message_t* msg, uint8_t value) {
    call RSSIFlag.set(msg);
    getMetadata(msg)->strength = value;
  }


  /***************** PacketTimeSyncOffset ****************/

  async command bool PacketTimeSyncOffset.isSet(message_t* msg) {
    return call TimeSyncFlag.get(msg);
  }
  
  async command uint8_t PacketTimeSyncOffset.get(message_t* msg) {
    return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
  }

  async command void PacketTimeSyncOffset.clear(message_t* msg) {
    call TimeSyncFlag.clear(msg);
  }
  
  async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value) {
    call TimeSyncFlag.set(msg);
  }


  /***************** PacketLinkQuality ****************/

  async command bool PacketLinkQuality.isSet(message_t* msg) {
    return call RSSIFlag.get(msg);
  }

  async command uint8_t PacketLinkQuality.get(message_t* msg) {
    // we are using the strength as a link quality indicator
    return getMetadata(msg)->strength; 
  }

  async command void PacketLinkQuality.clear(message_t* msg) {
    call RSSIFlag.clear(msg);
  }

  async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
    call RSSIFlag.set(msg);
    getMetadata(msg)->strength = value;
  }


  /***************** PacketAcknowledgements ****************/

  async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
    call Ieee154PacketLayer.setAckRequired(msg, TRUE);
    return SUCCESS;
  }

  async command error_t PacketAcknowledgements.noAck(message_t* msg) {
    call Ieee154PacketLayer.setAckRequired(msg, FALSE);
    return SUCCESS;
  }

  async command error_t PacketAcknowledgements.wasAcked(message_t* msg) {
    return call AckReceivedFlag.get(msg);
  }

  /***************** Defaults ****************/
  
  default tasklet_async event void RadioState.done() {}
  default tasklet_async event void RadioSend.sendDone(error_t error) {}
  default tasklet_async event void RadioSend.ready() {}
  default tasklet_async event void RadioCCA.done(error_t error) {}
  default tasklet_async event bool RadioReceive.header(message_t* msg) { return TRUE; }
  default tasklet_async event message_t* RadioReceive.receive(message_t* msg) { return msg; }

  
}
