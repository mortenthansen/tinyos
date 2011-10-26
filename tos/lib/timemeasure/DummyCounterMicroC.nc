module DummyCounterMicroC {

	provides {
		interface Counter<TMicro,uint16_t>;
	}

} implementation {

	async command uint16_t Counter.get() {
    return 0;
  }
	
  async command bool Counter.isOverflowPending() {
		return FALSE;
  }

  async command void Counter.clearOverflow() {
		
  }

}
