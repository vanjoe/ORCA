#include "vbx.h"
#include "image_diff.h"

#if GS_CAM
uint32_t abs_image_diff(vbx_ubyte_t* imgAb,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf)
#else
uint32_t abs_image_diff(vbx_word_t* imgA,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf)
#endif
{
	uint32_t diff = 0;
	vbx_word_t* tmp0 = (vbx_word_t*)(imgA + 4*THUMBNAIL_WIDTH*THUMBNAIL_HEIGHT);
	vbx_word_t* tmp1 = (vbx_word_t*)(tmp0 + 4*THUMBNAIL_WIDTH);
	vbx_word_t* imgB = (vbx_word_t*)(tmp1 + 4*THUMBNAIL_WIDTH); // note that imgB + THUMBNAIL_WIDTH*4 should not exceed the value of the SP address where the NN weights are stored

#if GS_CAM
	vbx_word_t* imgA = (vbx_word_t*)(imgB + 4*THUMBNAIL_WIDTH);
#endif
	vbx_set_vl(THUMBNAIL_WIDTH);
	for(int row=0;row<THUMBNAIL_HEIGHT;row++){
		// unpack the bytes of the previous image into words
		// and store the current image in the previous image buffer
		for(int col=0;col<THUMBNAIL_WIDTH;col++){
			imgB[col] = imgBb[row*THUMBNAIL_WIDTH + col];
#if GS_CAM
			imgA[col] = imgAb[row*CAM_IMAGE_WIDTH + col];
#endif
			prevBuf[row*THUMBNAIL_WIDTH+col] = imgA[row*THUMBNAIL_WIDTH+col];
		}

		// compute the diff for this row
#if GS_CAM
		vbx(VVW,VSUB,tmp0,imgA,imgB); //tmp0 = imgA - imgB
		vbx(VVW,VSUB,imgB,imgB,imgA); //imgB = imgB - imgA ( == -tmp0)
#else
		vbx(VVW,VSUB,tmp0,imgA + row*THUMBNAIL_WIDTH,imgB); // tmp0 = imgA - imgB
		vbx(VVW,VSUB,imgB,imgB,imgA + row*THUMBNAIL_WIDTH); // imgB = imgB - imgA ( == -tmp0)
#endif
		vbx(VVW,VSLT,tmp1,tmp0,imgB); // tmp1 = tmp0 < imgB ? 1 : 0
		vbx(VVW,VCMV_NZ,tmp0,imgB,tmp1); // tmp0 = tmp1 ? imgB : tmp0
		vbx_acc(SVW,VADD,tmp0,0,tmp0);
		diff += *tmp0;
	}

	return diff;
}
