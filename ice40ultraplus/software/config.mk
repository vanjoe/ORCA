#Since this file is checked in...
-include config.config.mk 

SW_PROJ ?= cifar_vector

ifeq ($(SW_PROJ), cifar_vector)
  C_MAIN = main.c cifar_main.c cifar_vector.c net.c
  C_LINK = base64.c sccb.c ovm7692.c
else ifeq ($(SW_PROJ), cifar_scalar)
  C_MAIN = main.c cifar_main.c cifar_scalar.c net.c
  C_LINK = base64.c sccb.c ovm7692.c
else ifeq ($(SW_PROJ), lve_test)
  C_MAIN = lve_test.c
  C_LINK = 
else ifeq ($(SW_PROJ), conv)
  C_MAIN = conv_ci_test.c
  C_LINK = 
endif
