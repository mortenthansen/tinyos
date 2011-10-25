
module BlockTestP @safe() {

  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;

    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    interface BlockSend;
    interface BlockReceive;
    interface PacketAcknowledgements as Acks;
    interface NeighborTable;

    interface TimeMeasure<uint32_t>;
  }

} implementation {

  message_t messageBuffer[BUFFER_SIZE];
  message_t* ONE_NOK messages[BUFFER_SIZE];

  /********** Init **********/

  event void Boot.booted() {
    uint8_t i;
    dbg("BlockTest.debug", "%i: booted\n", TOS_NODE_ID);
    for(i=0; i<BUFFER_SIZE; i++) {
      messages[i] = &messageBuffer[i];
    }
    call SerialControl.start();
    call RadioControl.start();
    call NeighborTable.insert(TOS_NODE_ID+1);
    call NeighborTable.insert(TOS_NODE_ID-1);
  }

  event void SerialControl.startDone(error_t error) {
    if(error!=SUCCESS) {
      call SerialControl.start();
    }
  }

  event void SerialControl.stopDone(error_t error) {

  }

  event void RadioControl.startDone(error_t error) {
    if(error==SUCCESS) {
      if(TOS_NODE_ID!=RECEIVER) {
        call Timer.startPeriodic(PERIOD);
      }
    } else {
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t error) {

  }

  /********** Send **********/

  event void Timer.fired() {
    if(call BlockSend.send(RECEIVER, messages, BUFFER_SIZE, sizeof(blocktest_msg_t))!=SUCCESS) {
      dbgerror("BlockTest.error", "Failed to send block..\n");
      call Leds.led0Toggle();
    } else {
      dbg("BlockTest.debug", "Sending..\n");
      call TimeMeasure.start();
    }
  }

  event void BlockSend.sendDone(message_t** msgs, uint8_t size, error_t error) {
    uint8_t i;

    call TimeMeasure.stop();

    if(error==SUCCESS) {
      dbg("BlockTest.debug", "Send success\n");
      call Leds.led1Toggle();
    } else {
      dbg("BlockTest.debug", "Send failed\n");
      call Leds.led0Toggle();
    }

    dbg("BlockTest.debug", "%hhu: ", TOS_NODE_ID);

    for(i=0; i<BUFFER_SIZE; i++) {
      dbg_clear("BlockTest.debug", "%hhu", call Acks.wasAcked(messages[i]));
    }

    dbg_clear("BlockTest.debug", ", time=%lu, quick=%lu\n", call TimeMeasure.get(), time_get());

  }

  /********** Receive **********/

  event void BlockReceive.receive(message_t** ONE msgs, uint8_t size, uint8_t len) {
    call Leds.led2Toggle();
    call BlockReceive.receiveDone(msgs, size);
  }

  /********** NeighborTable **********/

  event void NeighborTable.evicted(am_addr_t addr) {

  }

  }
