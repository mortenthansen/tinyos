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
 * @date   October 20 2011
 */

#include <Lidi.h>

configuration LidiEngineP {

  provides {
    interface StdControl;
  }

  uses {
    interface LidiCache[uint8_t id];
  }

} implementation {

  components 
    MainC,
    new LidiEngineImplP(uniqueCount(UQ_LIDI_DISSEMINATOR)),
    new AMSenderC(AM_LIDI_MESSAGE),
    new AMReceiverC(AM_LIDI_MESSAGE),
    /*LidiTimerP,
    new TimerMilliC() as PeriodicTimerC,
    new TimerMilliC() as FireTimerC,*/
    new TrickleTimerMilliC(DISSEMINATION_TIMER_MIN_PERIOD, DISSEMINATION_TIMER_MAX_PERIOD, 1, 1),
    RandomC;

  MainC.SoftwareInit -> LidiEngineImplP;
  LidiEngineImplP.LidiCache = LidiCache;
  //LidiEngineImplP.TrickleTimer -> LidiTimerP;
  LidiEngineImplP.TrickleTimer -> TrickleTimerMilliC.TrickleTimer[0];
  LidiEngineImplP.Send -> AMSenderC;
  LidiEngineImplP.Receive -> AMReceiverC;
  LidiEngineImplP.Packet -> AMSenderC;
  LidiEngineImplP.AMPacket -> AMSenderC;

  /*MainC.SoftwareInit -> LidiTimerP;
  LidiTimerP.PeriodicTimer -> PeriodicTimerC;
  LidiTimerP.FireTimer -> FireTimerC;
  LidiTimerP.Random -> RandomC;*/

  StdControl = LidiEngineImplP;

}
