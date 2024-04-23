#include "main.h"

#include "inout.h"
#include "upsampling.h"

int main(int argc, char *argv[]) {
  char *pSrcFile = NULL;
  char *pDstFile = NULL;
  char *pSrcDir = NULL;
  char *pDstDir = NULL;
  bool bParallel = false;
  int i, nCnt;
  Pixel *pSrcData = NULL;
  Pixel *pDstData = NULL;
  char **pSrcFiles = NULL;
  char **pDstFiles = NULL;
  char **pPictureLists = NULL;
  // int nTimes, nRemain, nBufSz;
  // int nCores;

  /* get input parameters */
  if (argc == 1) {
    printf("Missing argument, use \"-h\" or \"--help\" to get help\n");
    return -1;
  } else if (argc == 2) {
    if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
      printf("Options\t\t\tFunction\n");
      printf("-h, --help\t\tget help information\n");
      printf("-p\t\t\trun parallelly\n");
      printf("-f <source>\t\tspecify the single input picture\n");
      printf("-o <result>\t\tspecify the single output picture\n");
      printf("-src <source directory>\tspecify the input pictures location\n");
      printf("-dst <result directory>\tspecify the output pictures location\n");
      printf("Note: \"-f\" and \"-o\" should showup together, \"-src\" and \"-dst\" as well\n");
      return 0;
    } else {
      printf("Wrong argument!\n");
      return -1;
    }
  } else {
    for (i = 1; i < argc; ++i) {
      if (!strcmp("-p", argv[i])) {
        bParallel = true;
      } else if (!strcmp("-f", argv[i])) {
        pSrcFile = argv[++i];
      } else if (!strcmp("-o", argv[i])) {
        pDstFile = argv[++i];
      } else if (!strcmp("-src", argv[i])) {
        pSrcDir = argv[++i];
      } else if (!strcmp("-dst", argv[i])) {
        pDstDir = argv[++i];
      } else {
        printf("Wrong argument!\n");
        return -1;
      }
    }
  }

  /* init weights */
  initWeights_540p4k(-0.5);
  /* single picture processing */
  if (pSrcFile && pDstFile && !pSrcDir && !pDstDir) {
    /* allocate sourcee data */
    pSrcData = (Pixel *)malloc(sizeof(Pixel) * SRC_WIDTH * SRC_HEIGHT);
    if (!pSrcData) {
      printf("Allocate source data failed\n");
      return -1;
    }
    memset(pSrcData, 0, sizeof(Pixel) * SRC_WIDTH * SRC_HEIGHT);

    /* allocate result data */
    pDstData = (Pixel *)malloc(sizeof(Pixel) * DST_WIDTH * DST_HEIGHT);
    if (!pDstData) {
      printf("Allocate destination data failed\n");
      return -1;
    }
    memset(pDstData, 0, sizeof(Pixel) * DST_WIDTH * DST_HEIGHT);

    readSinglePicture_540p(pSrcFile, pSrcData);
    /* processing */
    if (bParallel) {
      upsamplingParallel_540p4k(pSrcData, pDstData);
      printf("Single picture parallel processing finished!\n");
    } else {
      upsampling_540p4k(pSrcData, pDstData);
      printf("Single picture processing finished!\n");
    }
    writeSinglePicture_4k(pDstFile, pDstData);

  }
  /* multi-pictures processing */
  else if (!pSrcFile && !pDstFile && pSrcDir && pDstDir) {
    /* get picture names */
    pPictureLists = getPictureLists(pSrcDir, &nCnt);

    /* allocate source and result filenames */
    pSrcFiles = (char **)malloc(sizeof(char *) * nCnt);
    assert(pSrcFiles != NULL);
    memset(pSrcFiles, 0, sizeof(char *) * nCnt);
    pDstFiles = (char **)malloc(sizeof(char *) * nCnt);
    assert(pDstFiles != NULL);
    memset(pDstFiles, 0, sizeof(char *) * nCnt);

    /* join path and filenames together */
    for (i = 0; i < nCnt; ++i) {
      pSrcFiles[i] = (char *)malloc(sizeof(char) * (strlen(pPictureLists[i]) + strlen(pSrcDir) + 1));
      assert(pSrcFiles[i] != NULL);
      sprintf(pSrcFiles[i], "%s/%s", pSrcDir, pPictureLists[i]);
      pDstFiles[i] = (char *)malloc(sizeof(char) * (strlen(pPictureLists[i] + strlen(pDstDir) + 1)));
      assert(pDstFiles != NULL);
      sprintf(pDstFiles[i], "%s/%s", pDstDir, pPictureLists[i]);
    }

    /* allocate source data */
    pSrcData = (Pixel *)malloc(sizeof(Pixel) * SRC_WIDTH * SRC_HEIGHT);
    if (!pSrcData) {
      printf("Allocate source data failed\n");
      return -1;
    }
    memset(pSrcData, 0, sizeof(Pixel) * SRC_WIDTH * SRC_HEIGHT);

    /* allocate result data */
    pDstData = (Pixel *)malloc(sizeof(Pixel) * DST_WIDTH * DST_HEIGHT);
    if (!pDstData) {
      printf("Allocate destination data failed\n");
      return -1;
    }
    memset(pDstData, 0, sizeof(Pixel) * DST_WIDTH * DST_HEIGHT);

    /* processing */
    for (i = 0; i < nCnt; ++i) {
      readSinglePicture_540p(pSrcFiles[i], pSrcData);
      if (bParallel) {
        upsamplingParallel_540p4k(pSrcData, pDstData);
      } else {
        upsampling_540p4k(pSrcData, pDstData);
      }
      writeSinglePicture_4k(pDstFiles[i], pDstData);
      printf("Pictures %d/%d finished!\n", i + 1, nCnt);
    }

    for (i = 0; i < nCnt; ++i) {
      free(pSrcFiles[i]);
      pSrcFiles[i] = NULL;
      free(pDstFiles[i]);
      pDstFiles[i] = NULL;
    }
  } else {
    printf("Wrong argument!\n");
    return -1;
  }

  // release heap memory
  if (pSrcData) {
    free(pSrcData);
    pSrcData = NULL;
  }

  if (pSrcFiles) {
    free(pSrcFiles);
    pSrcFiles = NULL;
  }

  if (pDstData) {
    free(pDstData);
    pDstData = NULL;
  }

  if (pDstFiles) {
    free(pDstFiles);
    pDstFiles = NULL;
  }

  if (pPictureLists) {
    for (i = 0; i < nCnt; ++i) {
      free(pPictureLists[i]);
      pPictureLists[i] = NULL;
    }
    free(pPictureLists);
    pPictureLists = NULL;
  }
  // end of release heap memory
  return 0;
}
