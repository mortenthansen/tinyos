#include "InjectionTest.h"

configuration InjectionTestC {

} implementation {

	components 
		InjectionTestP as App,
		ActiveMessageC,
		new AMReceiverC(AM_INJECTIONTEST_MSG) as Receiver;

	App.Receive -> Receiver;
	App.AMPacket -> ActiveMessageC;

}
