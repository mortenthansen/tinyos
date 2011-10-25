#ifndef BLOCK_H
#define BLOCK_H

#ifndef BLOCK_MAX_RETRANSMISSIONS
#define BLOCK_MAX_RETRANSMISSIONS 5
#endif

enum {
	AM_BLOCK_DATA_MSG = 180,
	AM_BLOCK_ACK_MSG = 181,

	BLOCK_MAX_BUFFER_SIZE = 60, // current max size is 256
	BLOCK_RECEIVED_ARRAY_SIZE = (BLOCK_MAX_BUFFER_SIZE + 7) / 8,	

	//BLOCK_MAX_RETRANSMISSIONS = 1,// now set in Makefile
	BLOCK_DELAY_RETRANSMISSIONS = 0,

	BLOCK_ACK_QUEUE_SIZE = 5, //morten

	BLOCK_INTER_PACKET_ARRIVAL = 10,
	BLOCK_RESPONSE_TIME = BLOCK_INTER_PACKET_ARRIVAL*BLOCK_MAX_RETRANSMISSIONS,
	
};

typedef nx_struct ack_queue_entry {
	nx_am_addr_t addr;;
	nx_uint8_t grant;
} block_ack_queue_entry_t;

typedef nx_struct block_header {
	nx_uint8_t request;
	nx_uint8_t seqno;
} block_header_t;

typedef nx_struct block_ack {
	nx_uint8_t grant;
	nx_uint8_t received[BLOCK_RECEIVED_ARRAY_SIZE];
	nx_uint8_t start;
} block_ack_t;

#endif
