#include "uart.h"

void XUARTChanged_SendByte(volatile void *BaseAddress, uint8_t Data) {
  while(XUartChanged_IsTransmitFull(BaseAddress)){
  }
  X_mWriteReg(BaseAddress, 0x30, Data);
}

void outbyte(char c) {
  XUARTChanged_SendByte((volatile void *)0xE0001000, c);
}

void ChangedPrint(char *ptr) {
  while (*ptr) {
    outbyte(*ptr++);
  }
  flush_uart();
}

void flush_uart(void){
  while(!XUartChanged_IsTransmitEmpty((volatile void *)0xE0001000)){
  }
}

void print_char(char c) {
  outbyte(c);
}

void print_hex(uint32_t value){
  char printString[11];
  printString[0] = '0';
  printString[1] = 'x';
  printString[10] = '\0';
  int place = 0;
  for(place = 0; place < 8; place ++){
    char higit = (value >> ((7-place)*4)) & 0xF;
    if(higit < 10){
      higit = '0' + higit;
    } else {
      higit = 'A' + (higit-10);
    }
    printString[2+place] = higit;
  }
  ChangedPrint(printString);
}
