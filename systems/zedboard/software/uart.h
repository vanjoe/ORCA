#include <stdint.h>
#include <stdarg.h>

#define X_mWriteReg(BASE_ADDRESS, RegOffset, data)                    \
  (*((volatile uint32_t *)(((uintptr_t)BASE_ADDRESS) + RegOffset)) = (uint32_t)data)
#define X_mReadReg(BASE_ADDRESS, RegOffset)                             \
  (*((volatile uint32_t *)(((uintptr_t)BASE_ADDRESS) + RegOffset)))
#define XUartChanged_IsTransmitFull(BASE_ADDRESS)                       \
  ((X_mReadReg(BASE_ADDRESS, 0x2C) & 0x10) == 0x10)

void XUARTChanged_SendByte(volatile void *BaseAddress, uint8_t Data);
void outbyte(char c);
void ChangedPrint(char *ptr);
void print_char(char c);
void ps7_printf(char *format, ...);
