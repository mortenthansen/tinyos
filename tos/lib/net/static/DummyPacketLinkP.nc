module DummyPacketLinkP {

  provides {
    interface PacketLink;
  }

  uses {
    interface PacketAcknowledgements;
  }

} implementation {

  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
    if(maxRetries>0) {
      call PacketAcknowledgements.requestAck(msg);
    } else {
      call PacketAcknowledgements.noAck(msg);
    }
  }

  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {}

  command uint16_t PacketLink.getRetries(message_t *msg) {
    return 0;
  }

  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return 0;
  }

  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }

}
