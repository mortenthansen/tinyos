COMPONENT=src/SoftwareEnergyComponentTestC

CFLAGS += -Isrc

##### Config #####

CFLAGS += -DPERIOD=1024
CFLAGS += -DRECEIVER=2

CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=51
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=51

CFLAGS += -DSOFTWAREENERGY

##### End #####

CFLAGS += -I${TOSDIR}/lib/softwareenergy

BUILD_EXTRA_DEPS += 
CLEAN_EXTRA = simbuild build doc app.xml 

include $(MAKERULES)