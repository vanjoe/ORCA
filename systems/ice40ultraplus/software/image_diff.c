#include "vbx.h"
#include "image_diff.h"

uint32_t abs_image_diff(vbx_word_t* imgA,vbx_ubyte_t* imgBb,vbx_ubyte_t* prevBuf)
{
	uint32_t diff = 0;
	vbx_word_t* tmp0 = (vbx_word_t*)(imgA + 4*THUMB_WIDTH*THUMB_HEIGHT);
	vbx_word_t* tmp1 = (vbx_word_t*)(tmp0 + 4*THUMB_WIDTH);
	vbx_word_t* imgB = (vbx_word_t*)(tmp1 + 4*THUMB_WIDTH); // note that imgB + THUMB_WIDTH*4 should not exceed the value of the SP address where the NN weights are stored

	vbx_set_vl(THUMB_WIDTH);
	for(int row=0;row<THUMB_HEIGHT;row++){
		// unpack the bytes of the previous image into words
		// and store the current image in the previous image buffer
		for(int col=0;col<THUMB_WIDTH;col++){
			prevBuf[row*THUMB_WIDTH+col] = imgA[row*THUMB_WIDTH+col];
		}
		for(int col=0;col<THUMB_WIDTH;col++){
			imgB[col] = imgBb[row*THUMB_WIDTH + col];
		}

		// compute the diff for this row
		vbx(VVW,VSUB,tmp0,imgA + row*THUMB_WIDTH,imgB); // tmp0 = imgA - imgB
		vbx(VVW,VSUB,imgB,imgB,imgA + row*THUMB_WIDTH); // imgB = imgB - imgA ( == -tmp0)
		vbx(VVW,VSLT,tmp1,tmp0,imgB); // tmp1 = tmp0 < imgB ? 1 : 0
		vbx(VVW,VCMV_NZ,tmp0,imgB,tmp1); // tmp0 = tmp1 ? imgB : tmp0
		vbx_acc(SVW,VADD,tmp0,0,tmp0);
		diff += *tmp0;
	}

	return diff;
}
