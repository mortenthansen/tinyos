configuration TestSensorC {

  provides interface Read<uint16_t>;

} implementation {

  components 
    MainC,
    new SineSensorC();

  MainC.SoftwareInit -> SineSensorC;
  Read = SineSensorC;

}
