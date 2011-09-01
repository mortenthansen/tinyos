

interface SyncLowPowerListeningConfig
{

	/**
	 * Returns the number of milliseconds the mote should turn on
	 * its radio to check for incoming messages. This check is 
	 * performed at every localWakeInterval.
	 */
	command uint16_t getListenLength();

	/**
	 * Returns the destination of a message
	 */
	command uint16_t getDestination(message_t* msg);

}
