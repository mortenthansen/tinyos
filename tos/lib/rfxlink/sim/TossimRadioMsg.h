#ifndef TOSSIM_RADIO_MSG_H
#define TOSSIM_RADIO_MSG_H

#include "AM.h"

#include <RadioConfig.h>
#include <TinyosNetworkLayer.h>
#include <Ieee154PacketLayer.h>
#include <ActiveMessageLayer.h>
#include <MetadataFlagsLayer.h>
#include <TimeStampingLayer.h>
#include <LowPowerListeningLayer.h>
#include <PacketLinkLayer.h>

typedef nx_struct tossim_header {
  nx_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t group;
  nxle_uint16_t dest;
  nxle_uint16_t src;
  //ieee154_header_t ieee154;
#ifndef TFRAMES_ENABLED
  network_header_t network;
#endif
#ifndef IEEE154FRAMES_ENABLED
  nx_am_id_t type;
  //activemessage_header_t am;
#endif
} tossim_header_t;

typedef nx_struct tossim_footer {
  nxle_uint16_t crc;  
} tossim_footer_t;

typedef struct tossim_metadata {
  nx_int8_t strength;
  //nx_uint8_t ack;
  //nx_uint16_t time;
  // rfxlink metadata shall be put at the end in the order they appear
  // in the radio stack
#ifdef LOW_POWER_LISTENING
  lpl_metadata_t lpl;
#endif
#ifdef PACKET_LINK
  link_metadata_t link;
#endif
  timestamp_metadata_t timestamp;
  flags_metadata_t flags;
} tossim_metadata_t;

#endif
