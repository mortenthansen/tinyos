
interface UdpPacket {

  command struct sockaddr_in6* getDestination(udpmessage_t* msg);
  command void setDestination(udpmessage_t* msg, struct sockaddr_in6* dest);

  command struct sockaddr_in6* getSource(udpmessage_t* msg);
  command void setSource(udpmessage_t* msg, struct sockaddr_in6* src);

  command uint8_t payloadLength(udpmessage_t* msg);
  command void setPayloadLength(udpmessage_t* msg, uint8_t len);
  command void* getPayload(udpmessage_t* msg);
  command struct ip_metadata* getMetadata(udpmessage_t* msg);

}
