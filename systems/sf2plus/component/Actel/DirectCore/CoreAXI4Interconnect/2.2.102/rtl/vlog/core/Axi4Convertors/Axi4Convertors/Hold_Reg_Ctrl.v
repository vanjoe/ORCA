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
// Description : Controls generic holding registers
//               
//               
//               
//
//--------------------------------------------------



module Hold_Reg_Ctrl

  (
    input wire rst,
    input wire clk,

		input wire src_data_valid, //!fifo_empty,
		input wire get_next_data_hold,
		
    
		output wire pass_data,
		output wire get_next_data_src, //fifo_rd_en,
		output reg  hold_data_valid //!hold_reg_empty

  );

	// Allow data into holding register when data is being taken from the holding register OR the holding register is empty.
	assign pass_data = (get_next_data_hold | !hold_data_valid);
	
	// Read more data from the source as there is data available at the source and we're passing the previous data to the holding register.
	assign get_next_data_src = (src_data_valid & pass_data); 
	
  always @(posedge clk or posedge rst) begin
    if (rst) begin
       hold_data_valid <= 'b0;
			end
    else begin
    // When passing data, indicate that data in the holding register is valid if source data was valid.
			if (pass_data)	hold_data_valid <= src_data_valid;

    end
  end

endmodule

