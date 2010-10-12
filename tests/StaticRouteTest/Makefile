COMPONENT=src/StaticRouteTestC

CFLAGS += -Isrc

##### CONFIG START #####

CFLAGS += -DPERIOD=2048

##### CONFIG END #####

#CFLAGS += -I$(TOSDIR)/lib/softwareenergy

CFLAGS += -I$(TOSDIR)/lib/tinydebug
CFLAGS += -I$(TOSDIR)/lib/net/static

BUILD_EXTRA_DEPS += 

CLEAN_EXTRA = simbuild build doc app.xml 

include $(MAKERULES)