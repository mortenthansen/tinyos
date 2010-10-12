/**
 * @author Morten Tranberg Hansen (mth@daimi.au.dk)
 * @date   May 30 2008
 */

#include "StaticRouteTest.h"

configuration StaticRouteTestC {}
implementation {
  components StaticRouteTestP as App;
  
  components 
    MainC, 
    new TimerMilliC() as Timer,
    //new RandomOffsetTimerMilliC() as Timer,
    ActiveMessageC,
    SerialActiveMessageC,
    new StaticRouteC(AM_TEST_MSG, 10, 30);

  App.Boot -> MainC;
  App.Timer -> Timer;
  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> SerialActiveMessageC;
  App.Send -> StaticRouteC;
  App.Receive -> StaticRouteC;

  components
    DebugC;

}
