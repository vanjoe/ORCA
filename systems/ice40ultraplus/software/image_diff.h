#ifndef IMAGE_DIFF_H
#define IMAGE_DIFF_H

#include "vbx.h"

#define GS_CAM 0

#define CAM_IMG_WIDTH  64
#define CAM_IMG_HEIGHT 32

#define THUMBNAIL_WIDTH  32
#define THUMBNAIL_HEIGHT 32
#define THUMBNAIL_X_OFFSET 0
#define THUMBNAIL_Y_OFFSET 0

#define DIFF_THRESH 0x1600

#if GS_CAM
uint32_t abs_image_diff(vbx_ubyte_t* imgAb,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf);
#else
uint32_t abs_image_diff(vbx_word_t* imgA,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf);
#endif


#endif
