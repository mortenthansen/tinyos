#include "Debug.h"

module CollectionTestP {

  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;    

    interface StdControl as CollectionControl;
    interface Send as CollectionSend;
    interface Receive as CollectionReceive;
    interface RootControl;
    interface CollectionPacket;
    interface AMPacket;
  }
} implementation {

  message_t message;
  bool busy = FALSE;
  
  /***************** Boot ****************/
  
  event void Boot.booted() {
    debug("App", "Booted!\n");
    call SerialControl.start();
    call RadioControl.start();
  }
  
  event void SerialControl.startDone(error_t error) {}
	
  event void SerialControl.stopDone(error_t err) {}

  event void RadioControl.startDone(error_t error) {
    call CollectionControl.start();
    if (TOS_NODE_ID == ROOT_NODE) {
      call RootControl.setRoot();
    } else {
      call Timer.startPeriodic(PERIOD);
    }
  }
  event void RadioControl.stopDone(error_t err) {}
  
  /***************** Timer ****************/
	
  event void Timer.fired() { 
    if (busy) {
      debug("App", "Send is busy.\n"); 
    } else {
      collection_msg_t* msg = (collection_msg_t*) call CollectionSend.getPayload(&message, sizeof(collection_msg_t));
      msg->value1 = 1;
      msg->value2 = 2;
      msg->value3 = 3;
      msg->value4 = 4;
      
      if (call CollectionSend.send(&message, sizeof(collection_msg_t)) == SUCCESS) {
        busy = TRUE;
        debug("App", "Sending message.\n");
      } else {
        debug("App", "Failed sending.\n");
      }		
    }		
  }

  event void CollectionSend.sendDone(message_t* msg, error_t err) {
    busy = FALSE;
  }
  
  /***************** Receive ****************/

  event message_t* CollectionReceive.receive(message_t* msg, void* payload, uint8_t len) {
    debug("App", "Received from %hu.\n", call CollectionPacket.getOrigin(msg));
    return msg;
  }
  
}
