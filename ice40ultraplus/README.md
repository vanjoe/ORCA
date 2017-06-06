#Running newly quanitzed networks
`cp qmin.bin min.bin`
Use either  `qmin.bin` (230) opr `qreduced.bin` (400) 
change flag in `software/net.c` to use larger reduced networks

#Running 400 reduced network
`cp reduced.bin min.bin`
change flag in `software/net.c` to use larger reduced network

#Up and running

- run `make` for initial build and to generate `flash.bin`
- initial builds need to run on `avx`, subsquent software rebuilds can run on local machine

- may need to edit xml for flash chip (depends on board) or FTUSB port (depends on what port usb cords in)
`programmer.xcf` `programmer-flash.xcf`

- can generate and save updated `programmer-flash.xcf` via GUI tool @ `/nfs/opt/lattice/programmer/3.8_x64/bin/lin64/programmer`
- choose last option to `open from existing project`, using `programmer-flash.xcf` as base
- click `detect cable` (may still need to try manually, if multiple found)
- double-click `Operation` and change flash chip between `SPI-M25P32` and `SPI-M25P80`
- click `load from file` to get actual `flash.bin` size
- test an ensure it works (try switch cables if multiple found)
- save as `programmer-flash.xcf`
- currently need `pgm-flash` to program board as jumpers switched

- see `./uart0.jpg` `./uart1.jpg` for UART (accessed via `picocom -b 1152000 /dev/ttyUSBX`)

#Building Flash.bin

The flash.bin has the bitstream at offset 0, the golden.bin contents at offset 0x20000 and reduced.bin at offset 0xB0000.

The `make all` command builds the flash.bin out of those three files with the following commands:

```sh
cp ice40ultraplus_Implmnt/sbt/outputs/bitmap/verilog_top_bitmap.bin bits.bin
cp bits.bin flash.bin
truncate --size $(( 0x20000 )) flash.bin
cat golden.bin >> flash.bin
truncate --size $(( 0xB0000 )) flash.bin
cat reduced.bin >> flash.bin
echo -en "\x01\x06\x00" >> flash.bin
```

The last echo command adds a sentinel value at the end of the flash.bin file to tell the programming tools
that this is the end of the file. This allows us to run `make pgm-flash` which programms `flash.bin` into
flash memory.

If you change the offsets for these, you need to change the values both in this makefile and in the software app.

**informational only, probably don't need todo this: If we want to actually boot from flash,we have to swap the spi miso and and mosi pins around in placer.pcf. Right now they are set up so that we can boot from usb**

#Configuration for CIFAR:

* `#define USE_CAM_IMG ` toggles between using the flash saved image (packed into reduced.bin or golden.bin) or the image off the camera

* `#define PRINT_B64_IMG` if set, print out the 32x32 image received from the camera on the uart in base64

* `verbose` local variable in `main()` prints out extra debug information.

#Printing

In normal mode, the riscv app just prints out a sequence of decimal numbers to the uart. The python app on the PC knows which number coresponds to which category and figures out if it is a person from that.

In verbose mode the riscv app also prints the catagory names after each frame.
