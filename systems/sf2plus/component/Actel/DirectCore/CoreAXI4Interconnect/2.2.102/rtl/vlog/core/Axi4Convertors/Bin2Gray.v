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
// Description : binary to graycode converter
//                        
//
//--------------------------------------------------


module Bin2Gray #
  (
  parameter integer n_bits = 4
  )
  (
   input wire [n_bits-1:0]  cntBinary,

   output wire [n_bits-1:0] nextGray
  );

  genvar i;
  generate
  for (i = 0; i < (n_bits-1) ; i = i + 1) 
    begin
      assign nextGray[i] = cntBinary[i] ^ cntBinary[i+1];
    end
  endgenerate

  assign nextGray[n_bits-1] = cntBinary[n_bits-1];

endmodule
