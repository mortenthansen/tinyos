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
 * @date   October 10 2010
 */

generic configuration StaticRouteC(am_id_t id, uint8_t queueLength, uint8_t maxRetries) {

  provides {
    interface Send;
    interface Receive;
    interface Intercept;
    interface Packet;
  }
  
} implementation {

  components
    MainC,
    new StaticRouteP(maxRetries),
    new AMSenderC(id),
    new AMReceiverC(id),
    new PoolC(message_t, queueLength) as MessagePool,
    new QueueC(message_t*, queueLength+1) as SendQueue;

  MainC.SoftwareInit -> StaticRouteP;
  StaticRouteP.SubSend -> AMSenderC;
  StaticRouteP.SubReceive -> AMReceiverC;
  StaticRouteP.SubPacket -> AMSenderC;
  StaticRouteP.MessagePool -> MessagePool;
  StaticRouteP.SendQueue -> SendQueue;

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS)
  components CC2420ActiveMessageC as PacketLink;
#else
  #warning "*** USING DUMMY PACKET LINK IN STATIC ROUTE ***"
  components DummyPacketLinkP as PacketLink;
#endif
  
  StaticRouteP.PacketLink -> PacketLink;

  Send = StaticRouteP;
  Receive = StaticRouteP;
  Intercept = StaticRouteP;
  Packet = StaticRouteP;

}
