#include "vbx.h"
#include "rgb2grayscale.h"
#include "image_diff.h"

/* convert_rgb2grayscale 
 * 
 * input: pointer to sampled rgb thumbnail image
 * input: pointer to sp location where grayscale image will be stored
 */
void convert_rgb2grayscale(vbx_word_t* rgb,vbx_word_t* gs)
{
	vbx_word_t* tmp = (vbx_word_t*)(gs + 4*THUMBNAIL_WIDTH*THUMBNAIL_HEIGHT);

	vbx_set_vl(THUMBNAIL_WIDTH);
	for(int row=0;row<THUMBNAIL_HEIGHT;row++){
	
		// extract B pixel
		vbx(SVW,VAND,tmp,0xFF,rgb + row*CAM_IMG_WIDTH);
		// move the weighted B into the grayscale image
		vbx(SVW,VMUL,gs + row*THUMBNAIL_WIDTH,25,tmp);
	
		// extract G pixel
		vbx(SVW,VAND,tmp,0xFF00,rgb + row*CAM_IMG_WIDTH);
		vbx(SVW,VMULH,tmp,(1<<24),tmp);
		// add the weighted G pixel into the grayscale image
		vbx(SVW,VMUL,tmp,129,tmp);
		vbx(VVW,VADD,gs + row*THUMBNAIL_WIDTH,gs + row*THUMBNAIL_WIDTH,tmp);
	
		//extract the R pixel
		vbx(SVW,VAND,tmp,0xFF0000,rgb + row*CAM_IMG_WIDTH);
		vbx(SVW,VMULH,tmp,(1<<16),tmp);
		// add the weighted R pixel into the gayscale image
		vbx(SVW,VMUL,tmp,66,tmp);
		vbx(VVW,VADD,gs + row*THUMBNAIL_WIDTH,gs + row*THUMBNAIL_WIDTH,tmp);
	
		// convert to 8 bit grayscale pixel
		vbx(SVW,VADD,gs + row*THUMBNAIL_WIDTH,128,gs + row*THUMBNAIL_WIDTH); // for rounding
		vbx(SVW,VAND,gs + row*THUMBNAIL_WIDTH,0xFFFF,gs + row*THUMBNAIL_WIDTH);
		vbx(SVW,VMULH,gs + row*THUMBNAIL_WIDTH,(1<<24),gs + row*THUMBNAIL_WIDTH);
	}
}

