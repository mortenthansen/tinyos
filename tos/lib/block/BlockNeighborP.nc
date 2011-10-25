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

module BlockNeighborP @safe() {

	provides {
		interface InitNeighbor;
		interface BlockNeighbor;
	}

} implementation {

	typedef struct block_data {
		uint8_t reserved;
		uint8_t start_seqno;
		//uint32_t received;
		uint32_t timeout;
		bool is_received;
		message_t* ONE_NOK messages[BLOCK_MAX_BUFFER_SIZE];
		uint8_t received[BLOCK_RECEIVED_ARRAY_SIZE];
	} block_data_t;

	uint8_t offset = uniqueN(UQ_NEIGHBOR_BYTES, sizeof(block_data_t));
	
	block_data_t* get_data(neighbor_t* n) {
		return TCAST(block_data_t* ONE, n->bytes+offset);
	}

	/***************** InitNeighbor ****************/
	
	command error_t InitNeighbor.init(neighbor_t* n) {
		uint8_t i;
		block_data_t* data = get_data(n);
		data->reserved = 0;
		data->start_seqno = 0;
		data->timeout = 0;
		data->is_received = TRUE;
		for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
			data->messages[i] = NULL;
		}
		for(i=0; i<BLOCK_RECEIVED_ARRAY_SIZE; i++) {
			data->received[i] = 0;
		}
		return SUCCESS;
	}

	/***************** BlockNeighbor ****************/

	command uint8_t BlockNeighbor.getReserved(neighbor_t* n) {
		return get_data(n)->reserved;
	}

	command void BlockNeighbor.setReserved(neighbor_t* n, uint8_t reserved) {
		get_data(n)->reserved = reserved;
	}

	command uint8_t BlockNeighbor.getStartSequenceNumber(neighbor_t* n) {
		return get_data(n)->start_seqno;
	}

	command void BlockNeighbor.setStartSequenceNumber(neighbor_t* n, uint8_t start_seqno) {
		get_data(n)->start_seqno = start_seqno;
	}

	/*command uint32_t BlockNeighbor.getReceived(neighbor_t* n) {
		return get_data(n)->received;
	}

	command void BlockNeighbor.setReceived(neighbor_t* n, uint32_t received) {
		get_data(n)->received = received;
		}*/

	command bool BlockNeighbor.getReceived(neighbor_t* n, uint8_t number) {
		bool b = get_data(n)->received[number/8] & (1 << (number%8)) ? TRUE : FALSE;
		//printf("dav %hhu %hhu %hhu %hhu\n", number, get_data(n)->received[number/8], b, number%8);
		return b;
	}

	command void BlockNeighbor.setReceived(neighbor_t* n, uint8_t number) {
		if(number<BLOCK_MAX_BUFFER_SIZE) {
			get_data(n)->received[number/8] |= 1 << (number%8);
			//printf("hej %hhu %hhu\n", number, get_data(n)->received[number/8]);
		}
	}

	command uint8_t BlockNeighbor.countReceived(neighbor_t* n) {
		uint8_t count = 0;
		uint8_t i;
		for(i=0; i<BLOCK_MAX_BUFFER_SIZE; i++) {
			if(get_data(n)->received[i/8] & (1 << (i%8))) {
				count++;
			}
		}
		return count;
	}

	command void BlockNeighbor.clearReceived(neighbor_t* n) {
		uint8_t i;
		for(i=0; i<BLOCK_RECEIVED_ARRAY_SIZE; i++) {
			get_data(n)->received[i] = 0;
		}
	}

	command bool BlockNeighbor.getIsReceived(neighbor_t* n) {
		return get_data(n)->is_received;
	}

	command void BlockNeighbor.setIsReceived(neighbor_t* n, bool b) {
		get_data(n)->is_received = b;
	}

/*command uint8_t BlockNeighbor.getAbortCounter(neighbor_t* n) {
		return get_data(n)->abort_counter;
	}

	command void BlockNeighbor.setAbortCounter(neighbor_t* n, uint8_t counter) {
		get_data(n)->abort_counter = counter;
		}*/

	command uint32_t BlockNeighbor.getTimeout(neighbor_t* n) {
		return get_data(n)->timeout;
	}

	command void BlockNeighbor.setTimeout(neighbor_t* n, uint32_t timeout) {
		get_data(n)->timeout = timeout;
	}

	command message_t* BlockNeighbor.getMessage(neighbor_t* n, uint8_t number) {
		if(number<BLOCK_MAX_BUFFER_SIZE) {
			return get_data(n)->messages[number];
		} else {
			return NULL;
		}
	}
	command void BlockNeighbor.setMessage(neighbor_t* n, uint8_t number, message_t* message) {
		if(number<BLOCK_MAX_BUFFER_SIZE) {
			get_data(n)->messages[number] = message;
		}
	}

}
