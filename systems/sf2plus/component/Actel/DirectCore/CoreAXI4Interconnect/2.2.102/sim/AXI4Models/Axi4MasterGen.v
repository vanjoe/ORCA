// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Master test source. It initialiates a Master transmission.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

module Axi4MasterGen # 
	(

		parameter [3:0]		MASTER_NUM				= 0,		// slaive number
		parameter integer 	ID_WIDTH   				= 2, 

		parameter integer 	ADDR_WIDTH      		= 20,				
		parameter integer 	DATA_WIDTH 				= 16, 

		parameter integer 	SUPPORT_USER_SIGNALS 	= 0,
		parameter integer 	USER_WIDTH 				= 1,
		
		parameter integer 	OPENTRANS_MAX			= 1,			// Number of open transations width - 1 => 2 transations, 2 => 4 transations, etc.

		parameter	HI_FREQ							= 0				// increases freq of operation at cost of added latency
		
	)
	(
		// Global Signals
		input  wire                         sysClk,
		input  wire                       	ARESETN,			// active high reset synchronoise to RE AClk - asserted async.
   
		//====================== Master Read Address Ports  ================================================//
		// Master Read Address Ports
		output  reg [ID_WIDTH-1:0]        	MASTER_ARID,
		output  reg [ADDR_WIDTH-1:0]      	MASTER_ARADDR,
		output  reg [7:0]                 	MASTER_ARLEN,
		output  reg [2:0]                 	MASTER_ARSIZE,
		output  reg [1:0]                 	MASTER_ARBURST,
		output  reg [1:0]                 	MASTER_ARLOCK,
		output  reg [3:0]                 	MASTER_ARCACHE,
		output  reg [2:0]                 	MASTER_ARPROT,
		output  reg  [3:0]                	MASTER_ARREGION,		// not used
		output  reg  [3:0]                	MASTER_ARQOS,			// not used
		output  reg [USER_WIDTH-1:0]      	MASTER_ARUSER,
		output  reg                       	MASTER_ARVALID,
		input 	wire                    		MASTER_ARREADY,
		
		// Master Read Data Ports
		input wire [ID_WIDTH-1:0]      	  	MASTER_RID,
		input wire [DATA_WIDTH-1:0]        	MASTER_RDATA,
		input wire [1:0]                    MASTER_RRESP,
		input wire                          MASTER_RLAST,
		input wire [USER_WIDTH-1:0]         MASTER_RUSER,
		input wire                          MASTER_RVALID,
		output reg                          MASTER_RREADY,
 
 		// Master Write Address Ports
		output  reg [ID_WIDTH-1:0]        	MASTER_AWID,
		output  reg [ADDR_WIDTH-1:0]      	MASTER_AWADDR,
		output  reg [7:0]                 	MASTER_AWLEN,
		output  reg [2:0]                 	MASTER_AWSIZE,
		output  reg [1:0]                 	MASTER_AWBURST,
		output  reg [1:0]                 	MASTER_AWLOCK,
		output  reg [3:0]                 	MASTER_AWCACHE,
		output  reg [2:0]                 	MASTER_AWPROT,
		output  reg [3:0]                 	MASTER_AWREGION,		// not used
		output  reg [3:0]                 	MASTER_AWQOS,			// not used
		output  reg [USER_WIDTH-1:0]      	MASTER_AWUSER,
		output  reg                       	MASTER_AWVALID,
		input 	wire                  		  MASTER_AWREADY,
		
		// Master Write Data Ports
		output reg [DATA_WIDTH-1:0]     	  MASTER_WDATA,
		output reg [(DATA_WIDTH/8)-1:0]     MASTER_WSTRB,
		output reg                          MASTER_WLAST,
		output reg [USER_WIDTH-1:0]         MASTER_WUSER,
		output reg                          MASTER_WVALID,
		input  wire                         MASTER_WREADY,
  
		// Master Write Response Ports
		input  wire [ID_WIDTH-1:0]		    	MASTER_BID,
		input  wire [1:0]                   MASTER_BRESP,
		input  wire [USER_WIDTH-1:0]        MASTER_BUSER,
		input  wire      	                  MASTER_BVALID,
		output reg	  	                    MASTER_BREADY,
   
		// ===============  Control Signals  =======================================================//
		input wire				   	  		MASTER_RREADY_Default,  	// defines whether Master asserts ready or waits for RVALID
		input wire				     			MASTER_WREADY_Default,  	// defines whether Master asserts ready or waits for wVALID
		input wire					     		d_MASTER_BREADY_default,
		input wire							    rdStart,									// defines whether Master starts a transaction
		input wire [7:0]				   	rdBurstLen,								// burst length of read transaction
		input wire [ADDR_WIDTH-1:0]	rdStartAddr,							// start addresss for read transaction
		input wire [ID_WIDTH-1:0]		rdAID,					  				// AID for read transactions
		input wire [2:0]				  	rdASize,									// each transfer size
		input wire [1:0]				  	expRResp,									// indicate Read Respons expected
		
		output reg					    		masterRdAddrDone,		// Address Read transaction has been completed
		output reg				    			masterRdDone,		  	// Asserted when a read transaction has been completed
		output reg					    		masterRdStatus,			// Status of read transaction - Pass =1, Fail=0. Only valid when masterRdDone asserted
		output reg					    		mstRAddrIdle,		  	// indicates Read Address Bus is idle
  
		input wire					    		wrStart,			 			// defines whether Master starts a transaction
		input wire [1:0]			  		BurstType,					// Type of burst - FIXED=00, INCR=01, WRAP=10 
		input wire [7:0]			  		wrBurstLen,					// burst length of write transaction
		input wire [ADDR_WIDTH-1:0]	wrStartAddr,				// start addresss for write transaction
		input wire [ID_WIDTH-1:0]		wrAID,						  // AID for write transactions
		input wire [2:0]					  wrASize,				  	// each transfer size
		input wire [1:0]					  expWResp,				  	// indicate Read Respons expected
		
		output reg									masterWrAddrDone,		// Address Write transaction has been completed
		output reg									masterWrDone,		  	// Asserted when a write transaction has been completed
		output reg									masterRespDone,			// Asserted when a write response transaction has completed
		output reg									masterWrStatus,			// Status of read transaction - Pass =1, Fail=0. Only valid when masterRespDone asserted
		output reg									mstWAddrIdle,		  	// indicates Read Address Bus is idle
		output wire									mstWrAddrFull,			// Asserted when the internal queue for writes are full
		output wire									mstRdAddrFull		  	// Asserted when the internal queue for writes are full

		
	);

