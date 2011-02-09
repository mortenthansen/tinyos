#include "Udp.h"
#include "printf.h"

module UdpTestP {

  uses {
    interface Boot;
    interface Thread as SendThread;
    interface Thread as ReceiveThread;
    interface BlockingStdControl as RadioControl;
    interface BlockingUdpSend as UdpSend;
    interface BlockingUdpReceive as UdpReceive;
    interface UdpPacket;
    interface Leds;
  }

} implementation {

  enum {
    PORT = 7000,
  };

  udpmessage_t sendMsg;
  udpmessage_t receiveMsg;

  typedef nx_struct data_msg {
    nx_int32_t value1;
    nx_int32_t value2;
  } data_msg_t;

  event void Boot.booted() {
    call SendThread.start(NULL);
  }

  event void SendThread.run(void* arg) {
    error_t error;
    data_msg_t* data = (data_msg_t*) call UdpPacket.getPayload(&sendMsg);
    call UdpPacket.setPayloadLength(&sendMsg, sizeof(data_msg_t));

    if(call RadioControl.start()!=SUCCESS) {
      call Leds.led0Toggle();
    }

    call ReceiveThread.start(NULL);

    sendMsg.dest.sin6_port = hton16(PORT);
    inet_pton6(REPORT_DEST, &sendMsg.dest.sin6_addr);
    data->value1 = 42;
    data->value2 = 67;

    while(TRUE) {
      //printf("FIRED\n");
      error = call UdpSend.send(&sendMsg.dest, &sendMsg);
      //printf("send with %hhu\n", error);
      //printfflush();
      call Leds.led1Toggle();
      call SendThread.sleep(1024);
    }
  }

  event void ReceiveThread.run(void* arg) {

    call UdpReceive.bind(PORT);

    while(TRUE) {
      if(call UdpReceive.receive(&receiveMsg, 0)==SUCCESS) {
        data_msg_t* data = (data_msg_t*) call UdpPacket.getPayload(&receiveMsg);
        printf("Got data %ld, %ld\n", data->value1, data->value2);
        printfflush();
        call Leds.led2Toggle();
      }
    }

  }

}
