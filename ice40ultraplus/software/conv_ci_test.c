#include "printf.h"
#include "vbx.h"
#include "flash_dma.h"

//8x8 input map with padding
//1 BYTE per pixel
//each row is aligned to word size
#define INPUT_MAP_SIZE  48
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

vbx_half_t sample_weight=0x1AA; //0b110 101 010
vbx_byte_t s_sample_weights[]={1,1,-1, 1,-1,1, -1,1,-1};

//extra 4 element padding just like the source image
vbx_word_t output_map_check[]={0,0x000,0x000,0x000,0x000,0x000,0x000,0x000,0,0,0,0,
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
void vbx_convolve(vbx_ubyte_t* input_map,vbx_word_t* output_map,int square_size,vbx_half_t weights)
{
	//the weights are the 9 LSBs of the weights parameter
	int col;

	//set up the weights.
	//dest and srcb do not matter;
	vbx_set_vl(1);
	vbx(SVW,VCUSTOM1,0,weights,0);
	vbx_set_vl(square_size+2);

	//stride is square size + 2 bytes for zero padding, + 2 bytes for word alignment
	int stride=square_size+2 +2;

	the_lve.stride=stride;
	for(col=0;col<square_size;col++){
		vbx(VVWBU,VCUSTOM2,(vbx_uword_t*)output_map+col,input_map+col,input_map+col+4);
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
	init_lve();
	vbx_ubyte_t* v_input_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE+2));
	vbx_word_t* v_output_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE)*sizeof(vbx_word_t));
	vbx_word_t* s_output_map=vbx_sp_alloc(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE)*sizeof(vbx_word_t));
	int flash_dma_size=1*1024;
	int flash_dma_addr=0;
	vbx_ubyte_t* v_dma_dest= vbx_sp_alloc(flash_dma_size);

	const int PRINT_MATS=1;
	printf("CONVOLVE TEST  start\r\n");
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
			}
	}

	//clear outputs
	vbx_set_vl(PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE));
	vbx(SVW,VAND,v_output_map,0,v_output_map);
	vbx(SVW,VAND,s_output_map,0,v_output_map);


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

	if (PRINT_MATS){
		printf("\r\ninput map\r\n");
		for(j=0;j<INPUT_MAP_SIZE+2;j++){
			for(i=0;i<PAD_UP(INPUT_MAP_SIZE+2,4);i++){
				printf("%3d ",(int)(v_input_map[j*PAD_UP(INPUT_MAP_SIZE+2,4)+i]));
			}printf("\r\n");
		}
	}

	if(PRINT_MATS ){
		printf("\r\nscalar output map\r\n");
		for(i=0;i<INPUT_MAP_SIZE;i++){
			for(j=0;j<PAD_UP(INPUT_MAP_SIZE+2,4);j++){
				printf("%3d ",(int)(s_output_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j]));
			}printf("\r\n");
		}
	}
	for(i=0;i<(sizeof(output_map_check)/sizeof(output_map_check[0]));i++){
		v_output_map[i]=0;
	}
	flash_dma_trans(flash_dma_addr,(void*) v_dma_dest,flash_dma_size);
	vbx_convolve(v_input_map,v_output_map,INPUT_MAP_SIZE,sample_weight);
	while(!flash_dma_done());


	int errors=0;
	if(PRINT_MATS){
		printf("\r\nvector output map\r\n");
		for(i=0;i<INPUT_MAP_SIZE;i++){
			for(j=0;j<PAD_UP(INPUT_MAP_SIZE+2,4);j++){
				printf("%3d ",(int)(v_output_map[i*PAD_UP(INPUT_MAP_SIZE+2,4)+j]));
			}printf("\r\n");
		}
	}
	for(i=0;i<PAD_UP(INPUT_MAP_SIZE+2,4)*(INPUT_MAP_SIZE);i++){
		if (s_output_map[i] != v_output_map[i]){
			printf("FAILED i=%d %x !=%x\r\n",i,(int)s_output_map[i],(int)(v_output_map[i]));
			errors++;
		}
	}

	if(!errors){
		printf("CONVOLVE TEST Passed\r\n");
	}

	return errors;

}

int test_word_to_byte()
{
	int test_length=1024;;
	vbx_uword_t* v_input=SCRATCHPAD_BASE;
	vbx_ubyte_t* v_output=(vbx_ubyte_t*)(v_input+test_length);

	int i;
	int errors=0;

#define input_gen(i) (i-test_length/2)
	for(i=0;i<test_length;i++){
		v_input[i] = input_gen(i) ;
	}

	the_lve.stride=1;
	vbx_set_vl(test_length);

	vbx(VVBWU,VCUSTOM0,v_output,v_input,0);


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
	if(!errors){
		printf("WORD TO BYTE TEST Passed\r\n");
	}
	return errors;
}

int main()
{
	int errors=0;
	errors+= test_convolve();
	errors+= test_word_to_byte();


	printf("DONE -- errors = %d %s\r\n",errors,errors?"FAILED :(":"PASSED :)");

}




/////
//Word to byte conversion sample
/////


void vbx_w2b_convert(vbx_word_t* input_map,vbx_byte_t* output_map,int num_elements)
{
	the_lve.stride=1;
	vbx_set_vl(num_elements);
	vbx(VVBW,VCUSTOM0,output_map,input_map,0);
}
