#include "CC2420.h"

configuration CC2420RadioC {

	provides {
		interface PacketAcknowledgements;
	}

} implementation {

	components
		CC2420PacketC;
	
	PacketAcknowledgements = CC2420PacketC;

}
