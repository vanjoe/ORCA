#ifndef IMAGE_DIFF_H
#define IMAGE_DIFF_H

#include "vbx.h"

#define CAM_IMG_WIDTH  64
#define CAM_IMG_HEIGHT 32

#define THUMB_WIDTH  32
#define THUMB_HEIGHT 32
#define THUMB_X_OFFSET 0
#define THUMB_Y_OFFSET 0

#define DIFF_THRESH 0x1600

uint32_t abs_image_diff(vbx_word_t* imgA,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf);

#endif
