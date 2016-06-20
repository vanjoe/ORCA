#ifndef I2S_H
#define I2S_H

#include <stdint.h>

#define _CPP_CONCAT(a,b) a##b
#define CPP_CONCAT(a,b) _CPP_CONCAT(a,b)



#define I2S_BUFFER_SIZE 1024
#define I2S_DATA_SIZE 32

#define I2S_BUFFER_OFFSET  2
#define I2S_VERSION_OFFSET 0
#define I2S_CONFIG_OFFSET  1
#define I2S_DATA_TYPE CPP_CONCAT(CPP_CONCAT(int,I2S_DATA_SIZE),_t)

#define MIC_I2S_BASE 0x40000
static volatile I2S_DATA_TYPE* const i2s_base = (volatile I2S_DATA_TYPE* const )MIC_I2S_BASE;

#endif //I2S_H
