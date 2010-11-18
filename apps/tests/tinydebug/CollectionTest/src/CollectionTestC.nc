#include "CollectionTest.h"

configuration CollectionTestC {
} implementation {
  components CollectionTestP as App;
  
  components 
    MainC, 
    new RandomOffsetTimerMilliC() as Timer,
    ActiveMessageC,
    SerialActiveMessageC,
    CollectionC as Collection, 
    new CollectionSenderC(DATA_COLLECTION_ID);
  
  App.Boot -> MainC;
  App.Timer -> Timer;

  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> SerialActiveMessageC;
  
  App.CollectionControl -> Collection;
  App.CollectionSend -> CollectionSenderC;
  App.CollectionReceive -> Collection.Receive[DATA_COLLECTION_ID];
  App.RootControl -> Collection;
  App.CollectionPacket -> Collection;	
  App.AMPacket -> ActiveMessageC;

#ifdef DEBUG
  components 
    DebugC,
    new CollectionDebugToDebugP();
  Collection.CollectionDebug -> CollectionDebugToDebugP;
#else

  components 
    UARTDebugSenderP,
    new PoolC(message_t, 10),
    new QueueC(message_t*, 10),
    new SerialAMSenderC(45);

  UARTDebugSenderP.Boot -> MainC;
  UARTDebugSenderP.MessagePool -> PoolC;
  UARTDebugSenderP.SendQueue -> QueueC;
  UARTDebugSenderP.UARTSend -> SerialAMSenderC;
  Collection.CollectionDebug -> UARTDebugSenderP;

#endif

}
