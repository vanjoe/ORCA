#include "interrupt.h"
#include "test_macros.h"

#include <stdint.h>

volatile uint32_t uop1[10] = {
  0x3907f464, 
  0x03163bec,
  0x08014b39,
  0x0950c504,
  0x5ceb6e31,
  0x1542b740,
  0x6854690d,
  0x1943ffe5,
  0x742602b5,
  0x0a061484
};

volatile uint32_t uop2[10] = {
  0x1a6acb34,
  0x2bb31e5d,
  0x2f916d89,
  0x2400e98a,
  0x3e3f5da7,
  0x37dc8006,
  0x0d70daac,
  0x52e654e4,
  0x6ce1fefe,
  0x5b6cc87b
};

volatile int32_t sop1[10] = {
  0xee43adc2,
  0x9eeb353b,
  0xc9790b3b,
  0xfc0372c1,
  0xb309e1b2,
  0xa15580a1,
  0xbdcd41f0,
  0xc1cbb001,
  0xa7e03114,
  0xb5c16d35
};

volatile int32_t sop2[10] = {
  0x8aaf076e,
  0x89c14586,
  0xbe14cd1c,
  0x90f27f3d,
  0xffcd07c5,
  0xa40c387a,
  0xcc2d75ae,
  0xfca20a6f,
  0x93f7f30d,
  0xdae1f377
};

volatile uint32_t result1lo[10] = {
  0x3dd0f050,
  0x441d6cbc,
  0xe8018681,
  0x18dad828,
  0x20abaef7,
  0x16304b80,
  0x98dba6bc,
  0x12450bf4,
  0xb17b4596,
  0x24a2fb6c
};

volatile uint32_t result2lo[10] = {           
  0xb6dc2168,
  0x6cf0406f,
  0x8cfa2193,
  0x214d850a,
  0x093de51e,
  0xa9ad83c6,
  0x590ead40,
  0xe20f14e4,
  0x93b689d8,
  0x5a9ce077
};

volatile uint32_t result3lo[10] = {           
  0xb175bef8,
  0x14b5f988,
  0x17d4df3c,
  0xc7c3edf4,
  0xfd6c22b5,
  0x50e15480,
  0x50ab57d6,
  0xf764e64b,
  0x8622f231,
  0xde50d55c
};
  
volatile int32_t result4lo[10] = {  
  0x9672f75c,
  0x48f1c3e2,
  0xa1d77974,
  0xcd3216fd,
  0x15508bfa,
  0xc26e84ba,
  0xa7d58120,
  0x58d35a6f,
  0x2b447a04,
  0x352812a3
};

volatile uint32_t result1hi[10] = {
  0x05e29962,
  0x0086e4fa,
  0x017cc8f7,
  0x014f6434,
  0x1698049e,
  0x04a3a556,
  0x057a4761,
  0x082e8370,
  0x3166923d,
  0x03946bb5
};

volatile uint32_t result2hi[10] = {           
  0xfe2b7997,
  0xef6d94e3,
  0xf5de3f4a,
  0xff707880,
  0xed4957f0,
  0xeb57d4c5,
  0xfc863d9a,
  0xebdb46bf,
  0xda84c8f8,
  0xe57c3547
}; 

volatile uint32_t result3hi[10] = {            
  0xe5dd5371,
  0xfe92febf,
  0xfdf0511f,
  0xfbf57cc9,
  0xffed7fea,
  0xf85d09f6,
  0xeae16175,
  0xffaaee0f,
  0xcefc4fcb,
  0xfe8bf1d4
};           

volatile uint32_t result4hi[10] = {
  0x0820ada8,
  0x2cd75f37,
  0x0e0a5cdf,
  0x01bab712,
  0x000f52b2,
  0x2200c0e5,
  0x0d668d41,
  0x00d1719c,
  0x253030bf,
  0x0ac3c22f
};


