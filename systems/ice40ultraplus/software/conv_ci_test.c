#include "printf.h"
#include "vbx.h"
#include "flash_dma.h"

//8x8 input map with padding
//1 BYTE per pixel
//each row is aligned to word size
#define INPUT_MAP_SIZE  8
#define PRINT_MAPS 0
vbx_byte_t input_map [] = { 0,0,0,0,0,0,0,0,0,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0,0,0,
                            0,0,0,0,0,0,0,0,0,0,0,0};

vbx_half_t sample_weight=0x1FF; //0b110 101 010
vbx_byte_t s_sample_weights[]={1,1,1, 1,1,1, 1,1,1};

//extra 4 element padding just like the source image
vbx_half_t output_map_check[]={0,0x000,0x000,0x000,0x000,0x000,0x000,0x000,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x0FF,0x1FE,0,0,0,0,
                               0,0x1FE,0x1FE,0x1FE,0x1FE,0x1FE,0x1FE,0x1FE,0,0,0,0};

///
// Padding:
//
// Padding rows on the top and bottom work faily straight-forward.
// You need padding on the top and bottom, and the custom instruction does 2 less writes
// than reads so padding rows in the source does not result in padding rows in the destination.
//
// Padding for colunms is slightly more complicated. All rows must be word aligned, every byte of
// Padding in the source results in a byte of padding in the destination.
void vbx_convolve(vbx_ubyte_t* input_map,vbx_half_t* output_map,int square_size,vbx_half_t weights)
{
	//the weights are the 9 LSBs of the weights parameter
	int col;

	//set up the weights.
	//dest and srcb do not matter;
	vbx_set_vl(1);
	vbx(SVW,VCUSTOM1,0,weights,0);
	vbx_set_vl(1,square_size+2);
	//stride is square size + 2 bytes for zero padding, + 2 bytes for word alignment
	int stride=square_size+2 +2;
	vbx_set_2D(stride*2, stride,stride );
	for(col=0;col<square_size;col+=2){
		vbx(VVW,VCUSTOM2,(vbx_word_t*)(output_map+col),(vbx_word_t*)(input_map+col),(vbx_word_t*)(input_map+col+4));
	}

}
static inline int PAD_UP(int n,int align)
{
	int extra=n%align;

	if( !(extra)){
		return n;
	}else{
		return n-(extra)+align;
	}
}


int test_convolve()
{
	printf("test_convolve()\r\n");
	init_lve();
	vbx_ubyte_t* v_input_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE+2));
	vbx_half_t* v_output_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE)*sizeof(vbx_half_t));
	vbx_half_t* s_output_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE)*sizeof(vbx_half_t));
	int flash_dma_size=1*1024;
	int flash_dma_addr=0;
	vbx_ubyte_t* v_dma_dest= vbx_sp_alloc(flash_dma_size);

	//copy the static data into the scratchpad
	int i,j;
	//initialize input matrix
	for(i=0;i<INPUT_MAP_SIZE+2;i++){
			for(j=0;j<PAD_UP(INPUT_MAP_SIZE+2,4);j++){
				int index=i*PAD_UP(INPUT_MAP_SIZE+2,4)+j;
				if(j==0 || j >= INPUT_MAP_SIZE+1 ||
				   i==0 || i >= INPUT_MAP_SIZE+1){
					v_input_map[index]=0;
				}else{
					v_input_map[index]=0xFF;
				}
				//v_input_map[index]=(i<<4)|j;
			}
	}

	//clear outputs
	vbx_set_vl(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE)/(sizeof(vbx_word_t)/sizeof(vbx_half_t)));
	vbx(SEW,VMOV,(vbx_word_t*)v_output_map,0,vbx_ENUM);
	vbx(SEW,VMOV,(vbx_word_t*)s_output_map,0,vbx_ENUM);


	//scalar output matrix
	for(i=0;i<INPUT_MAP_SIZE;i++){
		for(j=0;j<INPUT_MAP_SIZE;j++){
			int sum=0;
			sum+=s_sample_weights[0]*v_input_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j];
			sum+=s_sample_weights[1]*v_input_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j+1];
			sum+=s_sample_weights[2]*v_input_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j+2];
			sum+=s_sample_weights[3]*v_input_map[(i+1)*PAD_UP(INPUT_MAP_SIZE+2,4)+j];
			sum+=s_sample_weights[4]*v_input_map[(i+1)*PAD_UP(INPUT_MAP_SIZE+2,4)+j+1];
			sum+=s_sample_weights[5]*v_input_map[(i+1)*PAD_UP(INPUT_MAP_SIZE+2,4)+j+2];
			sum+=s_sample_weights[6]*v_input_map[(i+2)*PAD_UP(INPUT_MAP_SIZE+2,4)+j];
			sum+=s_sample_weights[7]*v_input_map[(i+2)*PAD_UP(INPUT_MAP_SIZE+2,4)+j+1];
			sum+=s_sample_weights[8]*v_input_map[(i+2)*PAD_UP(INPUT_MAP_SIZE+2,4)+j+2];

			s_output_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j]=sum;;
		}
	}

	if (PRINT_MAPS){
		printf("\r\ninput map\r\n");
		for(j=0;j<INPUT_MAP_SIZE+2;j++){
			for(i=0;i<PAD_UP(INPUT_MAP_SIZE+2,4);i++){
				printf("%3x ",(int)(v_input_map[j*PAD_UP(INPUT_MAP_SIZE+2,4)+i]));
			}printf("\r\n");
		}
	}

	if(PRINT_MAPS ){
		printf("\r\nscalar output map\r\n");
		for(i=0;i<INPUT_MAP_SIZE;i++){
			for(j=0;j<PAD_UP(INPUT_MAP_SIZE+2,4);j++){
				printf("%3x ",(int)(s_output_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j]));
			}printf("\r\n");
		}
	}
	for(i=0;i<(sizeof(output_map_check)/sizeof(output_map_check[0]));i++){
		v_output_map[i]=0;
	}
	//flash_dma_trans(flash_dma_addr,(void*) v_dma_dest,flash_dma_size);
	vbx_convolve(v_input_map,v_output_map,INPUT_MAP_SIZE,sample_weight);
	//while(!flash_dma_done());

	int errors=0;
	if(PRINT_MAPS){
		printf("\r\nvector output map\r\n");
		for(i=0;i<INPUT_MAP_SIZE;i++){
			for(j=0;j<PAD_UP(INPUT_MAP_SIZE+2,4);j++){
				printf("%3x ",(int)(v_output_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j]));
			}printf("\r\n");
		}
	}
	for(i=0;i<PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE);i++){
		if (s_output_map[i] != v_output_map[i]){
			printf("FAILED i=%d %x !=%x\r\n",i,(int)s_output_map[i],(int)(v_output_map[i]));
			errors++;
		}
	}
	printf("CONVOLVE TEST %s\r\n",errors?"Failed":"Passed");
	return errors;

}

