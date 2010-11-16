configuration SoftwareEnergyOverflowTestC {
  
} implementation {

  enum {
    MAX_COUNTER_TIME = 1024,
  };
  
  components 
    new SoftwareEnergyOverflowTestP() as App,
    MainC,
    LedsC,
    new TimerMilliC() as Timer,
    new SoftwareEnergyP(1, MAX_COUNTER_TIME),
    new SoftwareEnergyCurrentP(1000),
    new TestCounterMilliC(MAX_COUNTER_TIME) as TestCounter,
    new TimerMilliC() as TestCounterTimer;
  
  MainC.SoftwareInit -> SoftwareEnergyP;
  SoftwareEnergyP.SoftwareEnergyCurrent[0] -> SoftwareEnergyCurrentP;
  SoftwareEnergyP.Counter -> TestCounter; 

  TestCounter.Boot -> MainC;
  TestCounter.Timer -> TestCounterTimer;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer -> Timer;

  App.SoftwareEnergy -> SoftwareEnergyP;  
  App.SoftwareEnergyComponent -> SoftwareEnergyP.SoftwareEnergyComponent[0];

}
