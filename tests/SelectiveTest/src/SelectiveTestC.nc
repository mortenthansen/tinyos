/**
 * @author Morten Tranberg Hansen (mth@daimi.au.dk)
 * @date   May 30 2008
 */

#include "SelectiveTest.h"

configuration SelectiveTestC {}
implementation {
  components SelectiveTestP as App;
  
  components 
    MainC, 
    LedsC as Leds, 
    new RandomOffsetTimerMilliC() as Timer,
    new TimerMilliC() as StartTimer,
    ActiveMessageC,
    SerialActiveMessageC,
    new StaticRouteC(AM_DATA_MSG, 10, 30),
    SoftwareEnergyC,
    SelectiveForwardingP as Selective,
    MoteStatsP as MoteStats,
    CC2420ActiveMessageC,
    TestSensorC;

  App.Boot -> MainC;
  App.Leds -> Leds;
  App.StartTimer -> StartTimer;
  App.Timer -> Timer;

  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> SerialActiveMessageC;
  App.Send -> Selective;
  App.Receive -> Selective;

  App.SelectivePacket -> Selective;	
  App.LowPowerListening -> ActiveMessageC;

  App.Sensor -> TestSensorC;
  
  Selective.SubSend -> StaticRouteC;
  Selective.SubReceive -> StaticRouteC;
  Selective.SubPacket -> StaticRouteC;
  Selective.SubIntercept -> StaticRouteC;
  Selective.AMPacket -> ActiveMessageC;
  Selective.MoteStats -> MoteStats;
  Selective.SoftwareEnergy -> SoftwareEnergyC;

  MainC.SoftwareInit -> MoteStats;
  MoteStats.AppInfo -> App;
  MoteStats.LplInfo -> CC2420ActiveMessageC;
  MoteStats.SoftwareEnergy -> SoftwareEnergyC;

  components
    new RadioSoftwareEnergyC(19600, 17040);
  RadioSoftwareEnergyC.RadioInfo -> CC2420ActiveMessageC;

  components
    DebugC;

}
