#include <ip.h>
#include <lib6lowpan.h>

module UdpTestP {

  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface Timer<TMilli>;
    interface UDP;
    interface Leds;
  }

} implementation {

  enum {
    PORT = 7000,
  };

  typedef struct udpmessage {
    struct sockaddr_in6 dest;
    struct sockaddr_in6 src;
    uint8_t len;
    uint8_t payload[UDP_MAX_PAYLOAD_LENGTH];
    struct ip_metadata  metadata;
  } udpmessage_t;

  struct sockaddr_in6 dest;

  typedef nx_struct data_msg {
    nx_int32_t value1;
    nx_int32_t value2;
  } data_msg_t;

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    call UDP.bind(PORT);
    call Timer.startPeriodic(PERIOD);
  }

  event void RadioControl.stopDone(error_t error) {}

  event void Timer.fired() {
    data_msg_t data;
    dest.sin6_port = hton16(PORT);
    inet_pton6(REPORT_DEST, &dest.sin6_addr);
    data.value1 = 42;
    data.value2 = 67;
    call Leds.led1Toggle();
    call UDP.sendto(&dest, &data, sizeof(data_msg_t));
  }

  event void UDP.recvfrom(struct sockaddr_in6 *src, void *payload, uint16_t len, struct ip_metadata *meta) {
    call Leds.led2Toggle();
  }

}
