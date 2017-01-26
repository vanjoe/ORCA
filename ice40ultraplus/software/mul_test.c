#include "printf.h"

#define TEST_RUNS 65536

int lfsr_32( int previous_value )
{
	return (((previous_value>>31)^(previous_value>>21)^(previous_value>>1)^(previous_value>>0))&0x1)|((previous_value)<<1);
}

unsigned long long emulate_mulu(unsigned long srca, unsigned long srcb){
	unsigned long long ull_srcb = (unsigned long long)srcb;

	unsigned long long ull_dest = 0;
	int bit = 0;
	for(bit = 0; bit < 32; bit++){
		if(srca & (1 << bit)){
			ull_dest = ull_dest + ull_srcb;
		}
		ull_srcb = ull_srcb << 1;
	}

	return ull_dest;
}

signed long long emulate_muls(signed long srca, signed long srcb){
	signed long long ll_srca = (signed long long)srca;
	signed long long ll_srcb = (signed long long)srcb;

	int negate = 0;
	
	if(ll_srca & 0x80000000){
		ll_srca |= 0xFFFFFFFF00000000;
		ll_srca = 0 - ll_srca;
		negate = !negate;
	}
	if(ll_srcb & 0x80000000){
		ll_srcb |= 0xFFFFFFFF00000000;
		ll_srcb = 0 - ll_srcb;
		negate = !negate;
	}

	signed long long ll_dest = 0;
	int bit = 0;
	for(bit = 0; bit < 32; bit++){
		if(ll_srca & (1 << bit)){
			ll_dest = ll_dest + ll_srcb;
		}
		ll_srcb = ll_srcb << 1;
	}

	if(negate){
		ll_dest = 0 - ll_dest;
	}

	return ll_dest;
}


