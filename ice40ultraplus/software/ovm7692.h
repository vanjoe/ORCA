#ifndef __OVM7692_H_
#define __OVM7692_H_

#define OVM7692_ADDRESS 0x78
#define OVM7692_SUBADDRESS_GAIN  0x00
#define OVM7692_SUBADDRESS_BGAIN 0x01
#define OVM7692_SUBADDRESS_RGAIN 0x02
#define OVM7692_SUBADDRESS_GGAIN 0x03
#define OVM7692_SUBADDRESS_PIDH  0x0A
#define OVM7692_SUBADDRESS_PIDL  0x0B

#define OVM7692_DEFAULT_GAIN  0x00
#define OVM7692_DEFAULT_BGAIN 0x40
#define OVM7692_DEFAULT_RGAIN 0x40
#define OVM7692_DEFAULT_GGAIN 0x40
#define OVM7692_DEFAULT_PIDH  0x76
#define OVM7692_DEFAULT_PIDL  0x92

typedef struct{
	uint8_t addr,val;
} regval_t;
#include "ovm7692_reg.c"

int ovm_initialize(char* red_plane,char* green_plane,char*blue_plane);

int ovm_get_frame();


#endif //def __OVM7692_H_
