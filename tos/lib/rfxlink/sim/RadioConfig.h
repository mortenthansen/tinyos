#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#ifndef TASKLET_IS_TASK
#define TASKLET_IS_TASK
#endif

#include <Timer.h>

typedef TMicro TRadio;
typedef uint16_t tradio_size;

#define RADIO_ALARM_MICROSEC (1024ULL*1024ULL) / (1000ULL*1000ULL)

#define RADIO_ALARM_MILLI_EXP 10

// RADIO_ALARM_BYTE = 8 * RADIO_ALARM_SEC / (BITS_PER_SYMBOL * SYMBOLS_PER_SEC) = 8 * 1024*1024 / (4 * 65536)
#define RADIO_ALARM_BYTE 32 

#endif
