
configuration UdpTestC {

} implementation {

  components
    MainC,
    UdpTestP as App,
    IPDispatchC,
    new TimerMilliC(),
    new UdpSocketC(),
    LedsC;
  
  App.Boot -> MainC;
  App.RadioControl -> IPDispatchC;
  App.Timer -> TimerMilliC;
  App.UDP -> UdpSocketC;
  App.Leds -> LedsC;

}
