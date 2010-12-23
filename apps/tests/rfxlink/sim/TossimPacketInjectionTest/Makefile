COMPONENT=src/InjectionTestC

CFLAGS += -Isrc

BUILD_EXTRA_DEPS += InjectionMsg.py
CLEAN_EXTRA = simbuild build doc app.xml InjectionMsg.py *.pyc

InjectionMsg.py:
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=InjectionMsg src/InjectionTest.h injectiontest_msg -o $@

include $(MAKERULES)