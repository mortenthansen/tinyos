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
 * @date   September 12 2010
 */

#include "Debug.h"

generic module DebugFlashLoggerP() {

  provides {
    interface Init;
    interface DebugLog;
  }

  uses {
    interface LogWrite;
    interface LogRead;
    interface Receive;
    interface DebugLog as Extractor;
    
    interface Leds;
  }

} implementation {

  uint8_t* writeBuffer;
  uint16_t writeLength;
  uint16_t writeCurrent;
  bool writing;

  uint8_t readBuffer[255];
  uint8_t readLength;
  bool reading;

  task void appendTask();
  task void readTask();

  void start_read();
  void stop_read();
  void start_write();
  void stop_write();  

  /***************** Init ****************/

  command error_t Init.init() {
    writeBuffer = NULL;
    writeLength = 0;
    writeCurrent = 0;
    writing = FALSE;
    readLength = 0;
    reading = FALSE;
    return SUCCESS;
  }

  /***************** DebugLog ****************/

  command void DebugLog.flush(uint8_t* buf, uint16_t len) {
    if(writeBuffer!=NULL) {
      call Leds.led0Toggle();
      signal DebugLog.flushDone();
      return;
    }
    call Leds.led2Toggle();
    writeBuffer = buf;
    writeLength = len;
    writeCurrent = 0;
    start_write();
    //signal DebugLog.flushDone();
  }

  /***************** LogWrite ****************/

  event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t error) {
    debug_msg_t* dbg = (debug_msg_t*) &writeBuffer[writeCurrent];
    writeCurrent += dbg->len;
    post appendTask();
  }

  event void LogWrite.eraseDone(error_t error) {
    if(error==SUCCESS) {
      call Leds.led1Toggle();
    } else {
      call Leds.led0Toggle();
    }
    stop_read();
  }

  event void LogWrite.syncDone(error_t error) {
    stop_write();
  }

  /***************** Receive ****************/

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if(len==0) {
      readLength = 0;
      start_read();
    }
    return msg;
  }

  /***************** LogRead ****************/

  event void LogRead.readDone(void* buf, storage_len_t len, error_t error) {
    if(error!=SUCCESS) {
      call Leds.led0Toggle();
    } else {

      if(len==0) {
        //call LogWrite.erase();
        stop_read();
        return;
      }
      
      if (readLength==0) {
        uint8_t l = *((uint8_t*)buf);
        if (l>0) {
          readLength = l;
          post readTask();
        } else {
          call Leds.led0Toggle();
        }
      } else {
        call Extractor.flush(readBuffer, readLength);
        readLength = 0;
      }
    
    }
  }

  event void LogRead.seekDone(error_t error) {
    post readTask();
  }

  /***************** Extractor ****************/

  event void Extractor.flushDone() {
    post readTask();
  }

  /***************** Tasks ****************/

  task void appendTask() {
    debug_msg_t* dbg = (debug_msg_t*) &writeBuffer[writeCurrent];

    if(writeCurrent>=writeLength) {
      dbg("DebugFlashLogger.debug", "%s: Buffer is empty, flush done.\n", __FUNCTION__);
      call LogWrite.sync();
      return;
    } else if(dbg->len==0) {
      dbgerror("DebugFlashLogger.error", "%s: Length of debug msg is 0, flush done.\n", __FUNCTION__);
      call LogWrite.sync();
      return;
    }
    
    if(call LogWrite.append(dbg, dbg->len)!=SUCCESS) {
      dbgerror("DebugFlashLogger.error", "%s: Could not append debug message.\n", __FUNCTION__);
      writeCurrent += dbg->len;
      post appendTask();
      call Leds.led0Toggle();
    }

  }

  task void readTask() {
    error_t error;

    /*if(call LogRead.currentOffset()==SEEK_BEGINNING) {
      call LogWrite.erase();
      return;
      }*/

    if(readLength==0) {
      error = call LogRead.read(readBuffer, 1);
    } else {
      error = call LogRead.read(&readBuffer[1], readLength-1);
    }

    if(error!=SUCCESS) {
      call Leds.led0Toggle();
    }

  }

  /***************** Functions ****************/

  void start_read() {
    reading = TRUE;
    if(!writing) {
      //call LogRead.seek(SEEK_BEGINNING);
      post readTask();
      //call LogWrite.erase();
    }
  }

  void stop_read() {
    reading = FALSE;
    if(writing) {
      start_write();
    }
  }

  void start_write() {
    writing = TRUE;
    if(!reading) {
      post appendTask();
    }
  }

  void stop_write() {
    writing = FALSE;
    writeBuffer = NULL;
    writeLength = 0;
    signal DebugLog.flushDone();
    if(reading) {
      start_read();
    }
  }
  

}
