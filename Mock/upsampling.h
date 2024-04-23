#ifndef _UPSAMPLING_H
#define _UPSAMPLING_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* fraction bits, max is 22*/
#define FRACTION_BITS (16)

typedef struct Pixel {
  uint8_t blue;
  uint8_t green;
  uint8_t red;
} Pixel;

int initWeights_540p4k(float fA);
int upsampling_540p4k(Pixel *pSrc, Pixel *pDst);
int upsamplingParallel_540p4k(Pixel *pSrc, Pixel *pDst);

#ifdef __cplusplus
}
#endif

#endif
