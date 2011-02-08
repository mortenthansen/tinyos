#ifndef TOSTHREAD_UDP_H
#define TOSTHREAD_UDP_H

#ifndef UDP_MAX_PAYLOAD_LENGTH
#define UDP_MAX_PAYLOAD_LENGTH 100
#endif

typedef struct udpmessage {
  struct sockaddr_in6 dest;
  struct sockaddr_in6 src;
  uint8_t len;
  uint8_t payload[UDP_MAX_PAYLOAD_LENGTH];
  struct ip_metadata  metadata;
} udpmessage_t;

#endif
