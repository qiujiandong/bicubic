#include "inout.h"

#include <dirent.h>
#include <pthread.h>
#include <sys/types.h>

#include "main.h"

const BITMAPFILEHEADER dstHead = {.bfType = 19778, .bfSize = 24883254, .bfReserved1 = 0, .bfReserved2 = 0, .bfOffBits = 54};

const BITMAPINFOHEADER dstInfo = {.biSize = 40,
                                  .biWidth = 3840,
                                  .biHeight = 2160,
                                  .biPlanes = 1,
                                  .biBitCount = 24,
                                  .biCompression = 0,
                                  .biSizeImage = 24883200,
                                  .biXPelsPerMeter = 2834,
                                  .biYPelsPerMeter = 2834,
                                  .biClrUsed = 0,
                                  .biClrImportant = 0};

int readSinglePicture_540p(char *fullName, Pixel *pData) {
  if (!fullName || !pData) {
    return -1;
  }

  int i;
  size_t nNum;
  FILE *fp = fopen(fullName, "rb");
  if (fp == NULL) {
    return -1;
  }

  BITMAPFILEHEADER head;
  memset(&head, 0, sizeof(head));
  BITMAPINFOHEADER info;
  memset(&info, 0, sizeof(info));

  nNum = fread(&head, 1, sizeof(BITMAPFILEHEADER), fp);
  assert(nNum == sizeof(BITMAPFILEHEADER));
  nNum = fread(&info, 1, sizeof(BITMAPINFOHEADER), fp);
  assert(nNum == sizeof(BITMAPINFOHEADER));

  assert(info.biWidth == SRC_WIDTH);
  assert(info.biHeight == SRC_HEIGHT);

  fseek(fp, head.bfOffBits, SEEK_SET);
  for (i = info.biHeight - 1; i >= 0; --i) {
    nNum = fread(pData + i * info.biWidth, sizeof(Pixel), info.biWidth, fp);
    assert(nNum == info.biWidth);
  }

  fclose(fp);
  return 0;
}

// writeSinglePicture_4k only support 4k picture
int writeSinglePicture_4k(char *fullName, Pixel *pData) {
  if (!fullName || !pData) {
    return -1;
  }

  int i;
  FILE *fp = fopen(fullName, "wb");
  if (fp == NULL) {
    return -1;
  }

  Pixel *pRealloc = (Pixel *)malloc(sizeof(Pixel) * dstInfo.biWidth * dstInfo.biHeight);
  assert(pRealloc != NULL);

  memcpy(pRealloc, pData + dstInfo.biWidth * (dstInfo.biHeight - 1) - 1, sizeof(Pixel) * (dstInfo.biWidth + 1));
  memcpy(pRealloc + dstInfo.biWidth + 1, pData, sizeof(Pixel) * (dstInfo.biWidth * (dstInfo.biHeight - 1) - 1));

  fwrite(&dstHead, 1, sizeof(BITMAPFILEHEADER), fp);
  fwrite(&dstInfo, 1, sizeof(BITMAPINFOHEADER), fp);

  for (i = dstInfo.biHeight - 1; i >= 0; --i) {
    fwrite(pRealloc + i * dstInfo.biWidth, sizeof(Pixel), dstInfo.biWidth, fp);
  }

  fclose(fp);

  free(pRealloc);
  pRealloc = NULL;
  return 0;
}

char **getPictureLists(char *path, int *pCnt) {
  DIR *pDir = opendir(path);
  struct dirent *pEntry = NULL;
  *pCnt = 0;
  char **pNameLists;
  int i;
  int nLen;

  if (!pDir) {
    printf("Open dir failed\n");
    return NULL;
  }
  while (pEntry = readdir(pDir)) {
    if (pEntry->d_type == DT_REG) {
      ++(*pCnt);
    }
  }

  pNameLists = (char **)malloc(sizeof(char *) * *(pCnt));
  assert(pNameLists != NULL);

  seekdir(pDir, 0);
  while (pEntry = readdir(pDir)) {
    if (pEntry->d_type == DT_REG) {
      pNameLists[i] = (char *)malloc(sizeof(char) * (strlen(pEntry->d_name) + 1));
      assert(pNameLists[i] != NULL);
      strcpy(pNameLists[i], pEntry->d_name);
      ++i;
    }
  }

  return pNameLists;
}
