#define _GNU_SOURCE
#include "upsampling.h"

#include <assert.h>
#include <math.h>
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysinfo.h>

typedef struct ThreadArg {
  int nStartRow;
  int nRows;
  Pixel *pSrc;
  Pixel *pDst;
} ThreadArg;

/* weights at 0, 1/4, 2/4, 3/4, ..., 8/4
 *  format: Q2.N
 */
int64_t nWeightsMat[16 * 16];

int mirrorPadding(Pixel *pSrc, Pixel *pDst, uint32_t nWidth, uint32_t nHeight);

int upsampling_540p4k(Pixel *pSrc, Pixel *pDst) {
  if (!pSrc || !pDst) {
    return -1;
  }

  int i, j, k, m, n, nSrcX, nSrcY;
  Pixel *pDstLine = pDst;
  int64_t *pWeight;
  Pixel block[16];
  int64_t nBlu, nGrn, nRed;

  Pixel *pPaddedSrc = malloc(sizeof(Pixel) * 963 * 543);
  assert(pPaddedSrc != NULL);

  mirrorPadding(pSrc, pPaddedSrc, 960, 540);

  for (nSrcY = 0; nSrcY < 540; ++nSrcY) {
    // every 1 pixel in src map to 16 pixel in dst, calc 4 rows separately
    for (i = 0; i < 4; ++i) {
      pWeight = nWeightsMat + i * 16 * 4;

      for (nSrcX = 0; nSrcX < 960; ++nSrcX) {
        // every 4 pixel in dst has same source block, determine it
        for (m = 0; m < 4; ++m) {
          for (n = 0; n < 4; ++n) {
            block[m * 4 + n] = pPaddedSrc[(nSrcY + m) * 963 + nSrcX + n];
          }
        }

        // loop over 4 cols
        for (j = 0; j < 4; ++j) {
          nBlu = 0;
          nGrn = 0;
          nRed = 0;
          for (k = 0; k < 16; ++k) {
            nBlu += block[k].blue * pWeight[j * 16 + k];
            nGrn += block[k].green * pWeight[j * 16 + k];
            nRed += block[k].red * pWeight[j * 16 + k];
          }
          // 四舍五入
          nBlu = (nBlu + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;
          nGrn = (nGrn + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;
          nRed = (nRed + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;

          if (nBlu > 255) nBlu = 255;
          if (nBlu < 0) nBlu = 0;
          if (nGrn > 255) nGrn = 255;
          if (nGrn < 0) nGrn = 0;
          if (nRed > 255) nRed = 255;
          if (nRed < 0) nRed = 0;

          pDstLine[nSrcX * 4 + j].blue = nBlu;
          pDstLine[nSrcX * 4 + j].green = nGrn;
          pDstLine[nSrcX * 4 + j].red = nRed;
        }
      }
      pDstLine = pDstLine + 3840;
    }
  }

  free(pPaddedSrc);
  pPaddedSrc = NULL;

  return 0;
}

void *upsamplingPartial(void *pArg) {
  ThreadArg *pThArg = pArg;
  int i, j, k, m, n, nSrcX, nSrcY;
  int64_t *pWeight;
  Pixel block[16];
  int64_t nBlu, nGrn, nRed;
  Pixel *pPaddedSrc = pThArg->pSrc;
  int nStartRow = pThArg->nStartRow;
  int nEndRow = pThArg->nStartRow + pThArg->nRows;
  Pixel *pDstLine = pThArg->pDst + nStartRow * 3840 * 4;

  for (nSrcY = nStartRow; nSrcY < nEndRow; ++nSrcY) {
    // every 1 pixel in src map to 16 pixel in dst, calc 4 rows separately
    for (i = 0; i < 4; ++i) {
      pWeight = nWeightsMat + i * 16 * 4;

      for (nSrcX = 0; nSrcX < 960; ++nSrcX) {
        // every 4 pixel in dst has same source block, determine it
        for (m = 0; m < 4; ++m) {
          for (n = 0; n < 4; ++n) {
            block[m * 4 + n] = pPaddedSrc[(nSrcY + m) * 963 + nSrcX + n];
          }
        }

        // loop over 4 cols
        for (j = 0; j < 4; ++j) {
          nBlu = 0;
          nGrn = 0;
          nRed = 0;
          for (k = 0; k < 16; ++k) {
            nBlu += block[k].blue * pWeight[j * 16 + k];
            nGrn += block[k].green * pWeight[j * 16 + k];
            nRed += block[k].red * pWeight[j * 16 + k];
          }
          nBlu = (nBlu + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;
          nGrn = (nGrn + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;
          nRed = (nRed + (1 << (FRACTION_BITS - 1))) >> FRACTION_BITS;

          if (nBlu > 255) nBlu = 255;
          if (nBlu < 0) nBlu = 0;
          if (nGrn > 255) nGrn = 255;
          if (nGrn < 0) nGrn = 0;
          if (nRed > 255) nRed = 255;
          if (nRed < 0) nRed = 0;

          pDstLine[nSrcX * 4 + j].blue = nBlu;
          pDstLine[nSrcX * 4 + j].green = nGrn;
          pDstLine[nSrcX * 4 + j].red = nRed;
        }
      }
      pDstLine = pDstLine + 3840;
    }
  }
}

int upsamplingParallel_540p4k(Pixel *pSrc, Pixel *pDst) {
  int i, rowStride;
  int nCores;
  pthread_t thread_id[15];
  ThreadArg thraedArgs[15];
  cpu_set_t cpuset[15];
  Pixel *pPaddedSrc = NULL;

  if (!pSrc || !pDst) {
    return -1;
  }

  nCores = get_nprocs();
  if (nCores >= 15) {
    nCores = 15;
  } else if (nCores >= 12) {
    nCores = 12;
  } else if (nCores >= 9) {
    nCores = 9;
  } else if (nCores >= 6) {
    nCores = 6;
  } else if (nCores >= 4) {
    nCores = 4;
  }
  rowStride = 540 / nCores;

  pPaddedSrc = malloc(sizeof(Pixel) * 963 * 543);
  assert(pPaddedSrc != NULL);

  mirrorPadding(pSrc, pPaddedSrc, 960, 540);

  for (i = 0; i < nCores; ++i) {
    thraedArgs[i].nStartRow = rowStride * i;
    thraedArgs[i].nRows = rowStride;
    thraedArgs[i].pSrc = pPaddedSrc;
    thraedArgs[i].pDst = pDst;
    pthread_create(&(thread_id[i]), NULL, upsamplingPartial, &(thraedArgs[i]));
    CPU_ZERO(&cpuset[i]);
    CPU_SET(i, &cpuset[i]);
    pthread_setaffinity_np(thread_id[i], sizeof(cpuset[i]), &cpuset[i]);
  }

  for (i = 0; i < nCores; ++i) {
    pthread_join(thread_id[i], NULL);
  }

  free(pPaddedSrc);
  pPaddedSrc = NULL;

  return 0;
}

int initWeights_540p4k(float fA) {
  int i, j, m, n, k, p;
  int ind1, ind2;
  int64_t nWeights[9];
  static int initDone = 0;

  if (initDone) {
    return 0;
  }
  if (fA < -1.0 || fA > 0) {
    return -1;
  }

  int32_t nA1, nB1, nA2, nB2, nC2, nD2;
  int32_t nS1, nS2, nS3;

  nA1 = (1 << FRACTION_BITS) * (fA + 2);
  nB1 = (1 << FRACTION_BITS) * (-fA - 3);
  nA2 = (1 << FRACTION_BITS) * fA;
  nB2 = (1 << FRACTION_BITS) * (-5 * fA);
  nC2 = (1 << FRACTION_BITS) * (8 * fA);
  nD2 = (1 << FRACTION_BITS) * (-4 * fA);

  for (i = 0; i < 9; ++i) {
    if (i == 0) {
      nWeights[i] = 1 << FRACTION_BITS;
    } else if (i == 4 || i == 8) {
      nWeights[i] = 0;
    } else {
      nS1 = (1 << (FRACTION_BITS - 2)) * i;
      nS2 = (1 << (FRACTION_BITS - 4)) * i * i;
      nS3 = (1 << (FRACTION_BITS - 6)) * i * i * i;

      if (i < 4) {
        nWeights[i] = (((int64_t)nA1 * nS3) >> FRACTION_BITS) + (((int64_t)nB1 * nS2) >> FRACTION_BITS) + (1 << FRACTION_BITS);
      } else {
        nWeights[i] =
            (((int64_t)nA2 * nS3) >> FRACTION_BITS) + (((int64_t)nB2 * nS2) >> FRACTION_BITS) + (((int64_t)nC2 * nS1) >> FRACTION_BITS) + nD2;
      }
    }
  }

  k = 0;

  for (m = 0; m < 4; ++m) {
    for (n = 0; n < 4; ++n) {
      p = 0;
      for (i = 0; i < 16; i += 4) {
        for (j = 0; j < 16; j += 4) {
          ind1 = abs(m + 4 - i);
          ind2 = abs(n + 4 - j);
          nWeightsMat[k * 16 + p] = (nWeights[ind1] * nWeights[ind2]) >> FRACTION_BITS;
          // printf("%ld\t", nWeightsMat[k * 16 + p]);
          ++p;
        }
      }
      // printf("\n");
      ++k;
    }
  }

  initDone = 1;
  return 0;
}

/* NOTE:
 * This function will add 3 rows and 3 cols surrounding original
 * pixel, the space pointed by pDstData should has enouph space
 * Expand mode:
 *
 *     x x x x x x x x x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x o o o o o o o x x
 *     x x x x x x x x x x
 *     x x x x x x x x x x
 *
 *  x is added pixels surrouding original pixel
 */
int mirrorPadding(Pixel *pSrc, Pixel *pDst, uint32_t nWidth, uint32_t nHeight) {
  if (!pSrc || !pDst) {
    return -1;
  }

  int i;
  Pixel *pSrcLine, *pDstLine;
  uint32_t nNewWidth = nWidth + 3;
  uint32_t nNewHeight = nHeight + 3;

  // the first line
  pDst[0] = pSrc[nWidth + 1];
  memcpy(pDst + 1, pSrc + nWidth, sizeof(Pixel) * nWidth);
  pDst[nWidth + 1] = pDst[nWidth - 1];
  pDst[nWidth + 2] = pDst[nWidth - 2];

  // the second line to the last but two line
  for (i = 1; i < nHeight + 1; ++i) {
    pSrcLine = pSrc + nWidth * (i - 1);
    pDstLine = pDst + nNewWidth * i;
    pDstLine[0] = pSrcLine[1];
    memcpy(pDstLine + 1, pSrcLine, sizeof(Pixel) * nWidth);
    pDstLine[nWidth + 1] = pDstLine[nWidth - 1];
    pDstLine[nWidth + 2] = pDstLine[nWidth - 2];
  }

  // the last two line
  memcpy(pDst + nNewWidth * (nNewHeight - 2), pDst + nNewWidth * (nNewHeight - 4), sizeof(Pixel) * nNewWidth);
  memcpy(pDst + nNewWidth * (nNewHeight - 1), pDst + nNewWidth * (nNewHeight - 5), sizeof(Pixel) * nNewWidth);

  return 0;
}
