
configuration ActiveMessageC {

  provides {
    interface SplitControl;

    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];

    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface LowPowerListening;
  }

} implementation {

	components CC2420ActiveMessageC as CC2420;
	SplitControl = CC2420;
	AMSend = CC2420;
	Receive = CC2420.Receive;
	Snoop = CC2420.Snoop;
	Packet = CC2420;
	AMPacket = CC2420;
	PacketAcknowledgements = CC2420;
	LowPowerListening = CC2420;

}
