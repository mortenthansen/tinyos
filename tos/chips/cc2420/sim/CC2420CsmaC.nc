module CC2420CsmaC {

	provides {
		interface Init;
		interface Send;
		interface SplitControl;
		interface RadioBackoff;
        interface RadioInfo;
	}

	uses {
		interface CC2420PacketBody;
		interface CC2420Transmit;
		interface SplitControl as SubControl;
	}
	
} implementation {
	
	uint8_t running = FALSE;

	message_t* sendDoneMsg;
	error_t sendDoneError;

	task void sendDoneTask() {
		signal Send.sendDone(sendDoneMsg, sendDoneError);
	}

	command error_t Init.init() {
		return SUCCESS;
	}

  command error_t Send.send( message_t* msg, uint8_t len ) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
		
		if(!running) {
			return EOFF;
		} else {
			header->length = len;
			dbg("CC2420Csma","CSMA send len %hhu\n", len);
			return call CC2420Transmit.send(msg, TRUE);
		}
  }

  command error_t Send.cancel(message_t* msg) {
		dbg("CC2420Csma","CSMA cancel\n");
    return call CC2420Transmit.cancel();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return msg->data;
    } else {
      return NULL;
    }
  }

  command uint8_t Send.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  async event void CC2420Transmit.sendDone(message_t* ONE_NOK msg, error_t error) {
		dbg("CC2420Csma","CSMA sendDone\n");
		sendDoneMsg = msg;
		sendDoneError = error;
		post sendDoneTask();
	}

	command error_t SplitControl.start() {
		dbg("CC2420Csma","CSMA start\n");
		if(running) {
			return FAIL;
		} 
		signal RadioInfo.rx();
		return call SubControl.start();
	}
	
  event void SubControl.startDone(error_t error) {
		running = TRUE;
		dbg("CC2420Csma","CSMA startDone\n");
		signal SplitControl.startDone(error);
	}

  command error_t SplitControl.stop() {
		if(!running) {
			return FAIL;
		}
		signal RadioInfo.off();
		dbg("CC2420Csma","CSMA stop\n");
		return call SubControl.stop();
	}

  event void SubControl.stopDone(error_t error) {
		running = FALSE;
		dbg("CC2420Csma","CSMA stopDone\n");
		signal SplitControl.stopDone(error);
	}

  async command void RadioBackoff.setInitialBackoff(uint16_t backoffTime) {}

  async command void RadioBackoff.setCongestionBackoff(uint16_t backoffTime) {}

  async command void RadioBackoff.setCca(bool ccaOn) {}

  default event void SplitControl.startDone(error_t error) {}
  default event void SplitControl.stopDone(error_t error) {}

  default async event void RadioInfo.rx() {}
  default async event void RadioInfo.tx() {} 
  default async event void RadioInfo.off() {}


}
