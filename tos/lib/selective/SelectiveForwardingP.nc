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
  
  void p(float i) {
    printf("%li.%02li", (int32_t)i, (int32_t)((i-(int32_t)i)*100.0));
  }
  
  bool variableThreshold(selective_importance_t importance) {
    float i = importance;
    float PI = call MoteStats.getPI()/100.0;
    float PR = call MoteStats.getPR()/100.0;
    float ET = call MoteStats.getET();
    float EI = call MoteStats.getEI();
    float ER = call MoteStats.getER();
    
    // This gives the mote the same accuracy as matlab
    // TODO: remove
    /*float PI = ((uint16_t)call MoteStats.getPI())/100.0;
      float ET = ((uint16_t)(call MoteStats.getET()*100.0))/100.0;
      float EI = ((uint16_t)(call MoteStats.getEI()*100.0))/100.0;
      float ER = ((uint16_t)(call MoteStats.getER()*100.0))/100.0;*/
    
    //float E0 = PI * EI + (1.0-PI) * ER;
    bool result = i>=threshold;
    float E0 = PI * EI + PR * ER;
    float rho = E0!=0.0 ? (1.0 - PI) * (ET / E0) : 1.0; // TODO: is 1.0 the right value when E0==0?
    float A = counter>1 ? 1.0/((float)counter) : 0.7;
    
    // dt
    float dt = 0;
    if(result) {
      dt = A * rho * (i-threshold);
    }
    
    threshold = ((1.0-A) * threshold + dt);
    
    printf("threshold: %li.%03lu, I: %hhu, E0: %lu, ET: %lu\n", (int32_t)threshold, (int32_t) ((threshold-((int)threshold))*1000), importance, (uint32_t)(E0*PRECISION), (uint32_t)(ET*PRECISION));
    
    /*printf("PI: ");p(PI);printf("\n");
      printf("ET: ");p(ET);printf("\n");
      printf("EI: ");p(EI);printf("\n");
      printf("r: ");p(r);printf("\n");
      printf("A: ");p(A);printf("\n");
      printf("dt: ");p(dt);printf("\n");
      printf("t: ");p(threshold);printf("\n");*/

    //printf("PI: %lu, r: %02f, A: %02f, dt: %02f, t: %02f, EI: %lu, ET: %lu, ER: %lu\n", call MoteStats.getPI(), (double)r, (double)A, (double)dt, (double)threshold, call MoteStats.getEI(), call MoteStats.getET(), call MoteStats.getER());
    //printf("%lu,%lu,%lu,%lu,%lu\n", threshold, PI, EI, ET, ER);
    debug_event4(DEBUG_THRESHOLD, (uint16_t)(threshold*PRECISION), (uint16_t)(rho*PRECISION), (uint16_t)(E0*PRECISION), importance);
    
    return result;
  }
  
  /***************** Intercept ****************/
  
  event bool SubIntercept.forward(message_t* msg, void* payload, uint8_t len) {
    bool result;
    if(counter<MAX_COUNTER) counter++;
	
    if(TOS_NODE_ID==3) {
      //time_start();	
#ifdef SELECTIVE_FIXED_THRESHOLD//SELECTIVE_USE_FIXED
#warning "***** Selective Using Fixed Threshold *****"
      result = fixedThreshold(call SelectivePacket.getImportance(msg));
#else
      result = variableThreshold(call SelectivePacket.getImportance(msg));
#endif
      
      //time_stop();
      //printf("THRESHOLD TIME: %lu\n",time_get());
      //printf("MORTEN PI=%hhu, PR=%hhu\n", (uint8_t)call MoteStats.getPI(), (uint8_t)call MoteStats.getPR());
      {
        debug_event4(DEBUG_MOTESTATS, (((uint16_t)(call MoteStats.getPI()+0.5))<<8) + ((uint16_t)(call MoteStats.getPR()+0.5)), call MoteStats.getEI()*PRECISION, call MoteStats.getET()*PRECISION, call MoteStats.getER()*PRECISION);
        //debug_event4(DEBUG_MOTESTATS, call MoteStats.getPI()*(PRECISION/100), call MoteStats.getEI()*PRECISION, call MoteStats.getET()*PRECISION, call MoteStats.getER()*PRECISION);
      }
      
    } else {
      //result = variableThreshold(call SelectivePacket.getImportance(msg));
      result = TRUE;
    }
    
    TODO MORTEN CHANGE TO USE DEBUG_BATTERY
      make sure change is applied to matlab code as well
      debug_event1(DEBUG_ROUTING_BATTERY, call Battery.getCharge()/32768UL);
    
    if(result) {
      dbg("Selective.debug", "%s: Forwarding message with importance %hhu \n", __FUNCTION__, call SelectivePacket.getImportance(msg));
    } else {
      debug_event4(DEBUG_DISCARDED_MSG, call CollectionPacket.getSequenceNumber(msg), call CollectionPacket.getOrigin(msg), call AMPacket.destination(msg), call SelectivePacket.getImportance(msg));
      //printf("DISCARD from %hu\n", call CollectionPacket.getOrigin(msg));
    }
    
    // TODO: what is right to do with the return value?
    signal Intercept.forward(msg, payload, len);
    
    return result;
  }
  
  /***************** Send ****************/
  
  command error_t Send.send(message_t* msg, uint8_t len) {
    dbg("Selective.debug", "%s: Forwarding message with importance %hhu \n", __FUNCTION__, call SelectivePacket.getImportance(msg));
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
    dbg("Selective.debug", "%s: Received message with importance %hhu \n", __FUNCTION__, call SelectivePacket.getImportance(msg));
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
  
}
