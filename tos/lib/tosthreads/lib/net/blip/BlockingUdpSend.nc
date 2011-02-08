#include "Udp.h"

interface BlockingUdpSend {

  command error_t send(struct sockaddr_in6 *dest, udpmessage_t* msg);

}