int main(){
	int errors = 0;
	printf("\r\nMUL test\r\n");

	volatile unsigned long long ull_a = 0xFFFFFFFFFFFFFFFF;
	volatile unsigned long long ull_b = 0xFFFFFFFFFFFFFFFF;

	volatile unsigned long long ull_c = ull_a * ull_b;
	volatile unsigned long long ull_c_golden = 0x0000000000000001;

	if(ull_c != ull_c_golden){
		errors++;
		printf("Error: ");
	}
	printf("ull_c 0x%08X%08X ull_c_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ull_c)[1],
				 ((unsigned int *)&ull_c)[0],
				 ((unsigned int *)&ull_c_golden)[1],
				 ((unsigned int *)&ull_c_golden)[0]);

  ull_a = 0xFFFFFFFF;
	ull_b = 0xFFFFFFFF;

	volatile unsigned long long ull_d = ull_a * ull_b;
	volatile unsigned long long ull_d_golden = 0xFFFFFFFE00000001;

	if(ull_d != ull_d_golden){
		errors++;
		printf("Error: ");
	}
	printf("ull_d 0x%08X%08X ull_d_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ull_d)[1],
				 ((unsigned int *)&ull_d)[0],
				 ((unsigned int *)&ull_d_golden)[1],
				 ((unsigned int *)&ull_d_golden)[0]);

  ull_a = 0xFFFFFFFF00000000;
	ull_b = 0xFFFFFFFF;

	volatile unsigned long long ull_e = ull_a * ull_b;
	volatile unsigned long long ull_e_golden = 0x0000000100000000;

	if(ull_e != ull_e_golden){
		errors++;
		printf("Error: ");
	}
	printf("ull_e 0x%08X%08X ull_e_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ull_e)[1],
				 ((unsigned int *)&ull_e)[0],
				 ((unsigned int *)&ull_e_golden)[1],
				 ((unsigned int *)&ull_e_golden)[0]);

	volatile signed long long ll_a = 0xFFFFFFFFFFFFFFFF;
	volatile signed long long ll_b = 0xFFFFFFFFFFFFFFFF;

	volatile signed long long ll_c = ll_a * ll_b;
	volatile signed long long ll_c_golden = 0x0000000000000001;

	if(ll_c != ll_c_golden){
		errors++;
		printf("Error: ");
	}
	printf("ll_c 0x%08X%08X ll_c_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ll_c)[1],
				 ((unsigned int *)&ll_c)[0],
				 ((unsigned int *)&ll_c_golden)[1],
				 ((unsigned int *)&ll_c_golden)[0]);

  ll_a = 0xFFFFFFFF;
	ll_b = 0xFFFFFFFF;

	volatile signed long long ll_d = ll_a * ll_b;
	volatile signed long long ll_d_golden = 0xFFFFFFFE00000001;

	if(ll_d != ll_d_golden){
		errors++;
		printf("Error: ");
	}
	printf("ll_d 0x%08X%08X ll_d_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ll_d)[1],
				 ((unsigned int *)&ll_d)[0],
				 ((unsigned int *)&ll_d_golden)[1],
				 ((unsigned int *)&ll_d_golden)[0]);

  ll_a = 0xFFFFFFFF00000000;
	ll_b = 0xFFFFFFFF;

	volatile signed long long ll_e = ll_a * ll_b;
	volatile signed long long ll_e_golden = 0x0000000100000000;

	if(ll_e != ll_e_golden){
		errors++;
		printf("Error: ");
	}
	printf("ll_e 0x%08X%08X ll_e_golden 0x%08X%08X\r\n",
				 ((unsigned int *)&ll_e)[1],
				 ((unsigned int *)&ll_e)[0],
				 ((unsigned int *)&ll_e_golden)[1],
				 ((unsigned int *)&ll_e_golden)[0]);

	unsigned long ul_a = 0xDEADBEEF;
	unsigned long ul_b = 0xD00DFACE;

	printf("Doing %d runs of mul/mulh/mulhu vs emulated\r\n", TEST_RUNS);
	for(int run = 0; run < TEST_RUNS; run++){
		ul_a = lfsr_32(ul_a);
		ul_b = lfsr_32(ul_b);

		unsigned long ul_c = 0;
		unsigned long ul_d = 0;
		asm volatile("mul %0, %1, %2\n"   : "=r"(ul_c) : "r"(ul_a), "r"(ul_b));
		asm volatile("mulhu %0, %1, %2\n" : "=r"(ul_d) : "r"(ul_a), "r"(ul_b));
		unsigned long long ull_cd_golden = emulate_mulu(ul_a, ul_b);
		unsigned long ul_c_golden = (unsigned long)((ull_cd_golden >> 0) & 0xFFFFFFFF);
		if(ul_c != ul_c_golden){
			errors++;
			printf("Error: ");
			printf("mulu: 0x%08X * 0x%08X got 0x%08X expected 0x%08X\r\n",
						 (unsigned int)ul_a, (unsigned int)ul_b, (unsigned int)ul_c, (unsigned int)ul_c_golden);
		}
		unsigned long ul_d_golden = (unsigned long)((ull_cd_golden >> 32) & 0xFFFFFFFF);
		if(ul_d != ul_d_golden){
			errors++;
			printf("Error: ");
			printf("mulhu: 0x%08X * 0x%08X got 0x%08X expected 0x%08X\r\n",
						 (unsigned int)ul_a, (unsigned int)ul_b, (unsigned int)ul_d, (unsigned int)ul_d_golden);
		}

		signed long l_a = (signed long)ul_a;
		signed long l_b = (signed long)ul_b;

		signed long l_c = 0;
		signed long l_d = 0;
		asm volatile("mul %0, %1, %2\n"  : "=r"(l_c) : "r"(l_a), "r"(l_b));
		asm volatile("mulh %0, %1, %2\n" : "=r"(l_d) : "r"(l_a), "r"(l_b));
		signed long long ll_cd_golden = emulate_muls(l_a, l_b);
		signed long l_c_golden = (signed long)((ll_cd_golden >> 0) & 0xFFFFFFFF);
		if(l_c != l_c_golden){
			errors++;
			printf("Error: ");
			printf("mul: 0x%08X * 0x%08X got 0x%08X expected 0x%08X\r\n",
						 (unsigned int)l_a, (unsigned int)l_b, (unsigned int)l_c, (unsigned int)l_c_golden);
		}
		signed long l_d_golden = (signed long)((ll_cd_golden >> 32) & 0xFFFFFFFF);
		if(l_d != l_d_golden){
			errors++;
			printf("Error: ");
			printf("mulh: 0x%08X * 0x%08X got 0x%08X expected 0x%08X\r\n",
						 (unsigned int)l_a, (unsigned int)l_b, (unsigned int)l_d, (unsigned int)l_d_golden);
		}
	}

	if(errors){
		printf("Failed mul test with %d errors :(\r\n", errors);
	} else {
		printf("Passed mul test :)\r\n");
	}
													 
	return 0;
}
