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
 * @date   October 18 2009
 */

#include "Neighbor.h"

interface BlockNeighbor {

	command uint8_t getReserved(neighbor_t* ONE n);
	command void setReserved(neighbor_t* ONE n, uint8_t reserved);
	
	command uint8_t getStartSequenceNumber(neighbor_t* ONE n);
	command void setStartSequenceNumber(neighbor_t* ONE n, uint8_t start_seqno);

	command bool getReceived(neighbor_t* n, uint8_t number);
	command void setReceived(neighbor_t* n, uint8_t number);
	command uint8_t countReceived(neighbor_t* n);
	command void clearReceived(neighbor_t* n);

	/*command uint32_t getReceived(neighbor_t* ONE n);
		command void setReceived(neighbor_t* ONE n, uint32_t received);*/

	command uint32_t getTimeout(neighbor_t* ONE n);
	command void setTimeout(neighbor_t* ONE n, uint32_t timeout);

	command bool getIsReceived(neighbor_t* n);
	command void setIsReceived(neighbor_t* n, bool b);

	/*command uint8_t getAbortCounter(neighbor_t* ONE n);
		command void setAbortCounter(neighbor_t* ONE n, uint8_t counter);*/

	command message_t* ONE_NOK getMessage(neighbor_t* ONE n, uint8_t number);
	command void setMessage(neighbor_t* ONE n, uint8_t number, message_t* ONE_NOK message);

}
