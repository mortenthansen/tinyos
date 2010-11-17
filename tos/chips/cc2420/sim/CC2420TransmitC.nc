

module CC2420TransmitC {
  
  provides {
    interface CC2420Transmit;
    interface ReceiveIndicator as EnergyIndicator;
    interface ReceiveIndicator as ByteIndicator;
  }
  
  uses {
    interface CC2420PacketBody;
    interface ChannelAccess;
    interface Send as SubSend;
  }
  
} implementation {
  
  message_t* lastMsg = NULL;
  uint8_t ack;
  
  /*void print_message(message_t* msg) {
  //uint8_t len = sizeof(message_t);//(call CC2420PacketBody.getHeader(msg))->length;
  //uint8_t* buf = (uint8_t*) msg;//call CC2420PacketBody.getPayload(msg);
  uint8_t len = (call CC2420PacketBody.getHeader(msg))->length;
  uint8_t* buf = (uint8_t*) call CC2420PacketBody.getPayload(msg);
  uint8_t j;
  dbg("CC2420Transmit","packet: ");
  for(j=0; j<len; j++) {
  dbg_clear("CC2420Transmit","%hhu ", buf[j]); 
  }
  dbg_clear("CC2420Transmit","\n");
  }*/
  
  task void sendTask() {
    error_t result;
    (call CC2420PacketBody.getMetadata(lastMsg))->ack = ack;
    dbg("CC2420Transmit", "send %hhu\n", (call CC2420PacketBody.getMetadata(lastMsg))->ack);
    result = call SubSend.send(lastMsg, (call CC2420PacketBody.getHeader(lastMsg))->length);
    if(result!=SUCCESS) {
      signal CC2420Transmit.sendDone(lastMsg, result);			
    }
  }
  
  async command error_t CC2420Transmit.send(message_t* ONE msg, bool useCca) {
    lastMsg = msg;
    ack = (call CC2420PacketBody.getMetadata(lastMsg))->ack;
    post sendTask();
    return SUCCESS;
  }
  
  async command error_t CC2420Transmit.resend(bool useCca) {
    if(lastMsg!=NULL) {
      post sendTask();
      return SUCCESS;
    } else {
      return FAIL;
    }
  }
  
  async command error_t CC2420Transmit.cancel() {
    dbg("CC2420Transmit","CC2420Transmit send\n");		
    if(lastMsg!=NULL) {
      return call SubSend.cancel(lastMsg);
    } else {
      return FAIL;
    }
  }
  
  async command error_t CC2420Transmit.modify(uint8_t offset, uint8_t* COUNT_NOK(len) buf, uint8_t len) {
    return FAIL;
  }

  event void SubSend.sendDone(message_t* msg, error_t error) {
    signal CC2420Transmit.sendDone(msg, error);
  }
  
  command bool EnergyIndicator.isReceiving() {
    return !call ChannelAccess.clearChannel(0);
  }
  
  command bool ByteIndicator.isReceiving() {
    return FALSE;
  }
  
}
