configuration TimeSyncTestC {
} implementation {
  
  components 
    MainC, 
    LedsC as Leds,
    LocalTimeMilliC,
    TossimRadioC,
    new TimerMilliC(),
    TimeSyncMessageC as AM,
    TimeSyncTestP as App;
  
  App.Boot -> MainC;
  App.RadioControl -> AM;
  App.LocalTime -> LocalTimeMilliC;
  //App.LocalTime -> TossimRadioC;
  App.Timer -> TimerMilliC;
  App.Leds -> Leds;
  
  App.Send -> AM.TimeSyncAMSendMilli[AM_TIMESYNCTEST_MSG];
  App.Receive -> AM.Receive[AM_TIMESYNCTEST_MSG];
  App.TimeSyncPacket -> AM;
  
}
