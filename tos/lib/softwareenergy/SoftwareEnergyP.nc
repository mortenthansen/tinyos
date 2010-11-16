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

generic module SoftwareEnergyP(uint8_t numComponents, uint32_t maxCounterTime) {
	
  provides {
    interface Init;
    interface SoftwareEnergy;
    interface SoftwareEnergyComponent[softenergy_component_t c];
  }
  
  uses {
    interface SoftwareEnergyCurrent[softenergy_component_t c];
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
  } table[numComponents];
  
  softenergy_charge_t used;
  
  /***************** Init ****************/	
  
  command error_t Init.init() {
    uint8_t i;
    for(i=0; i<numComponents; i++) {
      table[i].running = FALSE;
      table[i].startTime = 0;
      table[i].overflows = 0;
    }
    used = 0;
    return SUCCESS;	
  }
  
  /***************** SoftwareEnergy ****************/	
  
  command softenergy_charge_t SoftwareEnergy.used() {
    softenergy_charge_t u;
    atomic u = used;
    return u;
  }
  
  /***************** SoftwareEnergyComponent ****************/	
  
  async command void SoftwareEnergyComponent.on[softenergy_component_t c]() {
    atomic {
      if(!table[c].running) {
        table[c].running = TRUE;
        table[c].startTime = call Counter.get();
        table[c].overflows = 0;
        call Counter.clearOverflow();
        dbg("SoftwareEnergy.debug", "%s: Component %hhu ON!\n", __FUNCTION__, c);
        //printf("Component %hhu ON at %lu!\n", c, (uint32_t)(call Counter.get()/32.768));
      } else {
        dbgerror("SoftwareEnergy.error", "%s: Component %hhu is ALREADY running\n!", __FUNCTION__, c);
      }
    }
  }
  
  async command void SoftwareEnergyComponent.off[softenergy_component_t c]() {
    softenergy_charge_t t = 0;
    uint32_t counter = call Counter.get();
    atomic {
      if(table[c].running) {
        if(counter>=table[c].startTime) {
          t = counter - table[c].startTime;
          dbg("SoftwareEnergy.debug", "normal t %llu overflows %hhu counter %lu start %lu\n", t, table[c].overflows, counter, table[c].startTime);
        } else {
          t =  counter + (maxCounterTime - table[c].startTime);
          table[c].overflows--;
          dbg("SoftwareEnergy.debug", "overflow t %llu overflows %hhu\n", t, table[c].overflows);
        }
        while(table[c].overflows>0) {
          t += maxCounterTime;
          table[c].overflows--;
        }
#ifdef TOSSIM
        t = t*32.768; // convert miliseconds to 32KHz seconds
#endif
        // (32KHz seconds * uA)/1000 = (32KHz uC)/1000 = 32KHz mC,
        used += (t * call SoftwareEnergyCurrent.getCurrent[c]())/1000; 
        table[c].running = FALSE;
        
        dbg("SoftwareEnergy.debug", "%s: Component %hhu OFF after %f ms cunsuming %f mC!\n", __FUNCTION__, c, t/32.768, ((t * call SoftwareEnergyCurrent.getCurrent[c]())/1000.0)/32768.0);
      } else {
        dbgerror("SoftwareEnergy.error", "%s: Component %hhu is NOT running!\n", c, __FUNCTION__);
      }
    }
    //printf("%hhu OFF at %lu after %lu consuming %lu\n", c, (uint32_t)(call Counter.get()/32.768), t, used);
  }
  
  async command void SoftwareEnergyComponent.reset[softenergy_component_t c]() {
    atomic {
      if(table[c].running) {
        table[c].running = FALSE;
        dbg("SoftwareEnergy.debug", "%s: Component %hhu RESET!\n", __FUNCTION__, c);
        //printf("Component %hhu RESET at %lu!\n", c, (uint32_t)(call Counter.get()/32.768));
      } else {
        dbgerror("SoftwareEnergy.error", "%s: Component %hhu is NOT running!\n", c, __FUNCTION__);
      }
    }
  }
    
  /***************** Counter ****************/	
  
  async event void Counter.overflow() {
    //#warning "Counter from SoftwareEnergyP might overflow after appox 36 hours."
    uint8_t i;
    atomic {
      for(i=0; i<numComponents; i++) {
        if(table[i].running) {
          table[i].overflows++;
        }
      }		
    }
    dbg("SoftwareEnergy.debug", "%s: Counter Overflow!\n", __FUNCTION__); 	
  }
  
  /***************** Defaults ****************/	
  
  default async command uint32_t SoftwareEnergyCurrent.getCurrent[softenergy_component_t c]() {
    return 0;
  }

}

