/*
 * Copyright (c) 2011 Aarus University
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
 * - Neither the name of Aarus University nor the names of
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
 * @date   March 30 2011
 */

generic module SoftwareAddressMatchLayerP() {

  provides {
    interface RadioReceive;
  }
  
  uses {
    interface RadioReceive as SubReceive;
    interface SoftwareAddressMatchConfig as Config;
    interface ActiveMessageAddress;
  }

} implementation {

  tasklet_async event bool SubReceive.header(message_t* msg) {
    if(call Config.hasDestination(msg)) {
#ifdef TOSSIM
      if(!(call Config.getDestination(msg)==call ActiveMessageAddress.amAddress() || call Config.getDestination(msg)==TOS_BCAST_ADDR)) {
        dbg("SoftwareAddressMatch.debug", "SoftwareAddressMatch: discarding packet to %hu\n", call Config.getDestination(msg));
      }
#endif
      return (call Config.getDestination(msg)==call ActiveMessageAddress.amAddress() || call Config.getDestination(msg)==TOS_BCAST_ADDR) && signal RadioReceive.header(msg);
    } else {
      return signal RadioReceive.header(msg);
    }
  }
  
  tasklet_async event message_t* SubReceive.receive(message_t* msg) {
    return signal RadioReceive.receive(msg);
  }

  async event void ActiveMessageAddress.changed() {}

}
