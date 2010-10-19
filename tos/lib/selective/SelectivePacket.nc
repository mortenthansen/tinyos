#include "Selective.h"

interface SelectivePacket {

	command selective_importance_t getImportance(message_t* msg);
	command void setImportance(message_t* msg, selective_importance_t priority);

}
