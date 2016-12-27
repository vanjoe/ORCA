#include "printf.h"
#include "lve_test.h"

int main(){
	int errors = 0;
	unsigned int failed_tests = 0x0000;
	printf("\r\nCI test\r\n");

	errors += lve_test(&failed_tests);

	if(errors){
		printf("Failed CI test with %d errors %04X mask:(\r\n", errors, failed_tests);
	} else {
		printf("Passed CI test :)\r\n");
	}
													 
	return 0;
}
