#include "SoftwareEnergy.h"

generic module SoftwareEnergyOverflowTestP() {
  
  uses {
    interface Boot;
    interface Leds;
    
    interface Timer<TMilli> as Timer;
    
    interface SoftwareEnergy;
    interface SoftwareEnergyComponent;
    
  }

} implementation {

  enum {
    STATE_ON,
    STATE_OFF,
  };
  
  uint8_t state = STATE_OFF;
  softenergy_charge_t lastUsed = 0;
  
  /********** Boot **********/
  
  event void Boot.booted() {
    dbg("App", "Booted\n");
    call Timer.startOneShot(1024);
  }
  
  /********** Timer **********/
  
  event void Timer.fired() {
    if(state==STATE_ON) {
      softenergy_charge_t u;
      dbg("App", "Turning OFF\n");	
      call SoftwareEnergyComponent.off();
      
      u = call SoftwareEnergy.used();
      dbg("App", "used now %llu uC\n", (u-lastUsed)/32768);
      lastUsed = u;
      
      state = STATE_OFF;
      call Timer.startOneShot(10);
    } else {
      dbg("App", "Turning ON\n");				
      call SoftwareEnergyComponent.on();
      state = STATE_ON;
      call Timer.startOneShot(2500);
    }
    
  }
  
}