//================================================================================================
// Local Parameters
//================================================================================================
 
localparam	READFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 

localparam	[2:0]		MASTER_ASIZE_DEFAULT	= 	(DATA_WIDTH == 'd16) ? 3'h1 :
													(DATA_WIDTH == 'd32) ? 3'h2 :
													(DATA_WIDTH == 'd64) ? 3'h3 :
													(DATA_WIDTH == 'd128) ? 3'h4 :
													(DATA_WIDTH == 'd256) ? 3'h5 :
													(DATA_WIDTH == 'd512) ? 3'h6 :
													(DATA_WIDTH == 'd1024) ? 3'h7 :
														3'b000;		// not supported

wire						fifoOverRunErr, fifoUnderRunErr;
	
reg [READFIF_WIDTH-1:0]		readFifWrData;
wire [READFIF_WIDTH-1:0]	readFifRdData;

reg							readFifWr, readFifRd;
wire						readFifoFull, readFifoEmpty;
 
reg [15:0]					arCount, d_arCount; 
reg [15:0]					rdCount, d_rdCount; 

reg [5:0]					wAddrMask;

  wire [4:0]   rd_addr_beat;
  wire [4:0]   rd_to_boundary_master;
   wire      [9:0]  ReadAddrMaskWrap;


//====================================================================================================
// Local Declarationes for Master Read Address 
//====================================================================================================

localparam	[2:0]		rstIDLE = 3'h0,	rstDATA = 3'h1;

reg						d_MASTER_RREADY;

reg [2:0]				rcurrState, rnextState;

reg [ID_WIDTH-1:0]		transID;
reg [1:0]			burstType;

reg	[DATA_WIDTH-1:0]	d_rxLen, rxLen;

reg [7:0]				burstLen;
reg [2:0] burstSize;
wire [5:0] ReadAddrMask;
wire [ADDR_WIDTH-1:0]	startRdAddr;
reg [ADDR_WIDTH-1:0]	curRdAddr, d_curRdAddr;

reg [DATA_WIDTH-1:0]	rDataMask;
wire [DATA_WIDTH-1:0] shift_dataMask;
wire [DATA_WIDTH-1:0] mask_rDataMask;
wire [DATA_WIDTH-1:0] mask_rDataMask_exp;
wire [10:0] shift_fixed;
wire [DATA_WIDTH-1:0] addr_shift;
wire [DATA_WIDTH-1:0] exp_mask_shift;

wire					sysReset;

wire [DATA_WIDTH-1:0] baseValue;

reg [8:0] rdata_rand_sig;
reg [8:0] bready_rand_sig;

wire[5:0] align_addr_32;
wire[5:0] align_addr;
wire[31:0] mask_unalign;

genvar i;

generate
for (i=0; i<(DATA_WIDTH/8);i=i+1) begin
	assign baseValue[(8*i)+:8] = i;
end
endgenerate

assign shift_fixed = ((burstType == 2'b00) && (MASTER_ARSIZE > 2) && (((2**MASTER_ARSIZE) -  ((curRdAddr[5:0]) & ((2**MASTER_ARSIZE) - 1))) > 4)) ? ((8*((2**MASTER_ARSIZE)-(align_addr & 6'h3c))) - 32) : 0;

//=======================================================================================================================
// Local system reset - asserted asynchronously to ACLK and deasserted synchronous
//=======================================================================================================================
ResetSycnc  
	rsync(
			.sysClk	( sysClk ),
			.sysReset_L( ARESETN ),			// active low reset synchronoise to RE AClk - asserted async.
			.sysReset( sysReset  )			// active high sysReset synchronised to ACLK
	);


//=====================================================================================================
// Compute Mask for mis-aligned data
//=====================================================================================================
always @( * )
	begin
		rDataMask <= { DATA_WIDTH{1'b0}  };		// initialise mask to all invalid

  // The below case statement(DATA_WIDTH) allows the mask to be applied properly.
  // The size of the bus determines the max transfer size
  case (DATA_WIDTH)
    // The case statement (MASTER_ARSIZE) applies the 1's to the appropriate part of the mask
    // by shifting in a defined number of 1's to the appropriate location.
    // Indexing is multiplied (by 8, 16, 32, 64, 128, 256) as the mask is set on a 'per-bit' basis.
    'd32 :  case(MASTER_ARSIZE)
             3'b000 : rDataMask[(8*curRdAddr[1:0]) +: 8] <= {1{8'hff}};
             3'b001 : rDataMask[(16*curRdAddr[1]) +: 16] <= {2{8'hff}};
             3'b010 : rDataMask[31 : 0] <= {4{8'hff}};
            endcase
    'd64 :  case (MASTER_ARSIZE)
             3'b000 : rDataMask[(8*curRdAddr[2:0]) +: 8]   <= {1{8'hff}};
             3'b001 : rDataMask[(16*curRdAddr[2:1]) +: 16] <= {2{8'hff}};
             3'b010 : rDataMask[(32*curRdAddr[2]) +: 32]   <= {4{8'hff}};
             3'b011 : rDataMask[63 : 0] <= {8{8'hff}};
            endcase
    'd128 : case (MASTER_ARSIZE)
             3'b000 : rDataMask[(8*curRdAddr[3:0]) +: 8]   <= {1{8'hff}};
             3'b001 : rDataMask[(16*curRdAddr[3:1]) +: 16] <= {2{8'hff}};
             3'b010 : rDataMask[(32*curRdAddr[3:2]) +: 32] <= {4{8'hff}};
             3'b011 : rDataMask[(64*curRdAddr[3]) +: 64]   <= {8{8'hff}};
             3'b100 : rDataMask[127 : 0] <=  {16{8'hff}};
            endcase
    'd256 : case (MASTER_ARSIZE)
             3'b000 : rDataMask[(8*curRdAddr[4:0]) +: 8]     <= {1{8'hff}};
             3'b001 : rDataMask[(16*curRdAddr[4:1]) +: 16]   <= {2{8'hff}};
             3'b010 : rDataMask[(32*curRdAddr[4:2]) +: 32]   <= {4{8'hff}};
             3'b011 : rDataMask[(64*curRdAddr[4:3]) +: 64]   <= {8{8'hff}};
             3'b100 : rDataMask[(128*curRdAddr[4]) +: 128]   <= {16{8'hff}};
             3'b101 : rDataMask[255 : 0] <= {32{8'hff}};
            endcase
    'd512 : case (MASTER_ARSIZE)
             3'b000 : rDataMask[(8*curRdAddr[5:0]) +: 8]     <= {1{8'hff}};
             3'b001 : rDataMask[(16*curRdAddr[5:1]) +: 16]   <= {2{8'hff}};
             3'b010 : rDataMask[(32*curRdAddr[5:2]) +: 32]   <= {4{8'hff}};
             3'b011 : rDataMask[(64*curRdAddr[5:3]) +: 64]   <= {8{8'hff}};
             3'b100 : rDataMask[(128*curRdAddr[5:4]) +: 128] <= {16{8'hff}};
             3'b101 : rDataMask[(256*curRdAddr[5]) +: 256]   <= {32{8'hff}};
             3'b110 : rDataMask[511 : 0] <= {64{8'hff}};
            endcase
  endcase
