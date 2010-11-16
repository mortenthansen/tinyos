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
 * @author Morten Tranberg Hansen
 * @date   April 12 2009
 */

#include "SoftwareEnergy.h"

generic module SoftwareEnergyP(uint8_t numStates, uint32_t maxCounterTime) {
	
  provides {
    interface Init;
    interface SoftwareEnergy;
    interface SoftwareEnergyState[softenergy_state_t s];
  }
  
  uses {
    interface SoftwareEnergyInfo[softenergy_state_t s];
    interface SoftwareEnergyComponent[softenergy_state_t s];
#ifdef TOSSIM
    interface Counter<TMilli,uint32_t>;
#else
    interface Counter<T32khz,uint32_t>;
#endif
  }
  
} implementation {
  
  struct softenergy_table_entry {
    bool running;
    uint32_t startTime;
    uint8_t overflows;
  } table[numStates];
  
  softenergy_energy_t used;
  
  /***************** Init ****************/	
  
  command error_t Init.init() {
    uint8_t i;
    for(i=0; i<numStates; i++) {
      table[i].running = FALSE;
      table[i].startTime = 0;
      table[i].overflows = 0;
    }
    used = 0;
    return SUCCESS;	
  }
  
  /***************** SoftwareEnergy ****************/	
  
  command softenergy_energy_t SoftwareEnergy.used() {
    softenergy_energy_t u;
    atomic u = used;
    return u;
  }

  command void SoftwareEnergy.evaluate() {
    uint8_t i;
    for(i=0; i<numStates; i++) {
      atomic {
        if(table[i].running) {
          dbg("SoftwareEnergy.debug", "%s: Evaluate state %hhu...\n", __FUNCTION__, i);
          call SoftwareEnergyState.off[i]();
          call SoftwareEnergyState.on[i]();
        }
      }
    }
  }

  
  /***************** SoftwareEnergyState ****************/	
  
  async command void SoftwareEnergyState.on[softenergy_state_t s]() {
    atomic {
      if(!table[s].running) {
        table[s].running = TRUE;
        table[s].startTime = call Counter.get();
        table[s].overflows = 0;
        call Counter.clearOverflow();
        dbg("SoftwareEnergy.debug", "%s: State %hhu ON!\n", __FUNCTION__, s);
        //printf("State %hhu ON at %lu!\n", s, (uint32_t)(call Counter.get()/32.768));
      } else {
        dbgerror("SoftwareEnergy.error", "%s: State %hhu is ALREADY running\n!", __FUNCTION__, s);
      }
    }
  }
  
  async command void SoftwareEnergyState.off[softenergy_state_t s]() {
    softenergy_energy_t t = 0;
    uint32_t counter = call Counter.get();
    atomic {
      if(table[s].running) {
        if(counter>=table[s].startTime) {
          t = counter - table[s].startTime;
          dbg("SoftwareEnergy.debug", "normal t %llu overflows %hhu counter %lu start %lu\n", t, table[s].overflows, counter, table[s].startTime);
        } else {
          t =  counter + (maxCounterTime - table[s].startTime);
          table[s].overflows--;
          dbg("SoftwareEnergy.debug", "overflow t %llu overflows %hhu\n", t, table[s].overflows);
        }
        while(table[s].overflows>0) {
          t += maxCounterTime;
          table[s].overflows--;
        }
#ifdef TOSSIM
        t = t*32.768; // convert miliseconds to 32KHz seconds
#endif
        // (32KHz seconds * uW)/32KHz = (32KHz uC)/32KHz = 32KHz uJ,
        used += (t * call SoftwareEnergyInfo.getPower[s]())/32768ULL; 
        call SoftwareEnergyComponent.use[s]((t * call SoftwareEnergyInfo.getPower[s]())/32768ULL);
        table[s].running = FALSE;
        
        dbg("SoftwareEnergy.debug", "%s: State %hhu OFF after %f ms cunsuming %f uJ!\n", __FUNCTION__, s, t/32.768, ((t * call SoftwareEnergyInfo.getPower[s]())/32768));
      } else {
        dbgerror("SoftwareEnergy.error", "%s: State %hhu is NOT running!\n",  __FUNCTION__, s);
      }
    }
    //printf("%hhu OFF at %lu after %lu consuming %lu\n", s, (uint32_t)(call Counter.get()/32.768), t, used);
  }
  
  async command void SoftwareEnergyState.reset[softenergy_state_t s]() {
    atomic {
      if(table[s].running) {
        table[s].running = FALSE;
        dbg("SoftwareEnergy.debug", "%s: State %hhu RESET!\n", __FUNCTION__, s);
        //printf("State %hhu RESET at %lu!\n", s, (uint32_t)(call Counter.get()/32.768));
      } else {
        dbgerror("SoftwareEnergy.error", "%s: State %hhu is NOT running!\n", __FUNCTION__, s);
      }
    }
  }
    
  /***************** Counter ****************/	
  
  async event void Counter.overflow() {
    //#warning "Counter from SoftwareEnergyP might overflow after appox 36 hours."
    uint8_t i;
    atomic {
      for(i=0; i<numStates; i++) {
        if(table[i].running) {
          table[i].overflows++;
        }
      }		
    }
    dbg("SoftwareEnergy.debug", "%s: Counter Overflow!\n", __FUNCTION__); 	
  }
  
  /***************** Defaults ****************/	
  
  default async command uint32_t SoftwareEnergyInfo.getPower[softenergy_state_t s]() {
    return 0;
  }

  default async command void SoftwareEnergyComponent.use[softenergy_state_t c](softenergy_energy_t energy) {}

}

