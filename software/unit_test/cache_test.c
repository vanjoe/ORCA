#include <stdint.h>

#define TEST_ATTR static __attribute__((noinline))

#define TEST_SIZE_WORDS 7
#define TEST_RUNS       3

TEST_ATTR int test_2()
{
  //Test back-to-back word writes followed by reads

  uint32_t temp_location[TEST_SIZE_WORDS];
  uint32_t run = 0;
  for(run = 0; run < TEST_RUNS; run++){
    uint32_t word = 0;
    //Writes 4 copies so do test_size_words-3 locations
    for(word = 0; word < (TEST_SIZE_WORDS-3); word++){
      register uint32_t result0;
      register uint32_t result1;
      register uint32_t result2;
      register uint32_t result3;
      register uint32_t *temp_pointer = &temp_location[word];
      register uint32_t write_value   = word+run;
      asm volatile ("sw %4, 0(%5)\n"
                    "lw %0, 0(%5)\n"
                    "sw %4, 4(%5)\n"
                    "lw %1, 4(%5)\n"    
                    "sw %4, 8(%5)\n"
                    "lw %2, 8(%5)\n"    
                    "sw %4, 12(%5)\n"
                    "lw %3, 12(%5)\n"
                    : "=r"(result0), "=r"(result1), "=r"(result2), "=r"(result3)
                    : "r"(write_value), "r"(temp_pointer)
                    );
      if(result0 != write_value){
        return 1;
      }
      if(result1 != write_value){
        return 1;
      }
      if(result2 != write_value){
        return 1;
      }
      if(result3 != write_value){
        return 1;
      }
    }
  }

  return 0;
}

TEST_ATTR int test_3()
{
  //Test back-to-back halfword writes followed by reads

  uint16_t temp_location[TEST_SIZE_WORDS];
  uint32_t run = 0;
  for(run = 0; run < TEST_RUNS; run++){
    uint32_t word = 0;
    //Writes 4 copies so do test_size_words-3 locations
    for(word = 0; word < (TEST_SIZE_WORDS-3); word++){
      register uint16_t result0;
      register uint16_t result1;
      register uint16_t result2;
      register uint16_t result3;
      register uint16_t *temp_pointer = &temp_location[word];
      register uint16_t write_value   = word+run;
      asm volatile ("sh %4, 0(%5)\n"
                    "lhu %0, 0(%5)\n"
                    "sh %4, 2(%5)\n"
                    "lhu %1, 2(%5)\n"    
                    "sh %4, 4(%5)\n"
                    "lhu %2, 4(%5)\n"    
                    "sh %4, 6(%5)\n"
                    "lhu %3, 6(%5)\n"
                    : "=r"(result0), "=r"(result1), "=r"(result2), "=r"(result3)
                    : "r"(write_value), "r"(temp_pointer)
                    );
      if(result0 != write_value){
        return 1;
      }
      if(result1 != write_value){
        return 1;
      }
      if(result2 != write_value){
        return 1;
      }
      if(result3 != write_value){
        return 1;
      }
    }
  }

  return 0;
}

TEST_ATTR int test_4()
{
  //Test back-to-back byte writes followed by reads

  uint8_t temp_location[TEST_SIZE_WORDS];
  uint32_t run = 0;
  for(run = 0; run < TEST_RUNS; run++){
    uint32_t word = 0;
    //Writes 4 copies so do test_size_words-3 locations
    for(word = 0; word < (TEST_SIZE_WORDS-3); word++){
      register uint8_t result0;
      register uint8_t result1;
      register uint8_t result2;
      register uint8_t result3;
      register uint8_t *temp_pointer = &temp_location[word];
      register uint8_t write_value   = word+run;
      asm volatile ("sb %4, 0(%5)\n"
                    "lbu %0, 0(%5)\n"
                    "sb %4, 1(%5)\n"
                    "lbu %1, 1(%5)\n"    
                    "sb %4, 2(%5)\n"
                    "lbu %2, 2(%5)\n"    
                    "sb %4, 3(%5)\n"
                    "lbu %3, 3(%5)\n"
                    : "=r"(result0), "=r"(result1), "=r"(result2), "=r"(result3)
                    : "r"(write_value), "r"(temp_pointer)
                    );
      if(result0 != write_value){
        return 1;
      }
      if(result1 != write_value){
        return 1;
      }
      if(result2 != write_value){
        return 1;
      }
      if(result3 != write_value){
        return 1;
      }
    }
  }

  return 0;
}

//this macro runs the test, and returns the test number on failure
#define do_test(i) do{if ( test_##i () ) return i;}while(0)

int main()
{

  do_test(2);
  do_test(3);
  do_test(4);

  return 0;

}

int handle_interrupt(int cause, int epc, int regs[32]) {
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		for (;;);
	}
	return epc;
}
