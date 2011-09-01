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
 * @date   March 13 2011
 */

#ifndef __SYNCLOWPOWERLISTENINGLAYER_H__
#define __SYNCLOWPOWERLISTENINGLAYER_H__

#ifdef SYNCLPL_IMMEDIATE_SEND
#warning "*** SYNCHRONOUS LOW POWER LISTENING USES IMMEDIATE SEND"
#endif

#ifdef SYNCLPL_SHARE_INTERVALS
#warning "*** SYNCHRONOUS LOW POWER LISTENING SHARES INTERVALS"
#endif

#ifdef SYNCLPL_OPTIMIZE_TRANSMISSION
#warning "*** SYNCHRONOUS LOW POWER LISTENING OPTIMIZES TRANSMISSION TO FIT WAKEUP"
#endif

typedef struct synclpl_neighbor {
  uint32_t wakeup;
#ifdef SYNCLPL_IMMEDIATE_SEND
  uint32_t off;
#endif
#ifdef SYNCLPL_SHARE_INTERVALS
  uint32_t interval;
#endif
#ifdef SYNCLPL_OPTIMIZE_TRANSMISSION
  uint8_t attempts;
#endif
} synclpl_neighbor_t;

typedef struct synclpl_ack {
  nx_uint32_t wakeup;
#ifdef SYNCLPL_SHARE_INTERVALS
  nx_uint16_t interval;
#endif
} synclpl_ack_t;

#endif//__SYNCLOWPOWERLISTENINGLAYER_H__
