#include "StaticRouteTest.h"
#include "Debug.h"

module StaticRouteTestP {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;
    interface Send;
    interface Receive;
  }

} implementation {

  message_t message;
  bool busy = FALSE;
  uint32_t counter = 0;
  
  /***************** Boot ****************/
  
  event void Boot.booted() {
    debug("App","Booted!\n");
    call SerialControl.start();
    call RadioControl.start();    
  }
  
  event void SerialControl.startDone(error_t error) {		
  }
	
  event void SerialControl.stopDone(error_t err) {}
    
  event void RadioControl.startDone(error_t error) {
    if(TOS_NODE_ID!=0) {
      call Timer.startPeriodic(PERIOD);
    }
  }
  
  event void RadioControl.stopDone(error_t err) {}
  	
  /***************** Timer ****************/
  
  event void Timer.fired() { 
    if (busy) {
      debug("App", "Send is busy.\n"); 
    } else {
      test_msg_t* msg = (test_msg_t*) call Send.getPayload(&message, sizeof(test_msg_t));
      
      msg->value = counter++;			
      
      if (call Send.send(&message, sizeof(test_msg_t))==SUCCESS) {
        busy = TRUE;
      }		
    }		
  }
  
  event void Send.sendDone(message_t* msg, error_t err) {
    busy = FALSE;
  }
  
  /***************** Receive ****************/

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    debug("App", "Message received\n");
    return msg;
  }
		   
}