end

//=============================================================================================
// Display messages only in Simulation - not synthesis
//=============================================================================================
`ifdef SIM_MODE
	
	//============================================================================================
	// Display messages for Read Address Channel	
	//=============================================================================================
	always @( posedge sysClk )
		begin
			#1;

			if ( MASTER_ARVALID )
				begin
					#1 $display( "%d, MASTER  %d - Starting Read Address Transaction %d, ARADDR= %h, ARBURST= %h, ARSIZE= %h, AID= %h, RXLEN= %d", 
											$time, MASTER_NUM, arCount, MASTER_ARADDR, MASTER_ARBURST, MASTER_ARSIZE, MASTER_ARID, MASTER_ARLEN );

					if ( MASTER_ARREADY )		// single beat
						begin
							#1 $display( "%d, MASTER  %d - Ending Read Address Transaction %d, AID= %h, RXLEN= %d", 
											$time, MASTER_NUM, arCount, MASTER_ARID, MASTER_ARLEN );
						end
					else
						begin
							@( posedge MASTER_ARREADY )
								#1 $display( "%d, MASTER  %d - Ending Read Address Transactions %d, AID= %h, RXLEN= %d", 
											$time, MASTER_NUM, arCount, MASTER_ARID, MASTER_ARLEN );
						end
				end
		end


		//=============================================================================================
		// Display messages for Read Data Channel
		//=============================================================================================
		always @( posedge sysClk )
			begin
				#1;

				if ( MASTER_RVALID )
					begin
						#1 $display( "%d, MASTER %d - Starting Read Data Transaction %d, RADDR= %h (%d), AID= %h, RXLEN= %d", 
										$time, MASTER_NUM, rdCount, curRdAddr, curRdAddr, MASTER_RID, burstLen );

						if ( MASTER_RLAST & MASTER_RVALID & MASTER_RREADY )		// single beat
							begin
								#1 $display( "%d, MASTER %d - Ending Read Data Transaction %d, AID= %h, RXLEN= %d", 
										$time, MASTER_NUM, rdCount, MASTER_RID, burstLen );
							end
						else
							begin
								@( posedge ( MASTER_RLAST & MASTER_RVALID & MASTER_RREADY ) )
									#1 $display( "%d, MASTER %d - Ending Read Data Transactions %d, AID= %h, RXLEN= %d, RRESP= %h", 
										$time, MASTER_NUM, rdCount, MASTER_RID, burstLen, MASTER_RRESP );
							end
					end
			end


		//=============================================================================================
		// Display messages for Read Data 
		//=============================================================================================
		always @( negedge sysClk )
			begin
				#1;

				if ( MASTER_RVALID & MASTER_RREADY )
					begin
						#1
						`ifdef VERBOSE
							$display( "%d, MASTER %d DATA: - RADDR= %h (%d), exp RDATA= %h, mask= %h, act RDATA= %h", $time, MASTER_NUM, 
												curRdAddr, curRdAddr, (rxLen+ MASTER_NUM + baseValue ), rDataMask & mask_rDataMask, MASTER_RDATA  );					
						`endif

						//===========================================================
						// For first beat in burst Mask out unused bytes
						//===========================================================
						
						if ( ( ( MASTER_RDATA & rDataMask & mask_rDataMask )!== ( (rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) ) & (expRResp == 0 ) & (burstType != 2'b00)  )
							begin
								$display( "%d, MASTER %d DATA ERROR - RADDR= %h (%d) exp RDATA= %h, mask= %h, act RDATA= %h", 
												$time, MASTER_NUM, curRdAddr, curRdAddr, ( rxLen+ MASTER_NUM + baseValue  ), rDataMask & mask_rDataMask, MASTER_RDATA  );
                $display( "360\t\t\trxLen: %h, d_rxLen: %h, MASTER_NUM: %h, MASTER_ARLEN: %h", rxLen, d_rxLen, MASTER_NUM, MASTER_ARLEN );

								masterRdStatus 	<= 0;
									
								if ( expRResp == 0 )		// if expect no error
									begin
										#1 $stop;
									end
							end
						else if ( ( ((( MASTER_RDATA  >> shift_fixed) & rDataMask ) & mask_rDataMask & (mask_unalign << 8*align_addr_32)  )!== ( ( (burstLen + MASTER_NUM + baseValue) & rDataMask  & mask_rDataMask_exp ) >> shift_fixed) ) & (expRResp == 0 ) & (burstType == 2'b00)  )
							begin
								$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h", $time, MASTER_NUM, 
												( ( (burstLen + MASTER_NUM + baseValue) & rDataMask  & mask_rDataMask_exp ) >> shift_fixed), ((( MASTER_RDATA  >> shift_fixed) & rDataMask ) & mask_rDataMask & (mask_unalign << 8*align_addr_32)  )  );
								masterRdStatus 	<= 0;
								if ( expRResp == 0 )		// if expect no error
									begin
										#1 $stop;
									end		
							end
					end
			end
`endif


 //===========================================================================================
 // FIFO to hold open transactions - pushed on Address Read cycle and popped on read data
 // cycle.
 //===========================================================================================
 FifoDualPort #(	.FIFO_AWIDTH( OPENTRANS_MAX ),
					.FIFO_WIDTH( READFIF_WIDTH ),
					.HI_FREQ( HI_FREQ ),
					.NEAR_FULL( 'd2 )
				)
		slFif(
					.HCLK(	sysClk ),
					.fifo_reset( sysReset ),

					// Write Port
					.fifoWrite( readFifWr ),
					.fifoWrData( readFifWrData ),

					// Read Port
					.fifoRead( readFifRd ),
					.fifoRdData( readFifRdData ),

					// Status bits
					.fifoEmpty ( readFifoEmpty ) ,
					.fifoOneAvail(   ),
					.fifoRdValid(  ),
					.fifoFull( readFifoFull ),
					.fifoNearFull( ),
					.fifoOverRunErr( fifoOverRunErr ),
					.fifoUnderRunErr( fifoUnderRunErr )
				   
				);

