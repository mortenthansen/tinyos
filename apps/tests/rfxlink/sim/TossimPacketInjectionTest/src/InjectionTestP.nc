module InjectionTestP {

	uses {
		interface Receive;
		interface AMPacket;
	}

} implementation {

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    uint8_t i;
    injectiontest_msg_t* d = ((injectiontest_msg_t*)payload);
    dbg("App", "Received type %hu with data:", call AMPacket.type(msg));
    for(i=0; i<TOSH_DATA_LENGTH; i++) {
      dbg_clear("App", " %hhu", d->data[i]);
    }
    dbg_clear("App", "\n");

    /*dbg("App", "message:");
    for(i=0; i<sizeof(message_t); i++) {
      dbg_clear("App", " %hhu", *(((uint8_t*)msg)+i));
    }
    dbg_clear("App", "\n");*/

    return msg;
  }
  
}