int test_word_to_byte()
{
	printf("test_word_to_byte()\r\n");
	int test_length=1024;;
	vbx_uword_t* v_input=SCRATCHPAD_BASE;
	vbx_ubyte_t* v_output=(vbx_ubyte_t*)(v_input+test_length);

	int i;
	int errors=0;

#define input_gen(i) (i-test_length/2)
	for(i=0;i<test_length;i++){
		v_input[i] = input_gen(i) ;
	}

	vbx_set_vl(1,test_length);
	vbx_set_2D(1,4 ,0);
	vbx(VEW,VCUSTOM0,(vbx_word_t*)v_output,(vbx_word_t*)v_input,0);


	for(i=0;i<test_length;i++){
		int test_val= input_gen(i);
		if(test_val<0)
			test_val=0;
		if(test_val>0xFF)
			test_val=255;
		if(test_val != v_output[i]){
			errors++;
			printf("ERROR i=%d %x !=%x\r\n",i,(int)test_val,(int)v_output[i]);
		}
	}

	printf("WORD TO BYTE TEST %s\r\n", errors ? "Failed" : "Passed");
	return errors;
}

int test_halfword_add()
{
	printf("test_halfword_add()\r\n");
	int test_length=10;
	vbx_half_t* v_inputa=SCRATCHPAD_BASE;
	vbx_half_t* v_inputb=(v_inputa+test_length);;
	vbx_half_t* v_output=(v_inputb+test_length);
	vbx_half_t* s_output=(v_output+test_length);
	int i,errors=0;
	for(i=0;i<test_length;i++){
		v_inputa[i]=i*63+i;
		v_inputb[i]=i*25+i+4;
		s_output[i]=v_inputa[i]+v_inputb[i];
	}
	//treat the vector as words
	vbx_set_vl(test_length/2);
	vbx(VVW,VCUSTOM3,(vbx_word_t*)v_output,(vbx_word_t*)v_inputa,(vbx_word_t*)v_inputb);

	for(i=0;i<test_length;i++){
		if(s_output[i] != v_output[i]){
			errors++;
			printf("ERROR @ %d: %d != %d ",i,s_output[i],v_output[i]);
		}
	}
	printf("Halfword Add test %s\r\n",errors?"Failed":"Passed");
	return errors;
}

int test_halftoword()
{
	//	printf("test_halftoword()\r\n");
	init_lve();
	int test_length=10;
	vbx_half_t* v_input=SCRATCHPAD_BASE;
	vbx_word_t* v_output=(vbx_word_t*)(v_input+test_length);
	int i,errors=0;
	for(i=0;i<test_length;i++){
		v_input[i]=i;
	}

	vbx_set_vl(1,test_length/2);
	vbx_set_2D(8,0,4);
	vbx(SVW,VAND, v_output,0xFFFF,   (vbx_word_t*)v_input);
	vbx(SVW,VMULHI,v_output+1,(1<<16),(vbx_word_t*)v_input);

	for(i=0;i<test_length;i++){
		if(v_output[i]!=i){
			printf("error : %d %d\r\n",i,(int)v_output[i]);
			errors++;
		}
	}

	printf("Half to word test %s\r\n",errors?"Failed":"Passed");
	return errors;
}

int main()
{
	//	printf("Starting\n");
	int errors=0;
	errors += test_convolve();
	errors += test_word_to_byte();
	errors += test_halfword_add();
	errors += test_halftoword();


	printf("DONE -- errors = %d %s\r\n\r\n",errors,errors?"FAILED :(":"PASSED :)");

}





/////
//Word to byte conversion sample
/////

void vbx_w2b_convert(vbx_word_t* input_map,vbx_byte_t* output_map,int num_elements)
{
	vbx_set_vl(num_elements);
	vbx(VEW,VCUSTOM0,(vbx_word_t*)output_map,input_map,0);
}
