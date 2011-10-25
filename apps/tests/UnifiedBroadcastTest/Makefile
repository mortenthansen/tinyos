COMPONENT=src/UnifiedBroadcastAppC

CFLAGS += -Isrc

##### Config #####

#CFLAGS += -DSENDER=9
#CFLAGS += -DSENDER=3
CFLAGS += -DSENDER=0
CFLAGS += -DUB_NO_TIMESTAMP
CFLAGS += -DUNIFIED_BROADCAST

#CFLAGS += -DTINYOS_6LOWPAN_NETWORK_ID=0x3a

#CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=200
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=200
CFLAGS += -DLPL_INTERVAL=200 #for FTSP

##### End #####

#CFLAGS += -DPRINTF_BUFFER_SIZE=1000
#CFLAGS += -I$(TOSDIR)/lib/printf
# if print should be disabled
#CFLAGS += -I$(TOSCONTRIB)/csau/misc/tos/types

#CFLAGS += -I$(TOSCONTRIB)/csau/misc/tos/lib/tossim
#CFLAGS += -I$(TOSDIR)/chips/cc2420/link
#CFLAGS += -I$(TOSDIR)/chips/cc2420/unique
#CFLAGS += -I$(TOSDIR)/chips/cc2420/lpl
#CFLAGS += -I$(TOSDIR)/chips/cc2420/interfaces

#CFLAGS += $(TOSEXTDIR)/lib/net/ub/UnifiedBroadcast.c 

CFLAGS += -I$(TOSDIR)/lib/ub

CFLAGS += -DDEBUG
CFLAGS += -DDEBUG_AUTO_FLUSH

BUILD_EXTRA_DEPS += 
CLEAN_EXTRA = simbuild build doc app.xml 

include $(MAKERULES)

