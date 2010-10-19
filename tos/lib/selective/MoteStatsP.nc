#include <emath.h>
#include "Debug.h"

module MoteStatsP {
  
  provides {
    interface Init;
    interface MoteStats;
  }
  
  uses {
    interface AppInfo;
    interface LplInfo;
    interface SoftwareEnergy;
  }
  
} implementation {

  enum {
    S_UNKNOWN,
    S_IDLE,
    S_RECEIVE,
    S_TRANSMIT,
    S_GENERATED,
    INIT_COUNTER = 0,
    MAX_COUNTER = 100,
    MATURE_COUNTER = 1, // set to 1 to disable
    PACKET_GENERATION_EST = 0, // according to jesus mail 22 may 2009.
    
    PRECISION = 1000,
  };
  
  uint8_t nextState;
  battery_charge_t lastEnergy;
  
  uint8_t idleCounter, transmitCounter, receiveCounter, piCounter, prCounter;
  
  float transmitEnergy, idleEnergy, receiveEnergy, pi, pr;
  
  uint8_t receivedSinceLast, wakeUpSinceLast;
  
  bool pending;
  float pendingEnergy;
  uint8_t pendingFree;	
  
  uint8_t prevState;
  float prevEnergy;
  float nextPenalty;

  float ewma_counter(float oldValue, float newValue, uint32_t counter) {
	if(counter<2) {
      return newValue;
	} else {
		float gain = 1.0-1.0/((float)counter);
		return gain * oldValue + (1.0-gain) * newValue;
	}
  }

  
  command error_t Init.init() {
    nextState = S_UNKNOWN;
    lastEnergy = 0;
    
    idleCounter = transmitCounter = receiveCounter = piCounter = prCounter = INIT_COUNTER;
    transmitEnergy = idleEnergy = receiveEnergy = pi = pr = 0.0;
    
    receivedSinceLast = wakeUpSinceLast = 0;
    
    pending = FALSE;
    pendingEnergy = 0.0;
    pendingFree = 0;
    
    prevState = S_UNKNOWN;
    prevEnergy = 0.0;
    nextPenalty = 0.0;
    
    return SUCCESS;
  }
  
  void updatePI(bool i) {
    if(piCounter<100) piCounter++;
    pi = ewma_counter(pi, i, piCounter);
    debug("MoteStats,PI","PI is %f after being updated with %hhu", pi, i);
  }
  
  void updatePR(bool r) {
    if(prCounter<100) prCounter++;
    pr = ewma_counter(pr, r, prCounter);
    debug("MoteStats,PR","PR is %f after being updated with %hhu", pi, i);
  }
  
  inline void handleIdle(float spent) {
    
    // Update idle energy
    if(idleCounter<MAX_COUNTER) idleCounter++;
    updatePI(TRUE); // update PI with idle state
    updatePR(FALSE);
    idleEnergy = ewma_counter(idleEnergy, spent, idleCounter);			
    
    // Handle pending transmission
    if(pending) {
      if(transmitCounter<MAX_COUNTER) transmitCounter++;
      if(pendingEnergy+idleEnergy>pendingFree*receiveEnergy) {
        transmitEnergy = ewma_counter(transmitEnergy, pendingEnergy+idleEnergy-pendingFree*receiveEnergy, transmitCounter);
      } else {
        transmitEnergy = ewma_counter(transmitEnergy, 0, transmitCounter);
      }
      debug("MoteStats,TRANSMIT_IDLE", "Transmit Idle with ET: %f, pending energy:, %f, pending free: %f\n", transmitEnergy, pendingEnergy, pendingFree);
      pending = FALSE;
    }

    debug("MoteStats,IDLE", "Idle with EI: %f and spent: %f\n", idleEnergy, spent);
    
  }
  
  inline void handleReceive(float spent) {
    uint8_t i;
    
    // Update receive energy
    for(i=0; i<receivedSinceLast; i++) { // TODO: this can be improved with formulas from jesus' mail sent May 7 2009
      if(receiveCounter<MAX_COUNTER) receiveCounter++;
      receiveEnergy = ewma_counter(receiveEnergy, spent/((float)receivedSinceLast), receiveCounter);
		}
    
    // Handle pending transmission
    if(pending) {
      if(transmitCounter<MAX_COUNTER) transmitCounter++;
      if(pendingEnergy>pendingFree*receiveEnergy) {
        transmitEnergy = ewma_counter(transmitEnergy, pendingEnergy-pendingFree*receiveEnergy, transmitCounter);
      } else {
        transmitEnergy = ewma_counter(transmitEnergy, 0, transmitCounter);
      }
      
      debug("MoteStats,TRANSMIT_RECEIVE", "Transmit Receive with ET: %f, pending energy:, %f, pending free: %f\n", transmitEnergy, pendingEnergy, pendingFree);            
      pending = FALSE;
    }
    
    debug("MoteStats,RECEIVE", "Receive with ER: %f, spent: %f, receive since last: %hhu\n", receiveEnergy, spent, receivedSinceLast);
  }
  
  inline void handleTransmit(float spent) {

    // We have a non-interering transmission
    if(wakeUpSinceLast==0) {
      
      // No free receptions
      if(receivedSinceLast==0) {
        if(transmitCounter<MAX_COUNTER) transmitCounter++;
        transmitEnergy = ewma_counter(transmitEnergy, spent, transmitCounter);
        debug("MoteStats,TRANSMIT", "Transmit BETWEEN with ET: %f, spent: %f, and nextPenalty: %f\n", transmitEnergy, spent, nextPenalty);
        
        // Free receptions 
      } else {
        if(pending) {
          debug("MoteStats,PENDING_CONCAT", "Concat Pending\n");
          pendingEnergy = (pendingEnergy+spent)/2;
          pendingFree = (pendingFree+receivedSinceLast)/2;
        } else {
          debug("MoteStats,PENDING_ADD", "Add Pending\n");
          pendingEnergy = spent;
          pendingFree = receivedSinceLast;
        }
        pending = TRUE;
      }
      
      // We have an overlapping transmission
    } else {
      
      if(pending) {
        // Transfer pending free reception to current wakeups.
        receivedSinceLast += pendingFree;
        
        // Handle pending as non-interfering transmission with no free receptions
        if(transmitCounter<MAX_COUNTER) transmitCounter++;
        transmitEnergy = ewma_counter(transmitEnergy, pendingEnergy, transmitCounter);
        
        debug("MoteStats,TRANSMIT_TRANSFER", "Transmit Transfer with ET: %f, pending energy: %f\n", transmitEnergy, pendingEnergy);
        
        pending = FALSE;
      }
      
      if(transmitCounter<MAX_COUNTER) transmitCounter++;
      
      // No free reception
      if(receivedSinceLast==0) {
        if(spent>idleEnergy*wakeUpSinceLast) {
          transmitEnergy = ewma_counter(transmitEnergy, spent-idleEnergy*wakeUpSinceLast, transmitCounter);
        } else {
          transmitEnergy = ewma_counter(transmitEnergy, 0, transmitCounter);
        }
        debug("MoteStats,TRANSMIT_OVERLAP_NOFREE", "Transmit Overlap NoFree with ET: %f, spent: %f, EI: %f, wakeUpSinceLast: %hhu\n", transmitEnergy, spent, idleEnergy, wakeUpSinceLast);
        
        // Free receptions
      } else {
        if(spent>receivedSinceLast*receiveEnergy) {
          transmitEnergy = ewma_counter(transmitEnergy, spent-receivedSinceLast*receiveEnergy, transmitCounter);
        } else {
          transmitEnergy = ewma_counter(transmitEnergy, 0, transmitCounter);
        }
        debug("MoteStats,TRANSMIT_OVERLAP_FREE", "Transmit Overlap Free with ET: %f, spent: %f, ER: %f, receivedSinceLast: %hhu\n", transmitEnergy, spent, receiveEnergy, receivedSinceLast);

      }
    }
    
  }
  
  float get_spent() {
    softenergy_charge_t energySpent;
    float spent;
    
    atomic {
      energySpent = lastEnergy - call SoftwareEnergy.used();
      lastEnergy = call SoftwareEnergy.used();
    }
    
    spent = energySpent/32768.0 - nextPenalty;
    if(spent<0.0) {
      spent = 0.0;
    }
    
    return spent;
  }
  
  command void LplInfo.recordTakeover() {
    
    if(nextState==S_RECEIVE || nextState==S_IDLE) {
      prevEnergy = get_spent();
      prevState = nextState;
      receivedSinceLast = wakeUpSinceLast = 0;
      nextPenalty = 0.0;
      nextState = S_UNKNOWN;
      debug("MoteStats,CANCEL", "Cancel with prevEnergy %f\n", prevEnergy);
    } else {
      call MoteStats.record();
    }
    
  }
  
  command void LplInfo.record() {
    float spent;
    
    float energyScaleFactor = 1.0;
    
    // first condition for when mote start, second for when it dies
    if(lastEnergy==0 || call SoftwareEnergy.used()==0) {
      lastEnergy = call SoftwareEnergy.used();
      return;
    }
    
    spent = get_spent() * energyScaleFactor;
	
    // idle event
    if(nextState==S_IDLE || (nextState==S_RECEIVE && receivedSinceLast==0)) {
      handleIdle(spent);
      prevState = S_IDLE;
      // receive event
    } else if(nextState==S_RECEIVE) {
      handleReceive(spent);		
      prevState = S_RECEIVE;
      // transmit event
    } else if(nextState==S_TRANSMIT) {
      handleTransmit(spent);
      prevState = S_TRANSMIT;
    } else {
      debug("MoteStats,UNKNOWN", "Unknown state with spent %f\n", spent);
    }
    
    prevEnergy = spent;
    receivedSinceLast = wakeUpSinceLast = 0;
    nextPenalty = 0.0;
    nextState = S_UNKNOWN;
  }
  
  command void LplInfo.nextReceive() {
    nextState = S_RECEIVE;
  }
  
  command void LplInfo.nextTransmit() {
    nextState = S_TRANSMIT;
  }
  
  command void LplInfo.nextTransmitTakeover() {
    if(prevState==S_IDLE || prevState==S_RECEIVE) {
      debug("MoteStats,CUTOFF", "Cutoff with prevState %hhu and nextPenalty %f\n", prevState, nextPenalty);
    }
	
    if(prevState==S_IDLE && idleEnergy>prevEnergy) {
      nextPenalty = idleEnergy - prevEnergy;
    } else if(prevState==S_RECEIVE && receiveEnergy>prevEnergy) {
      nextPenalty = receiveEnergy - prevEnergy;
    } else {
      nextPenalty = 0.0;
    }
    
    nextState = S_TRANSMIT;
  }
  
  command void LplInfo.nextIdle() {
    nextState = S_IDLE;
  }
  
  command void AppInfo.packetGenerated() {
    updatePI(FALSE); // update PI with active state
    updatePR(FALSE);
	
    /* Removed after introduction of PR
       if(receiveCounter<MAX_COUNTER) receiveCounter++;
       receiveEnergy = ewma_counter(receiveEnergy, PACKET_GENERATION_EST, receiveCounter);*/
    
    debug("MoteStats,GENERATED", "Packet Generated\n");
    //printf("GENERATED e:%lu, est:%lu\n", (uint32_t)(PACKET_GENERATION_EST*PRECISION), (uint32_t)(receiveEnergy*PRECISION));
  }
  
  command void LplInfo.received() {
    updatePI(FALSE); // update PI with active state
    updatePR(TRUE);
    receivedSinceLast++;
    debug("MoteStats,RECEIVED", "Packet Received\n");
  }
  
  command void LplInfo.wakeUp() {
    wakeUpSinceLast++;
  }
  
  command float MoteStats.getPI() {
    return (pi*100.0);
  }
  
  command float MoteStats.getPR() {
    return (pr*100.0);
  }
  
  command float MoteStats.getEI() {
    return idleCounter>=MATURE_COUNTER? idleEnergy : 0.0;
  }
  
  command float MoteStats.getET() {
    return transmitCounter>=MATURE_COUNTER ? transmitEnergy : 0.0;
  }
  
  command float MoteStats.getER() {
    return receiveCounter>=MATURE_COUNTER ? receiveEnergy : 0.0;
  }
  
  
}
