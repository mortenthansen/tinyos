#ifndef SELECTIVE_H
#define SELECTIVE_H


/*#ifdef SELECTIVE_USE_FIXED
#warning "***** Selective Using Fixed Threshold *****"
#else
#ifndef SELECTIVE_FIXED_THRESHOLD
#define SELECTIVE_FIXED_THRESHOLD 0
#endif
#endif*/

typedef uint8_t selective_importance_t;
typedef nx_uint8_t nx_selective_importance_t;

typedef nx_struct selective_header {
	nx_selective_importance_t importance;
} selective_header_t;

#endif
