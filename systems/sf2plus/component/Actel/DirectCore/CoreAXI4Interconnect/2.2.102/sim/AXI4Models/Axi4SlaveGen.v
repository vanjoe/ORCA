// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Slave test source.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

module Axi4SlaveGen # 
	(

		parameter [3:0]		SLAVE_NUM				= 0,		// slaive number
		parameter integer 	ID_WIDTH   				= 4, 

		parameter integer 	ADDR_WIDTH      		= 32,				
		parameter integer 	DATA_WIDTH 				= 32, 

		parameter integer 	SUPPORT_USER_SIGNALS 	= 0,
		parameter integer 	USER_WIDTH 				= 1,

		
		parameter integer 	OPENTRANS_MAX			= 2,		// Number of open transations width - 1 => 2 transations, 2 => 4 transations, etc.

		parameter integer	LOWER_COMPARE_BIT 		= 'd10,		// Defines lower bound of compare - bits below are dont care
		parameter			HI_FREQ					= 0
		
	)
	(
		// Global Signals
		input  wire                                    		sysClk,
		input  wire                                    		ARESETN,			// active low reset synchronoise to RE AClk - asserted async.
   
		//====================== Slave Read Address Ports  ================================================//
		// Slave Read Address Port
		input wire [ID_WIDTH-1:0]          					SLAVE_ARID,
		input wire [ADDR_WIDTH-1:0]          				SLAVE_ARADDR,
		input wire [7:0]                         			SLAVE_ARLEN,
		input wire [2:0]                         			SLAVE_ARSIZE,
		input wire [1:0]                         			SLAVE_ARBURST,
		input wire [1:0]                         			SLAVE_ARLOCK,
		input wire [3:0]                         			SLAVE_ARCACHE,
		input wire [2:0]                         			SLAVE_ARPROT,
		input wire [3:0]                         			SLAVE_ARREGION,			// not used
		input wire [3:0]                         			SLAVE_ARQOS,			// not used
		input wire [USER_WIDTH-1:0]	        				SLAVE_ARUSER,
		input wire                            				SLAVE_ARVALID,				
		output  wire 	                       				SLAVE_ARREADY,
   
		// Slave Read Data Ports
		output  reg [ID_WIDTH-1:0]          				SLAVE_RID,
		output  reg [DATA_WIDTH-1:0]    					SLAVE_RDATA,
		output  reg [1:0]                     				SLAVE_RRESP,
		output  reg                         				SLAVE_RLAST,
		output  reg [USER_WIDTH-1:0]	        		 	SLAVE_RUSER,			// not used
		output  reg                         				SLAVE_RVALID,
		
		input 	wire	                       				SLAVE_RREADY,
	
		// Slave Write Address Port
		input wire [ID_WIDTH-1:0]          					SLAVE_AWID,
		input wire [ADDR_WIDTH-1:0]          				SLAVE_AWADDR,
		input wire [7:0]                         			SLAVE_AWLEN,
		input wire [2:0]                         			SLAVE_AWSIZE,
		input wire [1:0]                         			SLAVE_AWBURST,
		input wire [1:0]                         			SLAVE_AWLOCK,
		input wire [3:0]                         			SLAVE_AWCACHE,
		input wire [2:0]                         			SLAVE_AWPROT,
		input wire [3:0]                         			SLAVE_AWREGION,			// not used
		input wire [3:0]                         			SLAVE_AWQOS,			// not used
		input wire [USER_WIDTH-1:0]	        				SLAVE_AWUSER,
		input wire                            				SLAVE_AWVALID,				
		output wire	 	                       				SLAVE_AWREADY,
   	
		// Slave Write Data Ports
		input wire [DATA_WIDTH-1:0]    						SLAVE_WDATA,
		input wire [(DATA_WIDTH/8)-1:0]  					SLAVE_WSTRB,
		input wire                           				SLAVE_WLAST,
		input wire [USER_WIDTH-1:0]	         				SLAVE_WUSER,
		input wire                            				SLAVE_WVALID,
		
		output reg                           				SLAVE_WREADY,
		
		// Master Write Response Ports
		output reg [ID_WIDTH-1:0]           				SLAVE_BID,
		output reg [1:0]                          			SLAVE_BRESP,
		output reg [USER_WIDTH-1:0]          				SLAVE_BUSER,
		output reg 	                            			SLAVE_BVALID,

		input  wire  	                           			SLAVE_BREADY,
		
		// ===============  Control Signals  =======================================================//
		input wire											SLAVE_ARREADY_Default,			// defines whether SLAVE asserts ready or waits for ARVALID
		input wire											SLAVE_AWREADY_Default,			// defines whether SLAVE asserts ready or waits for WVALID
	
		input wire											SLAVE_DATA_IDLE_EN,				// Enables idle cycles to be inserted in Data channels
		input wire [1:0]									SLAVE_DATA_IDLE_CYCLES,			// Idle cycles = 00= random, 01 = 1, 10=2, 11=3

		input wire											FORCE_ERROR, 					// Forces error pn read/write RESP
		input wire [7:0]									ERROR_BYTE						// Byte to force error on - for READs
		
	);
   						 
 
	localparam	[0:0]		arstIDLE = 1'h0,	arstDATA = 1'h1;

	localparam integer		NUM_BYTES 				= (DATA_WIDTH/8);			// number of bytes in each read / write 

	localparam [7:0] ALIGNED_BITS = 	$clog2(DATA_WIDTH/8);
								
	reg						d_SLAVE_ARREADY, preSLAVE_ARREADY;
	
	wire					sysReset;
	
	
