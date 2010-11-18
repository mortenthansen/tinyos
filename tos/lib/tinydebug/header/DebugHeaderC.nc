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
 * @date   September 14 2010
 */

generic configuration DebugHeaderC(typedef debug_header_t) {

  provides {
    interface DebugHeader<debug_header_t>;
    interface Send;
    interface Receive;
    interface Receive as Snoop;
    interface Packet;
  }

  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface Packet as SubPacket;
  }

} implementation {

#ifdef DEBUG

  components
    new DebugHeaderP(debug_header_t) as Impl;
  //new DummyDebugHeaderP(debug_header_t) as Impl;

#else
  components
    new DummyDebugHeaderP(debug_header_t) as Impl;
#warning "DebugHeaderC included but debug NOT activated!"
#endif

  DebugHeader = Impl;

  Send = Impl.Send;
  Receive = Impl.Receive;
  Snoop = Impl.Snoop;
  Packet = Impl.Packet;
  Impl.SubSend = SubSend;
  Impl.SubReceive = SubReceive;
  Impl.SubPacket = SubPacket;
  Impl.SubSnoop = SubSnoop;

  }


