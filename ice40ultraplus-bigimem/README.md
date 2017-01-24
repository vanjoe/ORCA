
# RISC-V Ultraplus System


## Memory System

The System has 4 wishbone masters, Camera, Flash DMA, ORCA instruction, and ORCA data.

They are connected to the various slaves according to the following table

    |       |                  MASTER              |                |
    |       | cam  | flash | orca-data | orca-instr| Address        |
    |SLAVE  |------|-------|-----------|-----------|----------------|
    |boot   |      |       |           |     X     | 0 -0x3FF       |
    |imem   |      |   X   |      X    |     X     | 0x10000-0x1FFFF|
    |dmem   |  X   |   X   |      X    |           | 0x20000-0x2FFFF|
    |uart   |      |       |      X    |           | 0x100000       |
    |pio    |      |       |      X    |           | 0x110000       |
    |flash  |      |       |      X    |           | 0x120000       |


The boot memory is a ROM that is preconfigured in the bitstream,it is responsible with initializing the
larger imem and dmem rams. The Boot ROM is not readable or writable by any other port other than
the instruction port.The Orca Data port can talk to all of the other slaves.

## Building the system

### Environment Setup

In this directory, change the file Makefile so that the ICECUBE2 variable points to the correct
directory where your icecube2 tools are installed.

If you want to simulate using Modelsim, you must do the same thing in the `simulate.tcl` script.

Make sure that the risc-v tools are included in your path.
Then run Make

### Building

The make command should build a few important files: *ice40up\_mdp\_16MHz\_Implmnt/sbt/outputs/bitmap/verilog\_top\_bitmap.bin* and *flash.bin*
The *verilog_top_bitmap.bin* is the bitstream that configures the FPGA, and
*flash.bin* contains the software that will be copied to the SPRAMs, and then executed.
The `flash.mem` file contains the same contents as `flash.bin`, except in hex format, it is
used for simulation.

Note one of the last things that make prints out is something like `65920 flash.bin` this is
the size of that file. Take note of that.

### Simulating

Running `vsim -do simulate.tcl` Should start modelsim,compile all the relevant rtl files,
and add some important signals to the waveform.

### Running

make sure the jumpers J19 are in the `PROG ICE` position.

There is a quirk with the programming tool where it confuses the size of the file, so we couldn't find a
good solution for automating programming the flash.

Here are the steps to program the flash

1. Open Diamond Programmer V3.8, Choose blank project

2. Configure Device Family = "ICE40 UltraPlus" Device= "iCE40UP5K"

3. Double click in the Operation Box in the table.

4. Choose SPI Flash Programming as your Access Mode.

5. Choose the *flash.bin* as your Programming file.

6. Choose, Vendor="Micron" Device="M25P80"

7. Choose 0x30000 as End Address

8. Type the size of flash.bin in the Data File size. (Load from file gives wrong value)

9. Press Ok

10. Click Program.


To Program the FPGA:

1. Perform steps 1-3 of the previous List

2. Select *ice40up\_mdp\_16MHz\_Implmnt/sbt/outputs/bitmap/verilog\_top\_bitmap.bin* as the Filename

3. Click Program.


The FPGA should now be programmed.

At this point the TXD pin should be printing data, at 115200 BAUD.
