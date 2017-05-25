Software:
Running make in the software directory builds the (modified) .coe file needed for simulation
as well as the .mem file for updating the bitstream. Make sure the software is up-to-date 
before running the simulation script. 

Simulation:
To simulate, first generate the design in Vivado, the run the Vivado simulator. 
From the simulator's TCL command window, enter:
source --quiet sim.tcl
This initializes the block rams with the test.coe file in the software directory.
