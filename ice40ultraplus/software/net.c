#include "neural.h"

#if 1
layer_t cifar[] = {
  {.conv={CONV, RELU, 0, 32, 32, 3, 64, 3, 0, 0, 0, 1, 0}},
  {.conv={CONV, RELU, 0, 32, 32, 64, 64, 3, 1, 0, 0, 1, 0}},
  {.conv={CONV, RELU, 0, 16, 16, 64, 128, 3, 0, 0, 0, 1, 0}},
  {.conv={CONV, RELU, 0, 16, 16, 128, 128, 3, 1, 0, 0, 1, 0}},
  {.conv={CONV, RELU, 0, 8, 8, 128, 256, 3, 0, 0, 0, 1, 0}},
  {.conv={CONV, RELU, 0, 8, 8, 256, 256, 3, 1, 0, 0, 1, 0}},
  {.dense={DENSE, RELU, 0, 256*4*4, 256, 0, 0, 1, 0}},
  {.dense={DENSE, RELU, 0, 256, 256, 0, 0, 1, 0}},
  {.dense={DENSE, LINEAR, 1, 256, 10, 0, 0, 1, 0}},
};
#elif 0
layer_t cifar[] = {
	{.conv={CONV, RELU, 0, 32, 32, 3, 64,  3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 32, 32, 64, 64, 3, 1, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 16, 16, 64, 64, 3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 16, 16, 64, 64, 3, 1, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 8, 8, 64, 128, 3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 8, 8, 128, 128, 3, 1, 0, 0, 1, 0}},
	{.dense={DENSE, RELU, 0, 128*4*4, 128, 0, 0, 1, 0}},
	{.dense={DENSE, RELU, 0, 128, 128, 0, 0, 1, 0}},
	{.dense={DENSE, LINEAR, 1, 128, 10, 0, 0, 1, 0}},
};
#else
layer_t cifar[] = {
	{.conv={CONV, RELU, 0, 32, 32, 3, 48,  3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 32, 32, 48, 48, 3, 1, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 16, 16, 48, 64, 3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 16, 16, 64, 64, 3, 1, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 8, 8, 64, 128, 3, 0, 0, 0, 1, 0}},
	{.conv={CONV, RELU, 0, 8, 8, 128, 128, 3, 1, 0, 0, 1, 0}},
	{.dense={DENSE, RELU, 0, 128*4*4, 32, 0, 0, 1, 0}},
	{.dense={DENSE, RELU, 0, 32, 128, 0, 0, 1, 0}},
	{.dense={DENSE, LINEAR, 1, 128, 10, 0, 0, 1, 0}},
};
#endif
