
configuration UdpTestC {

} implementation {

  components
    MainC,
    UdpTestP as App,
    BlockingUdpC,
    new BlockingUdpSenderC(),
    new BlockingUdpReceiverC(),
    LedsC;

  components new ThreadC(200) as SendThread;
  components new ThreadC(200) as ReceiveThread;

  App.Boot -> MainC;
  App.SendThread -> SendThread;
  App.ReceiveThread -> ReceiveThread;
  App.RadioControl -> BlockingUdpC;
  App.UdpSend -> BlockingUdpSenderC;
  App.UdpReceive -> BlockingUdpReceiverC;
  
  App.UdpPacket -> BlockingUdpC;
  App.Leds -> LedsC;

  components PrintfC;

}
