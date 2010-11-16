module SoftwareEnergyTestP {

	uses {
		interface Boot;
		interface Leds;

		interface Timer<TMilli> as Timer;

		interface SplitControl as RadioControl;
		interface AMSend as Send;
		interface Receive;
		interface PacketAcknowledgements as Acks;
		interface AMPacket;

		interface SoftwareEnergy;
	}

} implementation {
	
	message_t data;
	bool dataBusy;

	uint32_t seqno;

	/********** Boot **********/

	event void Boot.booted() {
		dbg("App", "Booted\n");
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t error) {
		dbg("App", "App startdone\n");
		if(TOS_NODE_ID!=RECEIVER) {
			call Timer.startPeriodic(256);
		}
	}

  event void RadioControl.stopDone(error_t error) {

	}

	/********** Data **********/

	event void Timer.fired() {
		test_msg_t* d = (test_msg_t*)call Send.getPayload(&data, sizeof(test_msg_t));

		dbg("App", "Fired!\n");

		if(dataBusy) {
			call Leds.led0Toggle();
			return;
		}
		
		call Acks.requestAck(&data);

		if(call Send.send(RECEIVER, &data, sizeof(test_msg_t))==SUCCESS) {
			dataBusy = TRUE;
		}
	}

	softenergy_charge_t lastUsed = 0;

  event void Send.sendDone(message_t* msg, error_t error) {
		softenergy_charge_t u;
		dataBusy = FALSE;

		if(error==SUCCESS && call Acks.wasAcked(msg)) {
			dbg("App", "Acked!\n");
			call Leds.led1Toggle();
		} else {
			dbg("App", "NOT acked!\n");
			call Leds.led0Toggle();
		}
		u = (call SoftwareEnergy.used()-lastUsed)/1000;
		dbg("App", "Used %llu mC\n", u);
		lastUsed = call SoftwareEnergy.used();
			
	}

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		test_msg_t*	d = ((test_msg_t*)payload);
		//dbg("App", "RECEIVED used %llu!\n", (call SoftwareEnergy.used()-lastUsed)/1000);
		lastUsed = call SoftwareEnergy.used();
		call Leds.led2Toggle();
		return msg;
	}

}