//=================================================================================================
// Local Declarationes
//=================================================================================================
 
localparam	READFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 

reg [READFIF_WIDTH-1:0]		readFifWrData;
wire [READFIF_WIDTH-1:0]	readFifRdData;

reg							readFifWr, readFifRd;
wire						readFifoFull, readFifoEmpty;

reg [0:0]					arcurrState, arnextState;
 
reg [7:0]					burstLen, d_burstLen;

wire						rdFifoOverRunErr, rdFifoUnderRunErr;

reg	[LOWER_COMPARE_BIT+ALIGNED_BITS-1:0]	memRdAddr, memWrAddr;
reg	[LOWER_COMPARE_BIT+ALIGNED_BITS-1:0]	d_memRdAddr, d_memWrAddr;

reg [LOWER_COMPARE_BIT+ALIGNED_BITS-1:0] 	memRdAddrAlignedMask, memWrAddrAlignedMask;


wire	[DATA_WIDTH-1:0]	memRdData;
reg	[DATA_WIDTH-1:0]		memWrData;

reg							memWr;
 
reg [15:0]					arCount, d_arCount; 
reg [15:0]					rdCount, d_rdCount; 
 
reg [1:0]					d_idleRdCycles, idleRdCycles;					// holds number of idle cycles per RdData Cycle

reg [1:0]					idleRdCount;
reg 						idleRdCountClr, idleRdCountIncr;

reg [8:0] raddr_rand_sig;
reg [8:0] waddr_rand_sig;
reg [8:0] wdata_rand_sig;
 
 
//=======================================================================================================================
// Local system reset - asserted asynchronously to ACLK and deasserted synchronous
//=======================================================================================================================
ResetSycnc  
	rsync(
			.sysClk	( sysClk ),
			.sysReset_L( ARESETN ),			// active low reset synchronoise to RE AClk - asserted async.
			.sysReset( sysReset  )			// active high sysReset synchronised to ACLK
	);
   		 
 
