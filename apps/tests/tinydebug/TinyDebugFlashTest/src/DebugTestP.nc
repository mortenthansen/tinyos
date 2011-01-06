#include "Debug.h"
#include "printf.h"

module DebugTestP {

  uses {
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;
    interface Boot;
    interface Timer<TMilli>;
  }

} implementation {

  uint8_t counter;

  event void Boot.booted() {
    call RadioControl.start();
    call SerialControl.start();
    call Timer.startPeriodic(1024);
  }

  event void RadioControl.startDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}
  event void SerialControl.startDone(error_t error) {}
  event void SerialControl.stopDone(error_t error) {}

  event void Timer.fired() {
    //printf("fired\n");
    debug("Flash,MESSAGE", "COUNTING: Lets's see if the flash works %hhu\n", counter++);
    debug("Flash,MESSAGE2", "COUNTING: %hhu\n", counter++);

  }

}
