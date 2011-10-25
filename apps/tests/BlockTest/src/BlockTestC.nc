#include "BlockTest.h"
#include "QuickTime.h"

configuration BlockTestC @safe(){

} implementation {

  components
    MainC,
    LedsC,
    new RandomOffsetTimerMilliC() as Timer,
    ActiveMessageC,
    SerialActiveMessageC,
#ifdef USE_BTP
    BtpSenderC as Sender,
    BtpReceiverC as Receiver,
#else
    LlaSenderC as Sender,
    LlaReceiverC as Receiver,
#endif
    NeighborTableC,
    BlockTestP as App;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;
  App.Timer -> Timer;
  App.SerialControl -> SerialActiveMessageC;
  App.RadioControl -> ActiveMessageC;
  App.BlockSend -> Sender;
  App.BlockReceive -> Receiver;
  App.Acks -> ActiveMessageC;
  App.NeighborTable -> NeighborTableC;

  components
    QuickTimeC,
    new TimeMeasureMicroC();
  App.TimeMeasure -> TimeMeasureMicroC;

}
