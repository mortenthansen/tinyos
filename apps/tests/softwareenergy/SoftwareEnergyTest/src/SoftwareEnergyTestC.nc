#include "SoftwareEnergyTest.h"

configuration SoftwareEnergyTestC {

} implementation {

	components 
		SoftwareEnergyTestP as App,
		MainC,
		LedsC,
		ActiveMessageC,
		new TimerMilliC() as Timer,
		new AMSenderC(AM_TEST_MSG) as Sender,
		new AMReceiverC(AM_TEST_MSG) as Receiver,
		SoftwareEnergyC;

	App.Boot -> MainC;
	App.Leds -> LedsC;

	App.Timer -> Timer;

	App.RadioControl -> ActiveMessageC;
	App.Send -> Sender;
	App.Receive -> Receiver;
	App.Acks -> ActiveMessageC;
	App.AMPacket -> ActiveMessageC;

	App.SoftwareEnergy -> SoftwareEnergyC;

}
