#include "PacketLinkTest.h"

configuration PacketLinkTestC {

} implementation {

	components 
		PacketLinkTestP as App,
		MainC,
		ActiveMessageC,
		new TimerMilliC() as Timer,
		new TimerMilliC() as CancelTimer,
		new AMSenderC(AM_TEST_MSG) as Sender,
		new AMReceiverC(AM_TEST_MSG) as Receiver;

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)
  components CC2420XActiveMessageC as PlatformActiveMessageC;
#elif defined (PLATFORM_MICA2) || defined (PLATFORM_MICA2DOT)
  components CC1000ActiveMessageC as PlatformActiveMessageC;
#elif defined (PLATFORM_IRIS)
  components RF230ActiveMessageC as PlatformActiveMessageC;
#else
  #error "Platform not supported by application!"
#endif

	App.Boot -> MainC;
	App.Timer -> Timer;
	App.CancelTimer -> CancelTimer;

	App.RadioControl -> ActiveMessageC;
	App.Send -> Sender;
	App.Receive -> Receiver;
	App.AMPacket -> ActiveMessageC;
#ifdef PACKET_LINK
	App.PacketLink -> PlatformActiveMessageC;
#endif

}
