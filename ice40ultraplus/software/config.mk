#Since this file is checked in...
-include config.config.mk 

SW_PROJ ?= cifar

ifeq ($(SW_PROJ), cifar)
  C_MAIN = main.c cifar_main.c cifar_scalar.c net.c
  C_LINK = base64.c sccb.c ovm7692.c
else ifeq ($(SW_PROJ), conv)
  C_MAIN = conv_ci_test.c
  C_LINK = 
endif
