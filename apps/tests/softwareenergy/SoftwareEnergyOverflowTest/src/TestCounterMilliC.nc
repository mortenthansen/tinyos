generic module TestCounterMilliC(uint32_t maxTime) {

	provides {
		interface Counter<TMilli,uint32_t>;
	}

	uses {
		interface Boot;
		interface Timer<TMilli>;
	}

} implementation {

	bool ignoreOverflow = FALSE;

	event void Boot.booted() {
		call Timer.startPeriodic(maxTime);
	}

	async command uint32_t Counter.get() {
		uint32_t c;
		atomic c = call Timer.getNow();
		return c % maxTime;
	}

  async command bool Counter.isOverflowPending() {
		return FALSE;
	}

  async command void Counter.clearOverflow() {
		if(call Timer.getNow()==maxTime) {
			ignoreOverflow = TRUE;
		}
	}

	event void Timer.fired() {
		if(!ignoreOverflow) {
			signal Counter.overflow();
		}
		ignoreOverflow = FALSE;
	}

}
