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
 * @author Morten Tranberg Hansen <mth at cs dot au dot dk>
 * @date   March 13 2011
 */

#include <Neighborhood.h>
#include "SyncLowPowerListeningLayer.h"

generic module SyncLowPowerListeningLayerP() {

  provides {
    interface Init;
    interface BareSend;
  }
  
  uses {
    interface BareSend as SubBareSend;
    interface Timer<TMilli> as DelayTimer;
    interface AckData<synclpl_ack_t>;
    interface LocalTime<TMilli>;
    interface Random;
    interface Timer<TMilli> as SleepTimer;
    interface Neighborhood;
    interface SyncLowPowerListeningConfig as Config;
    interface LowPowerListening;
    interface SystemLowPowerListening;
  }

} implementation {

  enum {
    // triggy parameter, if it is Config.getListenLength() it improves
    // PRR as the receiver might wakeup two times in one transmission
    MIN_OFFSET = 1, // [ms]
    RANDOM_OFFSET = 5, // [ms]
    // Max clock skew
    CLOCK_SKEW = 50, // [ppm]    
  };

  synclpl_neighbor_t table[NEIGHBORHOOD_SIZE];

  message_t* txMsg;
  uint16_t txWakeupInterval;

  bool shouldSyncSend(uint8_t idx);
  void signal_done(message_t* msg, error_t err);

  /***************** Init ****************/

  command error_t Init.init() {
    txMsg = NULL;
    txWakeupInterval = 0;
    return SUCCESS;
  }

  /***************** BareSend ****************/

  command error_t BareSend.send(message_t* msg) {
    uint8_t idx = call Neighborhood.getIndex(call Config.getDestination(msg));
    uint32_t wakeupInterval = call LowPowerListening.getRemoteWakeupInterval(msg);

    txMsg = msg;
    txWakeupInterval = call LowPowerListening.getRemoteWakeupInterval(msg);
    
    if(txWakeupInterval>0 && idx<NEIGHBORHOOD_SIZE && shouldSyncSend(idx)) {

      uint32_t nextWakeup;
      uint32_t offset;

#ifdef SYNCLPL_IMMEDIATE_SEND
      uint32_t nextOff;
      atomic nextOff = table[idx].off;
      if(nextOff>(call LocalTime.get()+call Config.getListenLength())) {
        dbg("SyncLpl.debug,SYNCLPL_IMMEDIATE_SEND", "SyncLpl: sending message immediately at %lu as receiver is still on for another %lu until %lu\n", call LocalTime.get(), nextOff-call LocalTime.get(), nextOff);
        call LowPowerListening.setRemoteWakeupInterval(msg, 2*call Config.getListenLength());
        return call SubBareSend.send(msg);        
      }
#endif

#ifdef SYNCLPL_SHARE_INTERVALS
      wakeupInterval = table[idx].interval;
#endif

      // Get next wakeup at destination
      atomic nextWakeup = table[idx].wakeup;
      while(nextWakeup<call LocalTime.get()) {
        nextWakeup += wakeupInterval;
      }
      
      // Calculate offset based on clock skew
      // We use a constant of 2 instead of WiseMAC's 4 as we are
      // measuring time since wakeup instead of wakeup time according
      // to the receivers clock.
      atomic offset = (2*CLOCK_SKEW*(call LocalTime.get()-table[idx].wakeup))/1000000 + MIN_OFFSET + (call Random.rand16()%RANDOM_OFFSET);

      // Send synced if it is expected to be an improvement
      if((offset+call Config.getListenLength())<wakeupInterval) {
        uint32_t delay;

        // Get delay need for next wakeup.  If wakeup is too soon we
        // go for the next one.
        if(nextWakeup >= offset + call LocalTime.get()) {
          delay = nextWakeup - offset - call LocalTime.get();
        } else {
          delay = nextWakeup + wakeupInterval - offset - call LocalTime.get();
        }

#ifdef SYNCLPL_OPTIMIZE_TRANSMISSION

        // Increase delay according to attempts to minimize the chance
        // of hidden terminal interference
        if(table[idx].attempts>0) {
          delay += wakeupInterval*(call Random.rand16()%table[idx].attempts);
        }

        wakeupInterval = offset+call Config.getListenLength();
        // We increase wakeup in a loop to make sure it does not overlap
        {
          uint8_t i;
          for (i=0; i<table[idx].attempts; i++) {
            // 7FFFF and 1
            if(wakeupInterval<0x3FFF) {
              wakeupInterval = wakeupInterval<<2;
            } else {
              wakeupInterval = 0xFFFF;
              break;
            }
          }
        }

        if(table[idx].attempts<0xFF) {
          table[idx].attempts++;
        }

        if( wakeupInterval < txWakeupInterval ) {
          dbg("SyncLpl.debug", "SyncLpl: Sending packet optimized on attempt %hhu with %hu instead of %hu, listen length %hu\n", table[idx].attempts, wakeupInterval, txWakeupInterval, call Config.getListenLength());
          call LowPowerListening.setRemoteWakeupInterval(msg, wakeupInterval);
        } else {
          dbg("SyncLpl.debug", "SyncLpl: Sending packet immediately on attempt %hhu with %hu instead of %hu, listen length %hu\n", table[idx].attempts, wakeupInterval, txWakeupInterval, call Config.getListenLength());
          return call SubBareSend.send(msg);
        }
#endif

        call DelayTimer.startOneShot(delay);

        dbg("SyncLpl.debug", "SyncLpl: sending synched to %hu with nextWakeup %lu, offset %lu, delay %lu\n", call Config.getDestination(msg), nextWakeup, offset, delay);

        return SUCCESS;

      } else {

        dbg("SyncLpl.debug,SYNCLPL_SENDING_NOTSYNCHED", "SyncLpl: cannot send synched to %hu with nextWakeup %lu, offset %lu+%hu (>=%hu)\n", call Config.getDestination(msg), nextWakeup, offset, call Config.getListenLength(), call LowPowerListening.getRemoteWakeupInterval(msg));

        return call SubBareSend.send(msg);        

      }

    } else {

      dbg("SyncLpl.debug,SYNCLPL_SENDING_NORMAL", "SyncLpl: sending unsynched to %hu\n", call Config.getDestination(msg));
      return call SubBareSend.send(msg);

    }

  }

  command error_t BareSend.cancel(message_t* msg) {
    return call SubBareSend.cancel(msg);
  }
  
  event void SubBareSend.sendDone(message_t* msg, error_t error) {
#ifdef SYNCLPL_OPTIMIZE_TRANSMISSION
    uint8_t idx = call Neighborhood.getIndex(call Config.getDestination(msg));
    // If packet was not send (e.g. due to busy channel), dont count it as an attempt
    if(idx<NEIGHBORHOOD_SIZE && error!=SUCCESS && table[idx].attempts>0) {
      table[idx].attempts--;
    }
#endif

    signal_done(msg, error);
  }

  /***************** DelayTimer ****************/

  event void DelayTimer.fired() {
    error_t err = call SubBareSend.send(txMsg);
    dbg("SyncLpl.debug,SYNCLPL_DELAY_TIMER", "SyncLpl: sending delayed message @ %lu \n", call LocalTime.get());
    if(err!=SUCCESS) {
      signal_done(txMsg, err);
    }
  }

  /***************** AckData ****************/

  tasklet_async event void AckData.requestData(uint16_t destination) {
    synclpl_ack_t* ack;
    atomic {
      ack = call AckData.getData();
      ack->wakeup = call LocalTime.get() - call SleepTimer.gett0();
#ifdef SYNCLPL_SHARE_INTERVALS
      ack->interval = call LowPowerListening.getLocalWakeupInterval();
#endif
    }
    dbg("SyncLpl.debug,SYNCLPL_REQUEST_DATA", "SyncLpl: setting own wakeup to %lu ms ago which was at %lu\n", ack->wakeup, call SleepTimer.gett0());
  }

  tasklet_async event void AckData.dataAvailable(uint16_t source, synclpl_ack_t* data) {
    uint8_t idx;
    atomic {
      idx = call Neighborhood.insertNode(source);
      table[idx].wakeup = call LocalTime.get() - data->wakeup;
#ifdef SYNCLPL_IMMEDIATE_SEND
      table[idx].off = call LocalTime.get() + call SystemLowPowerListening.getDelayAfterReceive();
#endif
#ifdef SYNCLPL_SHARE_INTERVALS
      table[idx].interval = data->interval;
#endif
#ifdef SYNCLPL_OPTIMIZE_TRANSMISSION
      table[idx].attempts = 0;
#endif
    }
    {
      uint32_t w;
      atomic w = table[idx].wakeup;
      dbg("SyncLpl.debug,SYNCLPL_DATA_AVAILABLE", "SyncLpl: Got last wakeup %lu ms ago from %hu which was at %lu\n", data->wakeup, source, w);
    }
  }

  /***************** Neighborhood ****************/  

  tasklet_async event void Neighborhood.evicted(uint8_t idx) {
    atomic memset(&table[idx], 0, sizeof(synclpl_neighbor_t));
  }

  /***************** Functions ****************/  

  inline bool shouldSyncSend(uint8_t idx) {
#ifdef SYNCLPL_SHARE_INTERVALS
    atomic return table[idx].wakeup>0 && table[idx].interval>0;
#else
    atomic return table[idx].wakeup>0;
#endif
  }

  inline void signal_done(message_t* msg, error_t err) {
    call LowPowerListening.setRemoteWakeupInterval(msg, txWakeupInterval);
    signal BareSend.sendDone(msg, err);
  }

  /***************** Ignore ****************/

  event void SleepTimer.fired() {}

}
