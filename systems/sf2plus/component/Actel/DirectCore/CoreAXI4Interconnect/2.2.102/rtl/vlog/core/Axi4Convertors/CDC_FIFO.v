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



module CDC_FIFO #

  (
    parameter integer  MEM_DEPTH            = 4,
    parameter integer  DATA_WIDTH        = 20
  )
  (
    input wire rst,
    input wire clk_wr,
    input wire clk_rd,

    input wire infoInValid,
    input wire readyForOut,

    input wire [DATA_WIDTH-1:0] infoIn,

    output wire [DATA_WIDTH-1:0] infoOut,
    output wire readyForInfo,
    output wire infoOutValid
  );

  genvar i;
  localparam FIFO_ADDR_WIDTH = (MEM_DEPTH < 4) ? 2 : $clog2(MEM_DEPTH);

  reg [FIFO_ADDR_WIDTH-1:0] wrPtr_s1, wrPtr_s2;
  reg [FIFO_ADDR_WIDTH-1:0] rdPtr_s1, rdPtr_s2;
  wire [FIFO_ADDR_WIDTH-1:0] wrPtr;
  wire [FIFO_ADDR_WIDTH-1:0] rdPtr;

  wire [FIFO_ADDR_WIDTH-1:0] wrPtrP1, wrPtrP2;
  wire [FIFO_ADDR_WIDTH-1:0] rdPtrP1;

  wire fifoWe;
  wire fifoRe;
  wire syncRstWrCnt;
  wire syncRstRdCnt;

  RAM_BLOCK #
     (
        .MEM_DEPTH    ( 2**(FIFO_ADDR_WIDTH) ),
        .ADDR_WIDTH   ( FIFO_ADDR_WIDTH ),
        .DATA_WIDTH   ( DATA_WIDTH ) 
     )
     ram (
        .clk          ( clk_wr ),
        .wr_en        ( fifoWe ),
        .wr_addr      ( wrPtr ),
        .rd_addr      ( rdPtr ),
        .data_in      ( infoIn ),
        .data_out     ( infoOut )
    );

  // Write clock domain
  CDC_grayCodeCounter #
    (
	.bin_rstValue ( 1 ),
        .gray_rstValue ( 0 ),
        .n_bits ( FIFO_ADDR_WIDTH )
    )
    wrGrayCounter
    (    
        .clk (clk_wr),
	.sysRst (rst),
	.syncRst (1'b0),
	.inc(fifoWe),
	.cntGray(wrPtr),
	.syncRstOut(syncRstWrCnt)
    );

    CDC_grayCodeCounter #
    (
	.bin_rstValue ( 2 ),
        .gray_rstValue ( 1 ),
        .n_bits ( FIFO_ADDR_WIDTH )
    )
    wrGrayCounterP1
    (    
        .clk (clk_wr),
	.sysRst (rst),
	.syncRst (syncRstWrCnt),
	.inc(fifoWe),
	.cntGray(wrPtrP1),
	.syncRstOut ()
    );

    CDC_grayCodeCounter #
    (
	.bin_rstValue ( 3 ),
        .gray_rstValue ( 3 ),
        .n_bits ( FIFO_ADDR_WIDTH )
    )
    wrGrayCounterP2
    (    
        .clk (clk_wr),
	.sysRst (rst),
	.syncRst (syncRstWrCnt),
	.inc(fifoWe),
	.cntGray(wrPtrP2),
	.syncRstOut ()
    );

    always @(posedge clk_wr or posedge rst) begin
      if (rst) begin
	 rdPtr_s1 <= 0;
	 rdPtr_s2 <= 0;
      end
      else begin
	  rdPtr_s1 <= rdPtr;
	  rdPtr_s2 <= rdPtr_s1;
      end
    end

    CDC_wrCtrl # (
        .ADDR_WIDTH ( FIFO_ADDR_WIDTH )
    )	  
    CDC_wrCtrl_inst (
	    .clk (clk_wr),
	    .rst (rst),
	    .wrPtr_gray (wrPtrP1),
	    .rdPtr_gray (rdPtr_s2),
	    .nextwrPtr_gray (wrPtrP2),
	    .readyForInfo (readyForInfo),

	    .infoInValid (infoInValid),
	    .fifoWe (fifoWe)
    );


  // read clock domain
  CDC_grayCodeCounter #
    (
	.bin_rstValue ( 1 ),
        .gray_rstValue ( 0 ),
        .n_bits ( FIFO_ADDR_WIDTH )
    )
    rdGrayCounter
    (    
        .clk (clk_rd),
	.sysRst (rst),
	.syncRst (1'b0),
	.inc(fifoRe),
	.cntGray(rdPtr),
	.syncRstOut (syncRstRdCnt)
    );

    CDC_grayCodeCounter #
    (
	.bin_rstValue ( 2 ),
        .gray_rstValue ( 1 ),
        .n_bits ( FIFO_ADDR_WIDTH )
    )
    rdGrayCounterP1
    (    
        .clk (clk_rd),
	.sysRst (rst),
	.syncRst (syncRstRdCnt),
	.inc(fifoRe),
	.cntGray(rdPtrP1),
	.syncRstOut ()
    );

    always @(posedge clk_rd or posedge rst) begin
      if (rst) begin
	 wrPtr_s1 <= 0;
	 wrPtr_s2 <= 0;
      end
      else begin
	  wrPtr_s1 <= wrPtr;
	  wrPtr_s2 <= wrPtr_s1;
      end
    end

    CDC_rdCtrl # (
        .ADDR_WIDTH ( FIFO_ADDR_WIDTH )
    )	   
    CDC_rdCtrl_inst (
	    .clk (clk_rd),
	    .rst (rst),
	    .rdPtr_gray (rdPtr),
	    .wrPtr_gray (wrPtr_s2),
	    .nextrdPtr_gray (rdPtrP1),
	    .readyForOut (readyForOut),

	    .infoOutValid (infoOutValid),
	    .fifoRe (fifoRe)
    );

endmodule

