module CC2420ReceiveC {
  
  provides {
    interface ReceiveIndicator as PacketIndicator;
  }
  
} implementation {
  
  // Receive stuff is handled in CC2420Transmit.
  
  command bool PacketIndicator.isReceiving() {
    return FALSE;
  }
  
}
