`timescale 1ns / 1ns
//-------------------------------------------------
//-- ----------------------------------------------
//--    Crevinn Teoranta          
//-- -----------------------------------------------
//-- Author      : $Author:       
//-- Date        : $Date:         
//-- Revision    : $Revision:     
//-- Location    : $URL: $        
//-- -----------------------------------------------
//--------------------------------------------------
//
// Description : Generic gray code counter for 
//                clock domain crossing
//
//--------------------------------------------------


module CDC_grayCodeCounter #
  (
    parameter bin_rstValue = 1,
    parameter gray_rstValue = 0,
    parameter integer n_bits = 4
  )
  (
    input wire clk,
    input wire sysRst,

    input wire syncRst,
    input wire inc,

    output wire syncRstOut,
    output reg [n_bits-1:0] cntGray

  );
  
  reg  [n_bits-1:0]  cntBinary;
  wire [n_bits-1:0]  nextGray, cntBinary_next;

  always @ (posedge clk or posedge sysRst)
  begin
  if (sysRst)
    begin
        cntBinary               <= bin_rstValue;
        cntGray                 <= gray_rstValue;
    end
  else
    begin
      if (inc)
      begin
        if (syncRst)
        begin
          cntBinary               <= bin_rstValue;
          cntGray                 <= gray_rstValue;
        end
        else
        begin
          cntBinary                 <= cntBinary_next;
          cntGray                   <= nextGray;
        end
     end	
    end
  end
  
assign cntBinary_next = cntBinary + 1;
assign syncRstOut = (cntBinary == 0);

Bin2Gray #
(
        .n_bits(n_bits)
)
 bin2gray_inst(
        .cntBinary(cntBinary),
        .nextGray(nextGray)
);

endmodule
