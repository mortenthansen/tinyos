#include "SoftwareEnergy.h"
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

  enum state_enums {
    S_OFF,
    S_IDLE,
    S_RECEIVE,
    S_TRANSMIT,
    S_GENERATED,
  };

  enum config_enums {
    INIT_COUNTER = 0,
    MAX_COUNTER = 100,
    MATURE_COUNTER = 1, // set to 1 to disable
    PACKET_GENERATION_EST = 0, // according to jesus mail 22 may 2009.
  };
  
  uint8_t state;
  softenergy_charge_t lastEnergy;
  
  uint8_t idleCounter, transmitCounter, receiveCounter, piCounter, prCounter;
  
  float transmitEnergy, idleEnergy, receiveEnergy, pi, pr;
  
  uint8_t receivedSinceLast, wakeUpSinceLast;
  
  bool pending;
  float pendingEnergy;
  uint8_t pendingFree;	
  
  float nextPenalty;

  void recordState();
  void updatePI(bool i);
  void updatePR(bool r);
  float get_spent();
  float ewma_counter(float oldValue, float newValue, uint32_t counter);

  /***************** Init ****************/  

  command error_t Init.init() {
    state = S_OFF;
    lastEnergy = 0;
    
    idleCounter = transmitCounter = receiveCounter = piCounter = prCounter = INIT_COUNTER;
    transmitEnergy = idleEnergy = receiveEnergy = pi = pr = 0.0;
    
    receivedSinceLast = wakeUpSinceLast = 0;
    
    pending = FALSE;
    pendingEnergy = 0.0;
    pendingFree = 0;
    
    nextPenalty = 0.0;
    
    return SUCCESS;
  }

  /***************** LplInfo ****************/
  
  event void LplInfo.transmit() {

    if(state!=S_OFF) {

      if(state==S_RECEIVE || state==S_IDLE) {
        float spent = get_spent();
        
        if(state==S_IDLE && idleEnergy>spent) {
          nextPenalty = idleEnergy - spent;
        } else if(state==S_RECEIVE && receiveEnergy>spent) {
          nextPenalty = receiveEnergy - spent;
        } else {
          nextPenalty = 0.0;
        }

        receivedSinceLast = wakeUpSinceLast = 0;
        state = S_OFF;

        debug("MoteStats,CANCEL", "Cancel with spent %f\n", spent);

      } else {
        recordState();
      }
      
      debug("MotesStats,NEXT", "Next TRANSMIT TAKEOVER\n");

    } else {
      debug("MotesStats,NEXT", "Next TRANSMIT\n");
    }

    state = S_TRANSMIT;

  }

  
  event void LplInfo.radioOff() {
    recordState();
  }
  
  event void LplInfo.energyDetected() {
    debug("MotesStats,NEXT", "Next RECEIVE\n");
    state = S_RECEIVE;
  }
    
  
  event void LplInfo.received() {
    updatePI(FALSE); // update PI with active state
    updatePR(TRUE);
    receivedSinceLast++;
    debug("MoteStats,RECEIVED", "Packet Received\n");
  }
  
  event void LplInfo.wakeUp() {
    wakeUpSinceLast++;
    if(state==S_OFF) {
      state = S_IDLE;
    }
  }

  /***************** AppInfo ****************/
  
  event void AppInfo.generated() {
    updatePI(FALSE); // update PI with active state
    updatePR(FALSE);
    debug("MoteStats,GENERATED", "Packet Generated\n");
  }

  /***************** MoteStats ****************/
  
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

  /***************** Functions ****************/
  
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

  void recordState() {
    float spent;
    
    float energyScaleFactor = 1.0;
    
    // first condition for when mote start, second for when it dies
    if(lastEnergy==0 || call SoftwareEnergy.used()==0) {
      lastEnergy = call SoftwareEnergy.used();
      debug("MoteStats,IGNORE","Ignore state!\n");
      return;
    }
    
    spent = get_spent() * energyScaleFactor;

    // idle event  
    if(state==S_IDLE || (state==S_RECEIVE && receivedSinceLast==0)) {
      handleIdle(spent);
    // receive event  
    } else if(state==S_RECEIVE && receivedSinceLast!=0) {
      handleReceive(spent);		
    // transmit event
    } else if(state==S_TRANSMIT) {
      handleTransmit(spent);
    } else {
      debug("MoteStats,OFF_STATE", "ERROR: Radio off when it was already in S_OFF state");
    }

    receivedSinceLast = wakeUpSinceLast = 0;
    nextPenalty = 0.0;
    state = S_OFF;
  }

  void updatePI(bool i) {
    if(piCounter<100) piCounter++;
    pi = ewma_counter(pi, i, piCounter);
    debug("MoteStats,PI","PI is %f after being updated with %hhu\n", pi, i);
  }
  
  void updatePR(bool r) {
    if(prCounter<100) prCounter++;
    pr = ewma_counter(pr, r, prCounter);
    debug("MoteStats,PR","PR is %f after being updated with %hhu\n", pr, r);
  }
  
  float get_spent() {
    softenergy_charge_t energySpent;
    float spent;
    
    atomic {
      energySpent = call SoftwareEnergy.used() - lastEnergy;
      lastEnergy = call SoftwareEnergy.used();
    }
    
    spent = energySpent/32768.0 - nextPenalty;
    if(spent<0.0) {
      spent = 0.0;
    }
    
    return spent;
  }
  
  float ewma_counter(float oldValue, float newValue, uint32_t counter) {
	if(counter<2) {
      return newValue;
	} else {
		float gain = 1.0-1.0/((float)counter);
		return gain * oldValue + (1.0-gain) * newValue;
	}
  }

  
}
