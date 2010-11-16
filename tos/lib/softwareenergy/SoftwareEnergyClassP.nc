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

generic module SoftwareEnergyClassP() {

  provides {
    interface Init;
    interface SoftwareEnergy;
    interface SoftwareEnergyClass;
  }

  uses {
    interface SoftwareEnergy as SubSoftwareEnergy;
  }

} implementation {

  softenergy_energy_t used;

  command error_t Init.init() {
    used = 0;
    return SUCCESS;
  }

  command softenergy_energy_t SoftwareEnergy.used() {
    softenergy_energy_t u;
    atomic u = used;
    return u;
  }

  command void SoftwareEnergy.evaluate() {
    call SubSoftwareEnergy.evaluate();
  }

  async command void SoftwareEnergyClass.use(softenergy_energy_t energy) {
    atomic {
      used += energy;
    }
  }

}
