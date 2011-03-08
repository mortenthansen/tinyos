module SoftwareEnergyComponentTestP {

  uses {
    interface Boot;

    interface Timer<TMilli> as Timer;

    interface SoftwareEnergy;
    interface SoftwareEnergy as SoftwareEnergyComponent;
    interface SoftwareEnergyState;
  }

} implementation {

  bool started;

  /********** Boot **********/

  event void Boot.booted() {
    dbg("App", "Booted\n");
    started = FALSE;
    call Timer.startPeriodic(256);
  }

  /********** Timer **********/

  event void Timer.fired() {

    if(started) {
      call SoftwareEnergyState.off();
      dbg("App", "Stopped with %llu == %llu\n", call SoftwareEnergy.used(), call SoftwareEnergyComponent.used());
      started = FALSE;
    } else {
      dbg("App", "Started\n");
      call SoftwareEnergyState.on();
      started = TRUE;
    }

  }

}
