#include "neural.h"


layer_t cifar_golden[] = {
	{.conv={CONV, RELU, 0, 32, 32, 3, 64, 0, GOLDEN_FLASH_DATA_OFFSET+3072, 1, 1}},
	{.conv={CONV, RELU, 0, 32, 32, 64, 64, 1, GOLDEN_FLASH_DATA_OFFSET+69504, 1, 1}},
	{.conv={CONV, RELU, 0, 16, 16, 64, 128, 0, GOLDEN_FLASH_DATA_OFFSET+94592, 1, 1}},
	{.conv={CONV, RELU, 0, 16, 16, 128, 128, 1, GOLDEN_FLASH_DATA_OFFSET+144768, 1, 1}},
	{.conv={CONV, RELU, 0, 8, 8, 128, 256, 0, GOLDEN_FLASH_DATA_OFFSET+186752, 1, 1}},
	{.conv={CONV, RELU, 0, 8, 8, 256, 256, 1, GOLDEN_FLASH_DATA_OFFSET+270720, 1, 0}},
	{.dense={DENSE, RELU, 0, 4096, 256, GOLDEN_FLASH_DATA_OFFSET+420224, GOLDEN_FLASH_DATA_OFFSET+551296, 1, GOLDEN_FLASH_DATA_OFFSET+552320}},
	{.dense={DENSE, RELU, 0, 256, 256, GOLDEN_FLASH_DATA_OFFSET+554368, GOLDEN_FLASH_DATA_OFFSET+562560, 1, GOLDEN_FLASH_DATA_OFFSET+563584}},
	{.dense={DENSE, LINEAR, 1, 256, 10, GOLDEN_FLASH_DATA_OFFSET+565632, GOLDEN_FLASH_DATA_OFFSET+565952, 1, GOLDEN_FLASH_DATA_OFFSET+565992}},
};

layer_t cifar_reduced[] = {
	{.conv={CONV, RELU, 0, 32, 32, 3, 48, 0, REDUCED_FLASH_DATA_OFFSET+3072, 1, 1}},
	{.conv={CONV, RELU, 0, 32, 32, 48, 48, 1, REDUCED_FLASH_DATA_OFFSET+52896, 1, 1}},
	{.conv={CONV, RELU, 0, 16, 16, 48, 96, 0, REDUCED_FLASH_DATA_OFFSET+70176, 1, 1}},
	{.conv={CONV, RELU, 0, 16, 16, 96, 96, 1, REDUCED_FLASH_DATA_OFFSET+104736, 1, 1}},
	{.conv={CONV, RELU, 0, 8, 8, 96, 128, 0, REDUCED_FLASH_DATA_OFFSET+130080, 1, 1}},
	{.conv={CONV, RELU, 0, 8, 8, 128, 128, 1, REDUCED_FLASH_DATA_OFFSET+163872, 1, 0}},
	{.dense={DENSE, RELU, 0, 2048, 256, REDUCED_FLASH_DATA_OFFSET+205856, REDUCED_FLASH_DATA_OFFSET+271392, 1, REDUCED_FLASH_DATA_OFFSET+272416}},
	{.dense={DENSE, RELU, 0, 256, 256, REDUCED_FLASH_DATA_OFFSET+274464, REDUCED_FLASH_DATA_OFFSET+282656, 1, REDUCED_FLASH_DATA_OFFSET+283680}},
	{.dense={DENSE, LINEAR, 1, 256, 10, REDUCED_FLASH_DATA_OFFSET+285728, REDUCED_FLASH_DATA_OFFSET+286048, 1, REDUCED_FLASH_DATA_OFFSET+286088}},
};
