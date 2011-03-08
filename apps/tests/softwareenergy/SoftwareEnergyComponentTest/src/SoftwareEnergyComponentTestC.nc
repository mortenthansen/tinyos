configuration SoftwareEnergyComponentTestC {

} implementation {

  components
    SoftwareEnergyComponentTestP as App,
    MainC,
    new TimerMilliC() as Timer,
    new SoftwareEnergyStateC(3000,20000),
    new SoftwareEnergyComponentC(),
    SoftwareEnergyC;

  SoftwareEnergyStateC.SoftwareEnergyComponent -> SoftwareEnergyComponentC;

  App.Boot -> MainC;
  App.Timer -> Timer;

  App.SoftwareEnergy -> SoftwareEnergyC;
  App.SoftwareEnergyComponent -> SoftwareEnergyComponentC;
  App.SoftwareEnergyState -> SoftwareEnergyStateC;

}
