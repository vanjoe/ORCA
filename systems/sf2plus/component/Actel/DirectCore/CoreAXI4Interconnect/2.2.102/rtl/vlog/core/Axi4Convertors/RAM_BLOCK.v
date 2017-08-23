`timescale 1ns / 1ns
//--------------------------------------------------
//-- -----------------------------------------------------------------------------
//--    Crevinn Teoranta                                                          
//-- -----------------------------------------------------------------------------
//-- Author      : $Author:                                                  
//-- Date        : $Date:                                    
//-- Revision    : $Revision:                                              
//-- Location    : $URL: $                                                        
//-- -----------------------------------------------------------------------------
//--------------------------------------------------
//
// Description : 
//               
//               
//               
//
//--------------------------------------------------



module RAM_BLOCK #

	(
		parameter integer	MEM_DEPTH	= 1024,
		parameter integer	ADDR_WIDTH	= 10,
		parameter integer	DATA_WIDTH	= 32
	)
	(
		input wire clk,

		input wire wr_en,
		input wire [ADDR_WIDTH-1:0] rd_addr,
		input wire [ADDR_WIDTH-1:0] wr_addr,
		input wire [DATA_WIDTH-1:0] data_in,

		output wire [DATA_WIDTH-1:0] data_out
	);

	reg [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];

	assign data_out = mem[rd_addr];

	always @(posedge clk) begin
		if (wr_en) begin
			mem[wr_addr] <= data_in;
		end
	end

endmodule