int main()
{


//        3907f464 *         1a6acb34 =  5e299623dd0f050
//         3163bec *         2bb31e5d =   86e4fa441d6cbc
//         8014b39 *         2f916d89 =  17cc8f7e8018681
//         950c504 *         2400e98a =  14f643418dad828
//        5ceb6e31 *         3e3f5da7 = 1698049e20abaef7
//        1542b740 *         37dc8006 =  4a3a55616304b80
//        6854690d *          d70daac =  57a476198dba6bc
//        1943ffe5 *         52e654e4 =  82e837012450bf4
//        742602b5 *         6ce1fefe = 3166923db17b4596
//         a061484 *         5b6cc87b =  3946bb524a2fb6c
// 
//        ee43adc2 *         1a6acb34 = fe2b7997b6dc2168
//        9eeb353b *         2bb31e5d = ef6d94e36cf0406f
//        c9790b3b *         2f916d89 = f5de3f4a8cfa2193
//        fc0372c1 *         2400e98a = ff707880214d850a
//        b309e1b2 *         3e3f5da7 = ed4957f0093de51e
//        a15580a1 *         37dc8006 = eb57d4c5a9ad83c6
//        bdcd41f0 *          d70daac = fc863d9a590ead40
//        c1cbb001 *         52e654e4 = ebdb46bfe20f14e4
//        a7e03114 *         6ce1fefe = da84c8f893b689d8
//        b5c16d35 *         5b6cc87b = e57c35475a9ce077
// 
//        3907f464 *         8aaf076e = e5dd5371b175bef8
//         3163bec *         89c14586 = fe92febf14b5f988
//         8014b39 *         be14cd1c = fdf0511f17d4df3c
//         950c504 *         90f27f3d = fbf57cc9c7c3edf4
//        5ceb6e31 *         ffcd07c5 = ffed7feafd6c22b5
//        1542b740 *         a40c387a = f85d09f650e15480
//        6854690d *         cc2d75ae = eae1617550ab57d6
//        1943ffe5 *         fca20a6f = ffaaee0ff764e64b
//        742602b5 *         93f7f30d = cefc4fcb8622f231
//         a061484 *         dae1f377 = fe8bf1d4de50d55c
// 
//        ee43adc2 *         8aaf076e =  820ada89672f75c
//        9eeb353b *         89c14586 = 2cd75f3748f1c3e2
//        c9790b3b *         be14cd1c =  e0a5cdfa1d77974
//        fc0372c1 *         90f27f3d =  1bab712cd3216fd
//        b309e1b2 *         ffcd07c5 =    f52b215508bfa
//        a15580a1 *         a40c387a = 2200c0e5c26e84ba
//        bdcd41f0 *         cc2d75ae =  d668d41a7d58120
//        c1cbb001 *         fca20a6f =   d1719c58d35a6f
//        a7e03114 *         93f7f30d = 253030bf2b447a04
//        b5c16d35 *         dae1f377 =  ac3c22f352812a3



  volatile uint32_t temp;
  volatile int32_t test_num = 0;
  
  int i;

// MUL
  for (i = 0; i < 10; i++) {
    asm volatile ("mul %0, %1, %2"
      : "=r" (temp)
      : "r" (uop1[i]), "r" (uop2[i])); 
    if (temp != result1lo[i]) {
      TEST_FAIL();
    }
    test_num++;
  }

  for (i = 0; i < 10; i++) {
    asm volatile ("mul %0, %1, %2"
      : "=r" (temp)
      : "r" (sop1[i]), "r" (uop2[i])); 
    if (temp != result2lo[i]) {
      TEST_FAIL();
    }
    test_num++;
  }

  for (i = 0; i < 10; i++) {
    asm volatile ("mul %0, %1, %2"
      : "=r" (temp)
      : "r" (uop1[i]), "r" (sop2[i])); 
    if (temp != result3lo[i]) {
      TEST_FAIL();
    }
    test_num++;
  }
 
  for (i = 0; i < 10; i++) {
    asm volatile ("mul %0, %1, %2"
      : "=r" (temp)
      : "r" (sop1[i]), "r" (sop2[i])); 
    if (temp != result4lo[i]) {
      TEST_FAIL();
    }
    test_num++;
  }

// MULHU
  for (i = 0; i  < 10; i++) {
    asm volatile ("mulhu %0, %1, %2"
      : "=r" (temp)
      : "r" (uop1[i]), "r" (uop2[i])); 
    if (temp != result1hi[i]) {
      TEST_FAIL();
    }
    test_num++;
  }

// MULHSU 
  for (i = 0; i < 10; i++) {
    asm volatile ("mulhsu %0, %1, %2"
      : "=r" (temp)
      : "r" (sop1[i]), "r" (uop2[i])); 
    if (temp != result2hi[i]) {
      TEST_FAIL();
    }
    test_num++;
  }


// MULH 
  for (i = 0; i < 10; i++) {
    asm volatile ("mulh %0, %1, %2"
      : "=r" (temp)
      : "r" (sop1[i]), "r" (sop2[i])); 
    if (temp != result4hi[i]) {
      TEST_FAIL();
    }
    test_num++;
  }

// Test -1 * -1 
  asm volatile ("mul %0, %1, %2"
    : "=r" (temp)
    : "r" (0xFFFFFFFF), "r" (0xFFFFFFFF)); 
  if (temp != 0x00000001) {
    TEST_FAIL();
  }
  test_num++;

  asm volatile ("mulhu %0, %1, %2"
    : "=r" (temp)
    : "r" (0xFFFFFFFF), "r" (0xFFFFFFFF)); 
  if (temp != 0xFFFFFFFE) {
    TEST_FAIL();
  }
  test_num++;

  asm volatile ("mulh %0, %1, %2"
    : "=r" (temp)
    : "r" (0xFFFFFFFF), "r" (0xFFFFFFFF)); 
  if (temp != 0x00000000) {
    TEST_FAIL();
  }
  test_num++;

// Shift left by zero.
  asm volatile("slli %0, %1, 0"
    : "=r" (temp)
    : "r" (-5));
  if (temp != -5) {
    TEST_FAIL();
  }

  asm volatile("slli %0, %1, 0"
    : "=r" (temp)
    : "r" (5));
  if (temp != 5) {
    TEST_FAIL();
  }

// Shift right by zero.
  asm volatile("srli %0, %1, 0"
    : "=r" (temp)
    : "r" (-5));
  if (temp != -5) {
    TEST_FAIL();
  }

  asm volatile("srli %0, %1, 0"
    : "=r" (temp)
    : "r" (5));
  if (temp != 5) {
    TEST_FAIL();
  }

// Arithmetic shift right by zero.
  asm volatile("srai %0, %1, 0"
    : "=r" (temp)
    : "r" (-5));
  if (temp != -5) {
    TEST_FAIL();
  }

  asm volatile("srai %0, %1, 0"
    : "=r" (temp)
    : "r" (5));
  if (temp != 5) {
    TEST_FAIL();
  }

  TEST_PASS();
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  switch(cause & 0xF) {

    case M_SOFTWARE_INTERRUPT:
      clear_software_interrupt();

    case M_TIMER_INTERRUPT:
      clear_timer_interrupt_cycles();

    case M_EXTERNAL_INTERRUPT:
      {
        int plic_claim;
        claim_external_interrupt(&plic_claim);
        complete_external_interrupt(plic_claim);
      }
      break;

    default:
      break;
  }

  return epc;
}
