#include "PacketLinkTest.h"

module PacketLinkTestP {

	uses {
		interface Boot;
		interface Timer<TMilli> as Timer;
		interface Timer<TMilli> as CancelTimer;

		interface SplitControl as RadioControl;
		interface AMSend as Send;
		interface Receive;
		interface AMPacket;
#ifdef PACKET_LINK        
		interface PacketLink;
#endif
	}

} implementation {
	
	message_t data;
	bool dataBusy;

	uint32_t seqno;

	/********** Boot **********/

	event void Boot.booted() {
		call RadioControl.start();
		dbg("PacketLinkTest", "booted\n");
	}

	event void RadioControl.startDone(error_t error) {
		if(TOS_NODE_ID!=RECEIVER) {
			call Timer.startPeriodic(PERIOD);
		}
	}

  event void RadioControl.stopDone(error_t error) {

	}

	/********** Data **********/

	event void Timer.fired() {
		uint8_t i;
		test_msg_t* t = call Send.getPayload(&data, sizeof(test_msg_t));

        dbg("PacketLinkTest", "Fired!\n");

		if(dataBusy) {
			return;
		}

		for(i=0; i<sizeof(test_msg_t); i++) {
			t->data[i] = i+1;
		}

#ifdef PACKET_LINK
		call PacketLink.setRetries(&data, RETRIES);
		call PacketLink.setRetryDelay(&data, DELAY);
#endif

		if(call Send.send(RECEIVER, &data, sizeof(test_msg_t))==SUCCESS) {
			dataBusy = TRUE;
		}

        if(CANCEL_DELAY>0) {
          call CancelTimer.startOneShot(CANCEL_DELAY);
        }
	}

    event void CancelTimer.fired() {
      call Send.cancel(&data);
    }

    event void Send.sendDone(message_t* msg, error_t error) {
		dataBusy = FALSE;

		if(error==SUCCESS
#ifdef PACKET_LINK
           && call PacketLink.wasDelivered(&data)
#endif
           ) {
			dbg("PacketLinkTest", "**** SENT **** \n");
		} else {
			dbg("PacketLinkTest", "**** FAILED **** \n");
		}

	}

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		dbg("PacketLinkTest", "**** Received ****\n");
		return msg;
	}
}
