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
 * @author Morten Tranberg Hansen <mth at cs dot au dot dk>
 * @date   August 19 2009
 */

#include <Tasklet.h>

generic module AckDataP(typedef data_t, uint8_t offset, uint8_t maxOffset) @safe() {
  
  provides {
    interface AckData<data_t>;
  }
  
  uses {
    interface DataAck;
  }
  
} implementation {

  /***************** AckData ****************/
  
  tasklet_async command data_t*  AckData.getData() {
    uint8_t* data = (uint8_t*) call DataAck.getData();
    return TCAST(data_t* BND(data,data+maxOffset), data+offset);
  }
  
  tasklet_async event void DataAck.requestData(am_addr_t destination) {
    signal AckData.requestData(destination);
  }
  
  tasklet_async event void DataAck.dataAvailable(am_addr_t source, void* data, uint8_t length) {
    uint8_t* d = (uint8_t*) data;
    signal AckData.dataAvailable(source, TCAST(data_t* BND(d,d+maxOffset), d+offset));
  }

  /***************** Defaults ****************/

  default tasklet_async event void AckData.requestData(uint16_t destination) {}
  default tasklet_async event void AckData.dataAvailable(uint16_t source, data_t* data) {}

}