//=============================================================================================
// Display messages only in Simulation - not synthesis
//=============================================================================================
`ifdef SIM_MODE

	//=============================================================================================
	// Display messages for Read Address Channel
	//=============================================================================================
	always @( posedge sysClk )
	begin
		#1;
	
		if ( SLAVE_ARVALID )
			begin
				#1 $display( "%d, SLAVE  %d - Starting Read Address Transaction %d, ARADDR= %h, ARBURST= %h, ARSIZE= %h, AID= %h, RXLEN= %d", 
								$time, SLAVE_NUM, arCount, SLAVE_ARADDR, SLAVE_ARBURST, SLAVE_ARSIZE, SLAVE_ARID, SLAVE_ARLEN );

				if ( SLAVE_ARREADY )		// single beat
					begin
						#1 $display( "%d, SLAVE  %d - Ending Read Address Transaction %d, AID= %h, RXLEN= %d", 
								$time, SLAVE_NUM, arCount, SLAVE_ARID, SLAVE_ARLEN );
					end
				else
					begin
						@( posedge SLAVE_ARREADY )
							#1 $display( "%d, SLAVE  %d - Ending Read Address Transactions %d, AID= %h, RXLEN= %d", 
								$time, SLAVE_NUM, arCount, SLAVE_ARID, SLAVE_ARLEN );
					end
			end
	end


	//=============================================================================================
	// Display messages for Read Data Channel
	//=============================================================================================
	always @( posedge sysClk )
		begin
			#1;
			if ( SLAVE_RVALID )
				begin
					#1 $display( "%d, SLAVE %d - Starting Read Data Transaction %d, AID= %h, RXLEN= %d", 
							$time, SLAVE_NUM, rdCount, SLAVE_RID, burstLen );

					if ( SLAVE_RLAST & SLAVE_RVALID & SLAVE_RREADY )		// single beat
						begin
							#1 $display( "%d, SLAVE %d - Ending Read Data Transaction %d, AID= %h, RXLEN= %d, RRESP=%h", 
								$time, SLAVE_NUM, rdCount, SLAVE_RID, burstLen, SLAVE_RRESP );
						end
					else
						begin
							@( posedge ( SLAVE_RLAST & SLAVE_RVALID & SLAVE_RREADY ) )
								#1 $display( "%d, SLAVE %d - Ending Read Data Transactions %d, AID= %h, RXLEN= %d, RRESP=%h", 
									$time, SLAVE_NUM, rdCount, SLAVE_RID, burstLen, SLAVE_RID );
						end
				end
		end 
 
 `ifdef VERBOSE
	//=============================================================================================
	// Display RDAT - data begin written from RAM
	//=============================================================================================
	always @( negedge sysClk )
		begin	
			if ( SLAVE_RVALID & SLAVE_RREADY )		
				begin
					$display( "%t, %m, memRdAddr=%h (%d), SLAVE_RDATA= %d", $time, memRdAddr, memRdAddr, SLAVE_RDATA );
				end
		end		
