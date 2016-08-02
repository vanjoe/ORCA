#ifndef TEST_MACRO_H
#define TEST_MACRO_H

extern void* PASS asm("PASS");
extern void* FAIL asm("FAIL");

#define TEST_PASS() do {  \
                         asm volatile("j PASS" \
                         : \
                         : ); \
                       } while(0)  

#define TEST_FAIL() do {  \
                         asm volatile("j FAIL" \
                         : \
                         : ); \
                       } while(0)  

#endif
