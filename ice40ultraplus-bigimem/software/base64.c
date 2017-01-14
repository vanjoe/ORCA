#include "printf.h"

union base64_t{
  struct {
	 char byte_c;
	 char byte_b;
	 char byte_a;

  };
  struct {
	 unsigned int index_d : 6;
	 unsigned int index_c : 6;
	 unsigned int index_b : 6;
	 unsigned int index_a : 6;
  };
};
const char base_64_table[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

void print_base64(char* in_str, int in_len)
{
  int i,j;
  union base64_t b64;
  for(i = 0;i<in_len;i+=3){

	 b64.byte_a=in_str[i];
	 b64.byte_b=i+1<in_len?in_str[i+1]:0;
	 b64.byte_c=i+2<in_len?in_str[i+2]:0;

	 printf("%c%c%c%c",
			  base_64_table[b64.index_a],
			  base_64_table[b64.index_b],
			  i+1<in_len?base_64_table[b64.index_c]:'=',
			  i+2<in_len?base_64_table[b64.index_d]:'=');
  }


}
