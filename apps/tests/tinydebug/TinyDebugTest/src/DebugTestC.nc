
configuration DebugTestC {

} implementation {

	components
		DebugTestP,
		MainC,
		new TimerMilliC(),
		ActiveMessageC,
		SerialActiveMessageC;

	DebugTestP.RadioControl -> ActiveMessageC;
	DebugTestP.SerialControl -> SerialActiveMessageC;
	DebugTestP.Boot -> MainC;
	DebugTestP.Timer -> TimerMilliC;

	components DebugC;

}
