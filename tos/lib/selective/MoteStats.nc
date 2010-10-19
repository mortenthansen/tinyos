interface MoteStats {

  /*command void record();
	command void recordTakeover();
	command void nextReceive();
	command void nextTransmit();
	command void nextTransmitTakeover();
	command void nextIdle();
	command void packetGenerated();
	command void packetReceived();
	command void wakeUp();*/
	command float getPI();
	command float getPR();
	command float getEI();
	command float getET();
	command float getER();
}
