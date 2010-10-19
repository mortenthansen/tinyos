#include "Selective.h"
#include "Debug.h"

module SelectiveForwardingP {
  
  provides {
    interface Send;
    interface Receive;
    interface Packet;
    interface Intercept;
    interface SelectivePacket;
  }
  
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
    interface Intercept as SubIntercept;
    
    interface AMPacket;
    interface MoteStats;
    interface SoftwareEnergy;
  }
  
} implementation {
  
  enum {
    //SELECTIVE_FIXED_THRESHOLD = 6,
    INIT_COUNTER = 9,
    MAX_COUNTER = 100,
    PRECISION = 1000,
  };
  
  float threshold = 0;
  uint8_t counter = INIT_COUNTER;
  
#ifdef SELECTIVE_FIXED_THRESHOLD
  bool fixedThreshold(selective_importance_t importance) {
    return importance>=SELECTIVE_FIXED_THRESHOLD;
  }
#endif
  
  bool variableThreshold(selective_importance_t importance) {
    float i = importance;
    float PI = call MoteStats.getPI()/100.0;
    float PR = call MoteStats.getPR()/100.0;
    float ET = call MoteStats.getET();
    float EI = call MoteStats.getEI();
    float ER = call MoteStats.getER();
        
    bool result = i>=threshold;
    float E0 = PI * EI + PR * ER;
    float rho = E0!=0.0 ? (1.0 - PI) * (ET / E0) : 1.0; // TODO: is 1.0 the right value when E0==0?
    float A = counter>1 ? 1.0/((float)counter) : 0.7;
    
    float dt = 0;
    if(result) {
      dt = A * rho * (i-threshold);
    }
    
    threshold = ((1.0-A) * threshold + dt);
    
    debug("Selective,THRESHOLD", "Threshold %f with rho: %f, EO: %f, and importance: %hhu\n", threshold, rho, E0, importance);
    
    return result;
  }
  
  /***************** Intercept ****************/
  
  event bool SubIntercept.forward(message_t* msg, void* payload, uint8_t len) {
    bool result;
    if(counter<MAX_COUNTER) counter++;
	
    if(TOS_NODE_ID==3) {
#ifdef SELECTIVE_FIXED_THRESHOLD//SELECTIVE_USE_FIXED
#warning "***** Selective Using Fixed Threshold *****"
      result = fixedThreshold(call SelectivePacket.getImportance(msg));
#else
      result = variableThreshold(call SelectivePacket.getImportance(msg));
#endif
      
      debug("Selective,MOTESTATS", "PI: %f, PR: %f, EI: %f, ET: %f, ER: %f\n", call MoteStats.getPI(), call MoteStats.getPR(), call MoteStats.getEI(), call MoteStats.getET(), call MoteStats.getER());
      
    } else {
      //result = variableThreshold(call SelectivePacket.getImportance(msg));
      result = TRUE;
    }
    
    debug("Selective,ENERGY_USED", "Energy used %llu\n", call SoftwareEnergy.used());
    
    if(result) {
      debug("Selective,FORWARD", "Forwarding message with importance: %hhu\n", call SelectivePacket.getImportance(msg));
    } else {
      debug("Selective,DISCARD", "Discarded message with importance: %hhu\n", call SelectivePacket.getImportance(msg));

    }
    
    // TODO: what is right to do with the return value?
    signal Intercept.forward(msg, payload, len);
    
    return result;
  }
  
  /***************** Send ****************/
  
  command error_t Send.send(message_t* msg, uint8_t len) {
    return call SubSend.send(msg, len + sizeof(selective_header_t));
  }
  
  command error_t Send.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }
  
  event void SubSend.sendDone(message_t* msg, error_t error) {
    signal Send.sendDone(msg, error);
  }
  
  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }
  
  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }
  
  /***************** Receive ****************/
  
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));
  }
  
  /***************** Packet ****************/
  
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(selective_header_t);
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(selective_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(selective_header_t);
  }
  
  // application payload pointer is just past the routing beacon header
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    void* payload = call SubPacket.getPayload(msg, len + sizeof(selective_header_t));
    if (payload != NULL) {
      payload += sizeof(selective_header_t);
    }
    return payload;
  }
  
  /***************** SelectivePacket ****************/
  
  selective_header_t* getHeader(message_t* m) {
    return (selective_header_t*)call SubPacket.getPayload(m, sizeof(selective_header_t));
  }
  
  command selective_importance_t SelectivePacket.getImportance(message_t* msg) {
    return getHeader(msg)->importance;
  }
  
  command void SelectivePacket.setImportance(message_t* msg, selective_importance_t importance) {
    getHeader(msg)->importance = importance;
  }

  /***************** Default ****************/

  default event bool Intercept.forward(message_t* msg, void* payload, uint8_t len) {
    return TRUE;
  }
  
}
