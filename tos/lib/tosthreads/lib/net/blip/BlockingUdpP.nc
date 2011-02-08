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
 * @author Morten Tranberg Hansen <mth at cs dot au dot dk>
 * @date   February 8 2011
 */

module BlockingUdpP {

  provides {
    interface UdpPacket;
  }

} implementation {

  command struct sockaddr_in6* UdpPacket.getDestination(udpmessage_t* msg) {
    return &msg->dest;
  }

  command void UdpPacket.setDestination(udpmessage_t* msg, struct sockaddr_in6* dest) {
    memcpy(&msg->dest, dest, sizeof(struct sockaddr_in6));
  }

  command struct sockaddr_in6* UdpPacket.getSource(udpmessage_t* msg) {
    return &msg->src;
  }

  command void UdpPacket.setSource(udpmessage_t* msg, struct sockaddr_in6* src) {
    memcpy(&msg->src, src, sizeof(struct sockaddr_in6));
  }

  command uint8_t UdpPacket.payloadLength(udpmessage_t* msg) {
    return msg->len;
  }

  command void UdpPacket.setPayloadLength(udpmessage_t* msg, uint8_t len) {
    msg->len = len;
  }

  command void* UdpPacket.getPayload(udpmessage_t* msg) {
    return msg->payload;
  }

  command struct ip_metadata* UdpPacket.getMetadata(udpmessage_t* msg) {
    return &msg->metadata;
  }


}
