#include "TimeSyncTest.h"

module TimeSyncTestP {
  
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface Timer<TMilli>;
    interface Leds;
    
    interface TimeSyncAMSend<TMilli,uint32_t> as Send;
    interface Receive;
    interface LocalTime<TMilli>;
    interface TimeSyncPacket<TMilli,uint32_t>;		
  }
  
  
} implementation {

  message_t message;
  uint16_t seqno;
  
  event void Boot.booted() {
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t error) {
    if(TOS_NODE_ID==SENDER) {
      call Timer.startPeriodic(PERIOD);
    }
  }
  
  event void RadioControl.stopDone(error_t error) {}
  
  event void Timer.fired() {
    timesynctest_msg_t* timemsg = (timesynctest_msg_t*) call Send.getPayload(&message, sizeof(timesynctest_msg_t));

    dbg("App", "Fired at %llu\n", sim_time());

    timemsg->seqno = seqno++;
    timemsg->localtime = call LocalTime.get();
	
    if(call Send.send(AM_BROADCAST_ADDR, &message, sizeof(timesynctest_msg_t), timemsg->localtime)!=SUCCESS) {
      call Leds.led0Toggle();
    }

  }
  
  event void Send.sendDone(message_t* msg, error_t error) {
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    timesynctest_msg_t* timemsg = (timesynctest_msg_t*) payload;		
    
    if(call TimeSyncPacket.isValid(msg)) {
      call Leds.led2Toggle();

      dbg("App", "Difference: %li\n", ((int32_t)timemsg->localtime) - ((int32_t)call TimeSyncPacket.eventTime(msg)));
      
    } else {
      dbgerror("App", "TimeSync not VALID!\n");
    }

    return msg;
  }
  
}