`endif
 
 
 
 
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
		rdFif(
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
					.fifoFull(  ),
					.fifoNearFull( readFifoFull ),
					.fifoOverRunErr( rdFifoOverRunErr ),
					.fifoUnderRunErr( rdFifoUnderRunErr )
				   
				);

 
		
//=============================================================================
// Declare Dual port RAM - store Slave Data
//=============================================================================
DualPort_RAM_SyncWr_ASyncRd #( 	.FIFO_AWIDTH( LOWER_COMPARE_BIT ),
								.FIFO_WIDTH ( DATA_WIDTH )
							)
		rdRam(
					// global signals
					.HCLK( sysClk ),

					// Write Port
					.fifoWrAddr( memWrAddr ),	
					.fifoWrite ( memWr	   ),
					.fifoWrStrb( SLAVE_WSTRB ),

					.fifoWrData( memWrData ),

					// Read Port
					.fifoRdAddr( d_memRdAddr ),
					.fifoRdData( memRdData )
				   
			);

 
 
//====================================================================================================
// Slave Read Address S/M
//===================================================================================================== 
 always @( * )
 begin
 
	arnextState <= arcurrState;

	readFifWrData <= { SLAVE_ARID, SLAVE_ARADDR, SLAVE_ARLEN, SLAVE_ARSIZE, SLAVE_ARBURST };
	
	d_SLAVE_ARREADY	<= SLAVE_ARREADY_Default;		// only accept a transaction when space in fifo
	readFifWr		<= 0;

	d_arCount		<= arCount;
	
	case( arcurrState )
		arstIDLE: begin
					d_SLAVE_ARREADY <= SLAVE_ARREADY_Default;
		
					if ( SLAVE_ARVALID & SLAVE_ARREADY )		// if always ready
						begin
							d_SLAVE_ARREADY	<= SLAVE_ARREADY_Default;
							
							readFifWr	<= 1;
							d_arCount	<= arCount + 1'b1;

							arnextState <= arstIDLE;
						end
					else if ( SLAVE_ARVALID & !SLAVE_ARREADY )
						begin
							arnextState <= arstDATA;
						end
				end
		arstDATA : begin
					d_SLAVE_ARREADY <= 1'b1;

					if ( SLAVE_ARVALID & SLAVE_ARREADY )		// 	last beat
						begin
							d_SLAVE_ARREADY	<= SLAVE_ARREADY_Default;

							d_arCount		<= arCount + 1'b1;
							
							readFifWr	  	<= 1;
	
							arnextState 		<= arstIDLE;

						end
				end
	endcase
end


 always @( posedge sysClk or posedge sysReset)		
 begin
	if (sysReset)
		begin
			arcurrState 		<= arstIDLE;
			preSLAVE_ARREADY	<= 0;
			
			arCount				<= 0;

		end
	else
		begin
			arcurrState 		<= arnextState;
			preSLAVE_ARREADY	<= d_SLAVE_ARREADY;
			raddr_rand_sig <= $random() % 100;
      waddr_rand_sig <= (raddr_rand_sig * $random()) % 100;
      wdata_rand_sig <= (waddr_rand_sig * $random()) % 100;
			arCount		<= d_arCount;

		end
end


assign SLAVE_ARREADY = preSLAVE_ARREADY & !readFifoFull & (raddr_rand_sig == 98);


//=================================================================================================
// Local Declarationes for Slave Read Data 
//=================================================================================================
 
reg [ID_WIDTH-1:0] 			d_SLAVE_RID;
reg [DATA_WIDTH-1:0]   		d_SLAVE_RDATA;
reg [1:0]                   d_SLAVE_RRESP;
reg                         d_SLAVE_RLAST;
reg [USER_WIDTH-1:0]        d_SLAVE_RUSER;
reg                         d_SLAVE_RVALID;


reg	[7:0]					rxLen, d_rxLen;
reg [1:0]					rdBurstType, d_rdBurstType; 
reg [2:0]					rdRSize, d_rdRSize; 
 
reg [1:0]					rcurrState, rnextState;

localparam	[1:0]			rstIDLE = 2'h0,	rstDATA = 2'h1, rstIDLE_DATA = 2'h2;


//====================================================================================================
// Counter for Idle on each Read Data
//====================================================================================================
always @(posedge sysClk or posedge sysReset )
begin
	if ( sysReset )
		begin
			idleRdCount	<= 0;		// initialise to 1
		end
	else if ( idleRdCountClr )
		begin
			idleRdCount	<= 0;		// initiales to 1
		end
	else if ( idleRdCountIncr )
		begin
			idleRdCount	<= idleRdCount + 1'b1;
		end
end

//=================================================================================================
// Create mask to "align" memRdAddr to size of transfer.
//=================================================================================================
always @( * )
	begin
		case( rdRSize )
			3'h0 : memRdAddrAlignedMask <=   { (LOWER_COMPARE_BIT+ALIGNED_BITS  ){1'b1} };
			3'h1 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-1){1'b1} }, 1'b0 };
			3'h2 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-2){1'b1} }, 2'b0 };
			3'h3 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-3){1'b1} }, 3'b0 };
			3'h4 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-4){1'b1} }, 4'b0 };
			3'h5 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-5){1'b1} }, 5'b0 };
			3'h6 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-6){1'b1} }, 6'b0 };
			3'h7 : memRdAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-7){1'b1} }, 7'b0 };
		endcase
	end
	
									
 //====================================================================================================
 // Slave Read Data S/M
//===================================================================================================== 

 always @( * )
 begin
 
	rnextState <= rcurrState;
	
	d_SLAVE_RID		<= SLAVE_RID;
	d_SLAVE_RDATA	<= { SLAVE_NUM, {(DATA_WIDTH-4){1'b0}   } };
	d_SLAVE_RRESP	<= SLAVE_RRESP;
	d_SLAVE_RLAST	<= SLAVE_RLAST;
	d_SLAVE_RUSER	<= 0;
	d_SLAVE_RVALID	<= 0;

	d_rxLen			<= rxLen;
	d_rdBurstType 	<= rdBurstType;
	d_rdRSize		<= rdRSize;
	d_idleRdCycles	<= idleRdCycles;
	
	readFifRd		<= 0;
	
	d_memRdAddr		<= memRdAddr;
	d_burstLen	 	<= burstLen;

	d_rdCount		<= rdCount;

	idleRdCountClr	<= 1'b0;
	idleRdCountIncr	<= 1'b0;
	
	case( rcurrState )
		rstIDLE: begin
					
					d_rxLen 		<= 0;
					d_SLAVE_RLAST	<= 0;
					
					idleRdCountClr	<= 1'b1;

					if ( !readFifoEmpty )				// data to read
						begin
							readFifRd		<= 1;		// pop fifo 

							d_SLAVE_RDATA	<= memRdData;	

							//===========================================================================================
							//FifWrData == { SLAVE_ARID, SLAVE_ARADDR, SLAVE_ARLEN, SLAVE_ARSIZE, SLAVE_ARBURST };
							//===========================================================================================
							d_rdBurstType <= readFifRdData[1:0];
							d_rdRSize	  <= readFifRdData[4:2];
							
							d_memRdAddr	<= readFifRdData[READFIF_WIDTH-ID_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH];
							d_burstLen	<= readFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ]; // pickout ARLEN
							d_SLAVE_RID	<= readFifRdData[READFIF_WIDTH-1: READFIF_WIDTH-ID_WIDTH];

							d_SLAVE_RLAST	<= (readFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ] == 0);

							d_SLAVE_RRESP	<= FORCE_ERROR 	? (ERROR_BYTE == 0 ) ? 2'b10  : 2'b00
															: 2'b00;

							
							//============================================================================
							// see if idle cycles to be inserted
							//============================================================================
							if ( SLAVE_DATA_IDLE_EN )
								begin
									d_SLAVE_RVALID	<= 1'b0;

									case (SLAVE_DATA_IDLE_CYCLES)
										2'b00:		// random cycles
											begin
												`ifdef SIM_MODE		// only use random when in simulation
													d_idleRdCycles <= $random(); 
												`else
													d_idleRdCycles <= 0; 
												`endif
											end
										2'b01:		// 1 idle cycle
											begin
												d_idleRdCycles <= 4'd1; 
											end
										2'b10:		// 2 idle cycle
											begin
												d_idleRdCycles <= 4'd2; 
											end
										2'b11:		// 3 idle cycle
											begin
												d_idleRdCycles <= 4'd3; 
											end
									endcase
							
									rnextState 		<= rstIDLE_DATA;
								end
							else
								begin
									d_idleRdCycles <= 0; 
								
									d_SLAVE_RVALID	<= 1'b1;	// start read cycle
									rnextState 		<= rstDATA;
								end
						end
					else
						begin

						end
						
				end
		rstIDLE_DATA : begin

					d_SLAVE_RDATA	<= memRdData;	
		
					if ( idleRdCount == idleRdCycles )		// if had all idle cycles
						begin
							d_SLAVE_RVALID	<= 1'b1;	// start read cycle

							rnextState 		<= rstDATA;
						end
					else
						begin
							idleRdCountIncr	<= 1'b1;
							
							rnextState 		<= rstIDLE_DATA;
						end
				end

		rstDATA : begin
					d_SLAVE_RVALID	<= 1'b1;
					d_SLAVE_RDATA	<= memRdData;	

					d_SLAVE_RRESP	<= FORCE_ERROR 	? (rxLen == ERROR_BYTE ) ? 2'b10  : 2'b00
													: 2'b00;
					
					if ( SLAVE_RVALID & SLAVE_RREADY & SLAVE_RLAST )		// 	last beat
						begin
							d_rdCount	<= rdCount + 1'b1;					// increment count of read transactions performed

							if ( ~readFifoEmpty )				// if another burst request - start on next clock
								begin
									readFifRd		<= 1;		// pop fifo 
								
									d_SLAVE_RLAST	<= (readFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ] == 0);
									
									// Pick out from Read Fifo
									d_rdBurstType <= readFifRdData[1:0];
									d_rdRSize	  <= readFifRdData[4:2];
									
									d_memRdAddr	<= readFifRdData[READFIF_WIDTH-ID_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH];
									d_burstLen	<= readFifRdData[ READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ]; // pickout ARLEN
									d_SLAVE_RID	<= readFifRdData[READFIF_WIDTH-1: READFIF_WIDTH-ID_WIDTH];

									d_SLAVE_RLAST	<= (readFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ] == 0);
									
									d_rxLen 	<= 0;

									if ( SLAVE_DATA_IDLE_EN )
										begin
								
											if (SLAVE_DATA_IDLE_CYCLES == 0)		// if random delays - update
												begin
													`ifdef SIM_MODE		// only use random when in simulation
														d_idleRdCycles <= $random(); 
													`else
														d_idleRdCycles <= 0; 
													`endif
												end
											d_SLAVE_RVALID	<= 1'b0;	// start next read data transaction
											rnextState  	<= rstIDLE_DATA;
										end
									else
										begin
											d_idleRdCycles <= 0; 

											d_SLAVE_RVALID	<= 1'b1;	// start next read data transaction
											rnextState  	<= rstDATA;
										end
								end
							else
								begin
														
									d_SLAVE_RVALID	<= 1'b0;
									d_SLAVE_RLAST	<= 0;
									d_burstLen		<= 0;
									d_rxLen 		<= 0;
									//d_memRdAddr		<= 0;
							
									rnextState <= rstIDLE;
								end
						end
					else if ( SLAVE_RREADY & SLAVE_RVALID )		// get next data
						begin
						
							case ( rdBurstType )
								2'b00 :			// fixed
									begin
										d_memRdAddr		<= memRdAddr;
									end
								2'b01 :			// increment
									begin
										d_memRdAddr <= ( memRdAddr & memRdAddrAlignedMask) + ( 1 << rdRSize );
																				// increment by number of bytes transferred										
									end
								2'b10 :			// wrap - not handling wrap correctly here
									begin
										d_memRdAddr <= ( memRdAddr & memRdAddrAlignedMask) + ( 1 << rdRSize );
																				// increment by number of bytes transferred										
									end									
								2'b11 :			// reserverd
									begin
										$stop;		// should never get here
									end										
							endcase
							
							d_SLAVE_RLAST	<= ( rxLen +1'b1 == burstLen );		// reached end of burst
							
							d_rxLen 		<= rxLen + 1'b1;

							if ( SLAVE_DATA_IDLE_EN )
								begin
								
									if (SLAVE_DATA_IDLE_CYCLES == 0)		// if random delays - update
										begin
											`ifdef SIM_MODE		// only use random when in simulation
												d_idleRdCycles <= $random(); 
											`else
												d_idleRdCycles <= 0; 
											`endif
										end
									else
										begin
											d_idleRdCycles <= 0; 
										end
										
										d_SLAVE_RVALID	<= 1'b0;	// start next read data transaction
										rnextState  	<= rstIDLE_DATA;
								end
							else
								begin
									d_SLAVE_RVALID	<= 1'b1;	// start next read data transaction
									rnextState  	<= rstDATA;
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
			SLAVE_RID		<= 0;
			SLAVE_RDATA		<= { SLAVE_NUM, {(DATA_WIDTH-4){1'b0} }  };
			SLAVE_RRESP		<= 0;
			SLAVE_RLAST		<= 0;
			SLAVE_RUSER		<= 0;
			SLAVE_RVALID	<= 0;
			
			rdBurstType	<= 0;
			rdRSize		<= 0;
			rxLen 		<= 0;
			memRdAddr	<= 0;
			burstLen	<= 0;

			rdCount		<= 0;
			idleRdCycles	<= 0;
			
			rcurrState	<= rstIDLE;
		end
	else
		begin
			SLAVE_RID		<= d_SLAVE_RID;
			SLAVE_RDATA		<= d_SLAVE_RDATA;
			SLAVE_RRESP		<= d_SLAVE_RRESP;
			SLAVE_RLAST		<= d_SLAVE_RLAST;
			SLAVE_RUSER		<= d_SLAVE_RUSER;
			SLAVE_RVALID	<= d_SLAVE_RVALID;
		
			rdBurstType <= d_rdBurstType;
			rdRSize		<= d_rdRSize;
			rxLen 		<= d_rxLen;
			memRdAddr 	<= d_memRdAddr;
			burstLen	<= d_burstLen;

			rdCount		<= d_rdCount;
			idleRdCycles <= d_idleRdCycles;
			
			rcurrState	<= rnextState;
		end
end


// Different paths for simulation and synthesis
// `ifdef SIM_MODE
	// `include "../component/Actel/DirectCore/CoreAXI4Interconnect_w/2.1.3/sim/AXI4Models/Axi4SlaveGen_Wr.v"
	// `include "../component/Actel/DirectCore/CoreAXI4Interconnect_w/2.1.3/sim/AXI4Models/Axi4SlaveGen_WrResp.v"
// `else
	`include "./Axi4SlaveGen_Wr.v"
	`include "./Axi4SlaveGen_WrResp.v"
// `endif

		
		
endmodule // Axi4SlaveGen.v
