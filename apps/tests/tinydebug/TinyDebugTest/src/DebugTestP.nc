//#include "printf.h"
#include "Debug.h"
#include "printf.h"

module DebugTestP {

	uses {
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
		interface Boot;
		interface Timer<TMilli>;
	}

} implementation {

	event void Boot.booted() {
		call RadioControl.start();
		call SerialControl.start();
		call Timer.startPeriodic(1024);
	}

	event void RadioControl.startDone(error_t error) {}
	event void RadioControl.stopDone(error_t error) {}
	event void SerialControl.startDone(error_t error) {}
	event void SerialControl.stopDone(error_t error) {}

	event void Timer.fired() {
		int8_t int8 = -2;
		uint8_t uint8 = 3;
		uint8_t hex8 = 0xFF;
		int16_t int16 = -200;
		uint16_t uint16 = 300;
		uint16_t hex16 = 0xFFFF;
		int32_t int32 = -40000L;
		uint32_t uint32 = 70000UL;
		uint32_t hex32 = 0xFFFFFFFF;
		int64_t int64 = -2500000LL;
		uint64_t uint64 = 5000000ULL;

		float f = 2.4;
		//dbg("App", "time is %lu and size %hhu\n", call Timer.getNow(),sizeof(int));
		
		debug("App,DEBUG_MORTEN", "MORTEN %hhi %hhu %hhx %hi %hu %hx %li %lu %lx %f %hhu\n", int8, uint8, hex8, int16, (uint16_t)uint16, hex16, int32, uint32, hex32, f, uint8);
        
		debug("App,ONE_PACKET", "MORTEN %hhi %hhu %hhx %hi %hu %hx %li %lu %lx\n", int8, uint8, hex8, int16, (uint16_t)uint16, hex16, int32, uint32, hex32);
		//debug("ONE_PACKET_AND_ONE", "MORTEN %hhi %hhu %hhx %hi %hu %hx %li %lu %lx %hhu\n", int8, uint8, hex8, int16, (uint16_t)uint16, hex16, int32, uint32, hex32, uint8);
		//debug("THREE_PACKETS", "THREE %hhi %hhu %hhx %hi %hu %hx %li %lu %lx %hhu %hhi %hhu %hhx %hi %hu %hx %li %lu %lx %hhu\n", int8, uint8, hex8, int16, (uint16_t)uint16, hex16, int32, uint32, hex32, uint8, int8, uint8, hex8, int16, (uint16_t)uint16, hex16, int32, uint32, hex32, uint8);

		//debug("SHORT","%hhx\n", 0xFF);

		debug("App,BATTERY", "cool %% text with numbers %lli %llu %f %hhu\n", int64, uint64, 4.5f, uint8);

        debug("App,FIRED", "fired now %lu\n", call Timer.getNow());

        debug("App,FILTER", "---- filter this\n");
        debug("App,IGNORE", "---- ignore this\n");

        debug("App2,SUPER", "---- APP2\n");

	}
	

}
