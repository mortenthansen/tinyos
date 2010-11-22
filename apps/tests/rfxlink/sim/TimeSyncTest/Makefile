COMPONENT=src/TimeSyncTestC
CFLAGS += -Isrc

##### CONFIG START #####

CFLAGS += -DPERIOD=1024
CFLAGS += -DSENDER=2

##### CONFIG END #####

BUILD_EXTRA_DEPS += 
CLEAN_EXTRA = simbuild build doc app.xml 

include $(MAKERULES)