assign mstRdAddrFull = readFifoFull;
assign startRdAddr	= readFifRdData[READFIF_WIDTH- ID_WIDTH-1: READFIF_WIDTH- ID_WIDTH- ADDR_WIDTH];

// align address to 32 bit boundary if TxSize > 32, align to TxSize otherwise
assign align_addr_32 = (((DATA_WIDTH/8)-1) & ( (MASTER_ARSIZE > 2) ? (curRdAddr[5:0] & 6'h3c) : (curRdAddr[5:0] & ~((1<<MASTER_ARSIZE)-1)) ));

// unalignement offset
assign align_addr = (curRdAddr[5:0] & ((1<<MASTER_ARSIZE)-1));

// valid bit within a 32 bit word for fixed
assign mask_unalign = 32'hffffffff << (curRdAddr[1:0] << 3);

// 
assign shift_dataMask = (((2**MASTER_ARSIZE) -  ((curRdAddr[5:0]) & ((2**MASTER_ARSIZE) - 1))) > 4) ? (8*(align_addr-4 + (DATA_WIDTH/8-addr_shift/8))) : 0;

// received data mask (mask out all bits but last 32 received bits
assign mask_rDataMask = ((burstType == 2'b00) && ( MASTER_ARSIZE > 2)) ? ((~((1 << addr_shift)-1))) : ~((1 << (8*(curRdAddr[5:0] & (DATA_WIDTH/8-1))))-1);

// expected data mask (mask out all bits but upper 32 valid bits)
assign mask_rDataMask_exp = ((burstType == 2'b00) && (MASTER_ARSIZE > 2)) ? (~((1 << addr_shift)-1)  << exp_mask_shift) : ~((1 << (8*(curRdAddr[5:0] & (DATA_WIDTH/8-1))))-1);

// address byte to bits within a word
assign addr_shift = (8*((curRdAddr[5:0]) & (DATA_WIDTH/8-1)));

// amount to shift the exp data mask by if TxSize > 32 bit
assign exp_mask_shift = (((2**MASTER_ARSIZE) -  ((curRdAddr[5:0]) & ((2**MASTER_ARSIZE) - 1))) > 4) ? ((8*((2**MASTER_ARSIZE)-(align_addr & 6'h3c))) - 32) : 0;

assign ReadAddrMaskWrap = (10'h3ff << $clog2((rdBurstLen+1) * (1 << rdASize)));

  assign rd_addr_beat = rdStartAddr[rdASize+:4] & rdBurstLen;
  assign rd_to_boundary_master = (rdBurstLen + 1) - rd_addr_beat;

//====================================================================================================
// Master Read Data S/M
//===================================================================================================== 
 always @( * )
 begin
 
 	#1;	// wait for inputs to "settle" - issue as "display" stmts 
	rnextState <= rcurrState;

	d_MASTER_RREADY	<= MASTER_RREADY_Default;
	readFifRd		<= 0;

	masterRdStatus	<= 1;

	d_rxLen 	<= rxLen;

	transID		= readFifRdData[READFIF_WIDTH-1: READFIF_WIDTH-ID_WIDTH];
	burstLen	= readFifRdData[READFIF_WIDTH- ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH- ID_WIDTH- ADDR_WIDTH -8];
  burstSize = readFifRdData[4:2];
	burstType	= readFifRdData[1:0];

	d_curRdAddr	<= curRdAddr;

	masterRdDone	<= 0;

	d_rdCount	<= rdCount;


  

	case( rcurrState )
		rstIDLE: begin
					d_MASTER_RREADY <= MASTER_RREADY_Default;

					masterRdStatus 	<= 1;
					d_rxLen 		<= 0;

					d_curRdAddr <= startRdAddr;
					
					if ( MASTER_RVALID & MASTER_RREADY & MASTER_RLAST )		// only 1 beat
						begin
							d_MASTER_RREADY	<= MASTER_RREADY_Default;

							transID		= readFifRdData[READFIF_WIDTH-1: READFIF_WIDTH-ID_WIDTH];
							burstLen	= readFifRdData[READFIF_WIDTH- ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH- ID_WIDTH- ADDR_WIDTH -8];

							if ( readFifoEmpty )
								begin

									$display( "%d, MASTER %d ERROR - Read Data cycle with no Read Address Pending", $time, MASTER_NUM );
									masterRdStatus 	<= 0;
									#1 $stop;
								end	
								
							if ( transID != MASTER_RID )
								begin
								
									$display( "%d, MASTER %d ERROR - exp RID= %h, act RID= %h", $time, MASTER_NUM, transID, MASTER_RID );
									
									masterRdStatus 	<= 0;
									#1 $stop;
								end
				
							if ( burstLen != rxLen )
								begin
									$display( "%d, MASTER %d ERROR - exp rxLen= %h, act rxLen= %h", $time, MASTER_NUM, burstLen, rxLen );

									masterRdStatus 	<= 0;

									#1 $stop;
								end		
							
							if ( MASTER_RRESP != expRResp )
								begin
									$display( "%d, MASTER %d ERROR - expRResp= %h, act RRESP= %h", $time, MASTER_NUM, 
													expRResp, MASTER_RRESP );
									masterRdStatus 	<= 0;

									#1 $stop;
							end		

							if ( ( ( MASTER_RDATA & rDataMask & mask_rDataMask )!== ( (rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) ) & (expRResp == 0 ) & (burstType != 2'b00)  )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h, mask= %h, curRdAddr= %h", $time, MASTER_NUM, 
												(rxLen+ MASTER_NUM + baseValue ), MASTER_RDATA, rDataMask & mask_rDataMask, curRdAddr );
									masterRdStatus 	<= 0;
									#1 $stop;
								end	

							else if ( ( ( ( (MASTER_RDATA >> shift_fixed) & rDataMask  ) & mask_rDataMask & (mask_unalign << 8*align_addr_32) )!== ( ((rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) >> shift_fixed) ) & (expRResp == 0 ) & (burstType == 2'b00)  )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h, mask= %h, exp_mask= %h, curRdAddr= %h", $time, MASTER_NUM, 
												(((rxLen+ MASTER_NUM + baseValue ) & rDataMask & mask_rDataMask_exp ) >> shift_fixed), (MASTER_RDATA  >> shift_fixed) & rDataMask & mask_rDataMask & (mask_unalign << 8*align_addr_32), rDataMask & mask_rDataMask & (mask_unalign << 8*align_addr_32), rDataMask & mask_rDataMask_exp, curRdAddr );
									masterRdStatus 	<= 0;
									#1 $stop;
								end	
								
							masterRdDone	<= 1;
							readFifRd		<= 1;				// pop open transaction
							
							d_rdCount	<= rdCount + 1'b1;
	
							rnextState	<= rstIDLE;
						end
					else if ( MASTER_RVALID & MASTER_RREADY & !MASTER_RLAST  )
						begin
							d_MASTER_RREADY	<= MASTER_RREADY_Default;
	
							d_rxLen <= rxLen + 1'b1;

		if (burstType == 2'b00) begin
			d_curRdAddr <= curRdAddr;
		end
                  else if (burstType == 2'b10) begin
                if (rxLen == (rd_to_boundary_master-1)) begin
                d_curRdAddr <= { curRdAddr[ADDR_WIDTH-1:10], (curRdAddr[9:0] & ReadAddrMaskWrap)};
                end else begin
                d_curRdAddr <= curRdAddr + (1 << burstSize);
                end
              end
		else begin
							d_curRdAddr	<= { curRdAddr[ADDR_WIDTH-1:6], (curRdAddr[5:0] & ReadAddrMask) }  + (1 << burstSize);		// aligned address 						
						end
							
							if ( readFifoEmpty )
								begin
								
									$display( "%d, MASTER %d ERROR - Read Data cycle with no Read Address Pending", $time, MASTER_NUM );
									masterRdStatus 	<= 0;
									#1 $stop;

								end	
								
							if ( transID != MASTER_RID )
								begin

									$display( "%d, MASTER %d ERROR - exp RID= %h, act RID= %h", $time, MASTER_NUM, transID, MASTER_RID );
									masterRdStatus 	<= 0;
									#1 $stop;
								end
								
							if ( MASTER_RRESP != expRResp )
								begin
									$display( "%d, MASTER %d ERROR - expRResp= %h, act RRESP= %h", $time, MASTER_NUM, 
													expRResp, MASTER_RRESP );
									masterRdStatus 	<= 0;

									#1 $stop;
							end		

							if ( ( ( MASTER_RDATA & rDataMask & mask_rDataMask )!== ( ( rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) ) & (expRResp == 0 ) & (burstType != 2'b00)  )

								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h, mask= %h", $time, MASTER_NUM, 
												( rxLen + MASTER_NUM + baseValue ), MASTER_RDATA, rDataMask & mask_rDataMask );
                  $display( "\t\t\trxLen: %h, d_rxLen: %h, MASTER_NUM: %h, MASTER_ARLEN: %h, burstLen: %h, rdBurstLen: %h", 
                        rxLen, d_rxLen, MASTER_NUM, MASTER_ARLEN, burstLen, rdBurstLen );
									masterRdStatus 	<= 0;
									#1 $stop;		
								end
							else if ( ( ( ( (MASTER_RDATA >> shift_fixed) & rDataMask )  & mask_rDataMask & (mask_unalign << 8*align_addr_32) )!== (( (burstLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp )  >> shift_fixed)) & (expRResp == 0 ) & (burstType == 2'b00)  )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h", $time, MASTER_NUM, 
												( (burstLen+ MASTER_NUM + baseValue ) & rDataMask & mask_rDataMask_exp) >> shift_fixed, ( ((MASTER_RDATA >> shift_fixed) & rDataMask) ) & mask_rDataMask & (mask_unalign << 8*align_addr_32) );
									masterRdStatus 	<= 0;
									#1 $stop;		
								end
								
							rnextState 		<= rstDATA;
							
						end
					else if ( MASTER_RVALID & !MASTER_RREADY  )
						begin
							d_MASTER_RREADY	<= MASTER_RREADY_Default;

							if ( readFifoEmpty )
								begin
								
									$display( "%d, MASTER %d ERROR - Read Data cycle with no Read Address Pending", $time, MASTER_NUM );
									masterRdStatus 	<= 0;
									#1 $stop;
								end	
								
							if ( transID != MASTER_RID )
								begin
									$display( "%d, MASTER %d ERROR - exp RID= %h, act RID= %h", $time, MASTER_NUM, transID, MASTER_RID );
									masterRdStatus 	<= 0;
									#1 $stop;
								
								end

							rnextState 		<= rstDATA;
							
						end
				end
		rstDATA : begin
					d_MASTER_RREADY <= 1'b1;

					#1;
					
					if ( MASTER_RVALID & MASTER_RREADY & MASTER_RLAST )		// only 1 beat
						begin
							d_MASTER_RREADY	<= MASTER_RREADY_Default;
							
							transID		= readFifRdData[READFIF_WIDTH-1: READFIF_WIDTH-ID_WIDTH];
							burstLen	= readFifRdData[READFIF_WIDTH- ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH- ID_WIDTH- ADDR_WIDTH -8];
							
							if ( transID != MASTER_RID )
								begin
									$display( "%d, MASTER %d ERROR - exp RID= %h, act RID= %h", $time, MASTER_NUM, transID, MASTER_RID );
									masterRdStatus 	<= 0;
									#1 $stop;
									
								end
				
							if ( burstLen != rxLen )
								begin
									$display( "%d, MASTER %d ERROR - exp rxLen= %h, act rxLen= %h", $time, MASTER_NUM, burstLen, rxLen );
									masterRdStatus 	<= 0;
									#1 $stop;
									
								end	
								
							if ( MASTER_RRESP != expRResp )
								begin
									$display( "%d, MASTER %d ERROR - expRResp= %h, act RRESP= %h", $time, MASTER_NUM, 
													expRResp, MASTER_RRESP );
									masterRdStatus 	<= 0;

									#1 $stop;
							end		
							
							if ( ( ( MASTER_RDATA & rDataMask & mask_rDataMask )!== ( (rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) ) & (expRResp == 0 ) & (burstType != 2'b00) )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h, rDataMask & mask_rDataMask: %h", $time, MASTER_NUM, 
												(rxLen+ MASTER_NUM + baseValue ), MASTER_RDATA, rDataMask & mask_rDataMask );
                  $display( "\t\t\trxLen: %h, MASTER_NUM: %h, MASTER_ARLEN: %h, DATA+MASK: %h, curRdAddr:%h", 
                        rxLen, MASTER_NUM, MASTER_ARLEN,(MASTER_RDATA & rDataMask & mask_rDataMask), curRdAddr );
									masterRdStatus 	<= 0;
											#1 $stop;
								end	
							else if ( ( ( ( (MASTER_RDATA >> shift_fixed) & rDataMask )  & mask_rDataMask & (mask_unalign << 8*align_addr_32) )!== (( (rxLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) >> shift_fixed )) & (expRResp == 0 ) &  (burstType == 2'b00))
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h, rDataMask & mask_rDataMask: %h", $time, MASTER_NUM, 
												((rxLen+ MASTER_NUM + baseValue ) >> shift_fixed), (MASTER_RDATA  >> shift_fixed), rDataMask & mask_rDataMask & (mask_unalign << 8*align_addr_32) );
                  $display( "\t\t\trxLen: %h, MASTER_NUM: %h, MASTER_ARLEN: %h, DATA+MASK: %h, curRdAddr:%h", 
                        rxLen, MASTER_NUM, MASTER_ARLEN,(MASTER_RDATA & rDataMask & mask_rDataMask & (mask_unalign << 8*align_addr_32)), curRdAddr );
									masterRdStatus 	<= 0;
											#1 $stop;
								end	

							d_rxLen 		<= 0;				// initialise for next burst

							d_curRdAddr	<= startRdAddr;
							
							readFifRd		<= 1;				// pop open transaction
							masterRdDone	<= 1;
							d_rdCount		<= rdCount + 1'b1;

							rnextState	<= rstIDLE;
						end
					else if ( MASTER_RVALID & MASTER_RREADY & !MASTER_RLAST  )
						begin
							d_MASTER_RREADY	<= MASTER_RREADY_Default;
							d_rxLen <= rxLen + 1'b1;
		if (burstType == 2'b00) begin
			d_curRdAddr <= curRdAddr;
		end
                      else if (burstType == 2'b10) begin
                if (rxLen == (rd_to_boundary_master-1)) begin
                d_curRdAddr <= { curRdAddr[ADDR_WIDTH-1:10], (curRdAddr[9:0] & ReadAddrMaskWrap)};
                end else begin
                d_curRdAddr <= curRdAddr + (1 << burstSize);
                end
              end
		else begin
              d_curRdAddr	<= { curRdAddr[ADDR_WIDTH-1:6], (curRdAddr[5:0] & ReadAddrMask) }  + (1 << burstSize);		// aligned address
      end

							if ( transID != MASTER_RID )
								begin
									$display( "%d, MASTER %d ERROR - exp RID= %h, act RID= %h", $time, MASTER_NUM, transID, MASTER_RID );
									masterRdStatus 	<= 0;
									#1 $stop;
									
								end
								
							if ( MASTER_RRESP != expRResp )
								begin
									$display( "%d, MASTER %d ERROR - expRResp= %h, act RRESP= %h", $time, MASTER_NUM, 
													expRResp, MASTER_RRESP );
									masterRdStatus 	<= 0;

									#1 $stop;
							end

							if ( ( ( MASTER_RDATA & rDataMask & mask_rDataMask )!== ( (rxLen /*MASTER_ARLEN*/ + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) ) & (expRResp == 0 ) & (burstType != 2'b00)  )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h", $time, MASTER_NUM, 
												(rxLen+ MASTER_NUM + baseValue ) & rDataMask & mask_rDataMask_exp, MASTER_RDATA & rDataMask & mask_rDataMask );
									masterRdStatus 	<= 0;
									#1 $stop;		
								end
							else if ( ( ( ( (MASTER_RDATA  >> shift_fixed) & rDataMask ) & mask_rDataMask & (mask_unalign << 8*align_addr_32) )!== ( ( (burstLen + MASTER_NUM + baseValue) & rDataMask & mask_rDataMask_exp ) >> shift_fixed ) ) & (expRResp == 0 ) & (burstType == 2'b00)  )
								begin
									$display( "%d, MASTER %d ERROR - exp RDATA= %h, act RDATA= %h", $time, MASTER_NUM, 
												((burstLen+ MASTER_NUM + baseValue ) & rDataMask & mask_rDataMask_exp ) >> shift_fixed, (MASTER_RDATA  >> shift_fixed) & rDataMask & mask_rDataMask & (mask_unalign << 8*align_addr_32) );
									masterRdStatus 	<= 0;
									#1 $stop;		
								end

							rnextState 		<= rstDATA;
							
						end
				end
	endcase
end

assign ReadAddrMask = 6'h3f << (readFifRdData[4:2]);

 always @(posedge sysClk or posedge sysReset )
 begin
	if (sysReset)
		begin
			rcurrState 		<= rstIDLE;
			MASTER_RREADY	<= 0;
			rxLen 			<= 0;
			rdCount			<= 0;
			curRdAddr		<= 0;
		end
	else
		begin
			rcurrState 		<= rnextState;
			MASTER_RREADY	<= d_MASTER_RREADY;
			rxLen			<= d_rxLen;
			rdCount			<= d_rdCount;
			curRdAddr		<= d_curRdAddr;
		end
end


//====================================================================================================
// Local Declarationes for Master Read Address 
//====================================================================================================
reg [ID_WIDTH-1:0]        	d_MASTER_ARID;
reg [ADDR_WIDTH-1:0]      	d_MASTER_ARADDR;
reg [7:0]                 	d_MASTER_ARLEN;
reg [2:0]                 	d_MASTER_ARSIZE;
reg [2:0]                 	max_ARSIZE;
reg [1:0]                 	d_MASTER_ARBURST;
reg [1:0]                 	d_MASTER_ARLOCK;
reg [3:0]                 	d_MASTER_ARCACHE;
reg [2:0]                 	d_MASTER_ARPROT;
reg [3:0]					d_MASTER_ARREGION;
reg [3:0]                 	d_MASTER_ARQOS;		// not used
reg [USER_WIDTH-1:0]      	d_MASTER_ARUSER;
reg                       	d_MASTER_ARVALID;

reg [2:0]	arcurrState, arnextState;

localparam	[2:0]		arstIDLE = 3'h0,	arstDATA = 3'h1;

//====================================================================================================
// Master Read Address S/M
//===================================================================================================== 
 always @( * )
 begin
 
	arnextState <= arcurrState;

	d_MASTER_ARID		<= MASTER_ARID;
	d_MASTER_ARADDR		<= MASTER_ARADDR;
	d_MASTER_ARLEN		<= MASTER_ARLEN;
	d_MASTER_ARSIZE 	<= MASTER_ARSIZE;
	d_MASTER_ARBURST	<= MASTER_ARBURST;
	d_MASTER_ARLOCK		<= MASTER_ARLOCK;
	d_MASTER_ARCACHE	<= MASTER_ARCACHE;
	d_MASTER_ARPROT		<= MASTER_ARPROT;
	d_MASTER_ARREGION	<= MASTER_ARREGION;
	d_MASTER_ARQOS		<= MASTER_ARQOS;		// not used
	d_MASTER_ARUSER		<= MASTER_ARUSER;

	d_MASTER_ARVALID	<= MASTER_ARVALID;	
	
	mstRAddrIdle			<= 0;
	readFifWrData <= { MASTER_ARID, MASTER_ARADDR, MASTER_ARLEN, MASTER_ARSIZE, MASTER_ARBURST };

	readFifWr	<= 0;	

	d_arCount			<= arCount;
	masterRdAddrDone	<= 0;
	
	case( arcurrState )
		arstIDLE: begin
					mstRAddrIdle	<= 1;
			
					if ( rdStart & !readFifoFull )		// start master read address transaction
						begin
							d_MASTER_ARVALID	<= 1'b1;

							d_MASTER_ARID		<= rdAID;
							d_MASTER_ARADDR		<= rdStartAddr;				// make up data to be easy read in simulation
							d_MASTER_ARLEN 		<= rdBurstLen;

							
							max_ARSIZE 	<= 	(DATA_WIDTH == 'd16)  ? 3'h1 :
											(DATA_WIDTH == 'd32 ) ? 3'h2 :
											(DATA_WIDTH == 'd64 ) ? 3'h3 :
											(DATA_WIDTH == 'd128) ? 3'h4 :
											(DATA_WIDTH == 'd256) ? 3'h5 :
											(DATA_WIDTH == 'd512) ? 3'h6 :
														 3'bxxx;		// not supported;
														 
							if (rdASize > max_ARSIZE)
								begin
									d_MASTER_ARSIZE 	<= max_ARSIZE;
									$display( "%d, MASTER %d ERROR - requested transfer size = %h exceed data width limitation and is reset to %h", 
														$time, MASTER_NUM, rdASize, max_ARSIZE );
									#1 $stop;
								end
							else
								begin
									d_MASTER_ARSIZE 	<= rdASize;
								end
														
							d_MASTER_ARBURST	<= BurstType;	
							d_MASTER_ARLOCK		<= 0;
							d_MASTER_ARCACHE	<= 0;
							d_MASTER_ARPROT		<= 0;
							d_MASTER_ARREGION	<= 0;
							d_MASTER_ARQOS		<= 0;		// not used
							d_MASTER_ARUSER		<= 1;

							arnextState 	<= arstDATA;
						end
				end
		arstDATA : begin
					d_MASTER_ARVALID	<= 1'b1;
					readFifWrData <= { MASTER_ARID, MASTER_ARADDR, MASTER_ARLEN, MASTER_ARSIZE, MASTER_ARBURST };

					if ( MASTER_ARVALID & MASTER_ARREADY )		
						begin
						
							readFifWr			<= 1;		// push fifo 
							d_arCount			<= arCount + 1'b1;
							masterRdAddrDone	<= 1;
							
							if ( rdStart & !readFifoFull)				// if another burst request and space
								begin
									d_MASTER_ARVALID	<= 1'b1;
									
									d_MASTER_ARID		<= rdAID;
									d_MASTER_ARADDR		<= rdStartAddr;				// make up data to be easy read in simulation
									d_MASTER_ARLEN 		<= rdBurstLen;

									arnextState <= arstDATA;
								end
							else
								begin
									d_MASTER_ARVALID	<= 1'b0;
							
									arnextState <= arstIDLE;
								end
						end
					else			// not ready
						begin
									
						end
				end
	endcase
end


 always @(posedge sysClk or posedge sysReset )
 begin
 
	if (sysReset)
		begin
			MASTER_ARVALID	<= 1'b0;

			MASTER_ARID		<= 0;
			MASTER_ARADDR	<= 0;				// make up data to be easy read in simulation
			MASTER_ARLEN 	<= 0;

			MASTER_ARSIZE 	<= 0;
			MASTER_ARBURST	<= 0;
			MASTER_ARLOCK	<= 0;
			MASTER_ARCACHE	<= 0;
			MASTER_ARPROT	<= 0;
			MASTER_ARREGION	<= 0;
			MASTER_ARQOS	<= 0;		// not used
			MASTER_ARUSER	<= 1;

			arCount			<= 0;

			arcurrState	<= arstIDLE;
		end
	else
		begin
			MASTER_ARVALID	<= d_MASTER_ARVALID;

			MASTER_ARID		<= d_MASTER_ARID;
			MASTER_ARADDR	<= d_MASTER_ARADDR;				// make up data to be easy read in simulation
			MASTER_ARLEN 	<= d_MASTER_ARLEN;

			MASTER_ARSIZE 	<= d_MASTER_ARSIZE;
			MASTER_ARBURST	<= d_MASTER_ARBURST;
			MASTER_ARLOCK	<= d_MASTER_ARLOCK;
			MASTER_ARCACHE	<= d_MASTER_ARCACHE;
			MASTER_ARPROT	<= d_MASTER_ARPROT;
			MASTER_ARREGION	<= d_MASTER_ARREGION;
			MASTER_ARQOS	<= d_MASTER_ARQOS;		// not used
			MASTER_ARUSER	<= d_MASTER_ARUSER;

			arCount			<= d_arCount;

			arcurrState	<= arnextState;
		end
end

// Different paths for simulation and synthesis
// `ifdef SIM_MODE
	// `include "../component/Actel/DirectCore/CoreAXI4Interconnect_w/2.1.3/sim/AXI4Models/Axi4MasterGen_Wr.v"
	// `include "../component/Actel/DirectCore/CoreAXI4Interconnect_w/2.1.3/sim/AXI4Models/Axi4MasterGen_WrResp.v"
// `else
	`include "../../sim/AXI4Models/Axi4MasterGen_Wr.v"
	`include "../../sim/AXI4Models/Axi4MasterGen_WrResp.v"
// `endif


		
		
endmodule // Axi4MasterGen.v
