#ifndef _INOUT_H
#define _INOUT_H

#ifdef __cplusplus
extern "C" {
#endif

#include "upsampling.h"

typedef struct __attribute__((packed)) BITMAPFILEHEADER {
  uint16_t bfType;
  uint32_t bfSize;
  uint16_t bfReserved1;
  uint16_t bfReserved2;
  uint32_t bfOffBits;
} BITMAPFILEHEADER;

typedef struct __attribute__((packed)) BITMAPINFOHEADER {
  uint32_t biSize;
  uint32_t biWidth;
  uint32_t biHeight;
  uint16_t biPlanes;
  uint16_t biBitCount;
  uint32_t biCompression;
  uint32_t biSizeImage;
  uint32_t biXPelsPerMeter;
  uint32_t biYPelsPerMeter;
  uint32_t biClrUsed;
  uint32_t biClrImportant;
} BITMAPINFOHEADER;

int readSinglePicture_540p(char *fullName, Pixel *pData);
int writeSinglePicture_4k(char *fullName, Pixel *pData);

char **getPictureLists(char *path, int *nCnt);

#ifdef __cplusplus
}
#endif
#endif
