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
 * @author Morten Tranberg Hansen
 * @date   August 31 2011
 */

generic module HplTossimRadioC() {

  provides {
    interface Alarm<TMicro, uint16_t>;
    interface LocalTime<TMicro> as LocalTimeRadio;
  }

} implementation {

  enum {
    TICKS_PER_SECOND = 1048576ULL, 
  }; 

  bool running = FALSE;
  uint16_t alarmTime = 0;
  sim_event_t* currentEvent = NULL;;

  sim_time_t clock_to_sim(sim_time_t t) {
    t *= sim_ticks_per_sec();
    t /= TICKS_PER_SECOND;
    return t;
  }

  sim_time_t sim_to_clock(sim_time_t t) {
    t *= TICKS_PER_SECOND;
    t /= sim_ticks_per_sec();
    return t;
  }

  /***************** Alarm ****************/  

  async command void Alarm.start(uint16_t dt) {
    call Alarm.startAt(call Alarm.getNow(), dt);
  }

  async command void Alarm.stop() {
    if(running) {
      dbg("HplTossimRadio.debug", "HplTossimRadio: stopping alarm\n");
      currentEvent->cancelled = TRUE;
      running = FALSE;
    }
  }

  async command bool Alarm.isRunning() {
    return running;
  }

  void alarm_fired(sim_event_t* evt) {
    if(!evt->cancelled) {
      dbg("HplTossimRadio.debug", "HplTossimAlarm: fired at %hu\n", call Alarm.getNow());
      running = FALSE;
      signal Alarm.fired();
    } else {
      dbg("HplTossimRadio.debug", "HplTossimAlarm: event cancelled\n");
    }
  }

  async command void Alarm.startAt(uint16_t t0, uint16_t dt) {

    uint16_t now = call Alarm.getNow();
    int32_t fire;
    sim_event_t* alarmEvent = sim_queue_allocate_event();    

    if(t0<=now) {
      fire = (int32_t)t0 + (int32_t)dt;
    } else {
      fire = (int32_t)dt - ((int32_t)(0xFFFF-t0) + (int32_t)now);
    }
    
    dbg("HplTossimRadio.debug","hej: %i\n", fire>now ? fire - now : 1);

    alarmEvent->time = sim_time() + clock_to_sim(fire>now ? fire - now : 1);
    alarmEvent->force = FALSE;
    alarmEvent->cancelled = FALSE;
    alarmEvent->handle = alarm_fired;
    alarmEvent->cleanup = sim_queue_cleanup_none;
    
    running = TRUE;
    alarmTime = (uint16_t)((fire+0xFFFF) & 0xFFFF);
    currentEvent = alarmEvent;
    
    dbg("HplTossimRadio.debug", "HplTossimRadio: scheduling event with alarmtime %hu, from now %hu, t0 %hu, and dt %hu\n", alarmTime, now, t0, dt);
      
    sim_queue_insert(alarmEvent);

  }

  async command uint16_t Alarm.getNow() {
    uint16_t now;    
    sim_time_t elapsed = sim_time()-sim_mote_start_time(sim_node());
    elapsed = sim_to_clock(elapsed);
    now = (uint16_t)(elapsed & 0xFFFF);
    dbg("HplTossimRadio.trace", "HplTossimRadio: now is %hu\n", now);
    return now;
  }

  async command uint16_t Alarm.getAlarm() {
    return alarmTime;
  }


  /***************** LocalTime ****************/  

  async command uint32_t LocalTimeRadio.get() {
    uint32_t lt;
    sim_time_t elapsed = sim_time()-sim_mote_start_time(sim_node());
    elapsed = sim_to_clock(elapsed);
    lt = (uint32_t)(elapsed & 0xFFFFFFFF);
    dbg("HplTossimRadio.trace", "HplTossimRadio: localtime is %lu\n", lt);
    return lt;
  }

}
