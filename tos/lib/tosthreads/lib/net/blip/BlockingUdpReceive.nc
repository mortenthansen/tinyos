#include "Udp.h"

interface BlockingUdpReceive {

  command error_t bind(uint16_t port);
  command error_t receive(udpmessage_t* msg, uint32_t timeout);

}
