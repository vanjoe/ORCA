// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Slave Write Channel test
//              source. It stores the write cycle into local memory. It
//              assume write is of INCR type.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

//=================================================================================================
// Local Declarationes
//=================================================================================================
 
 
	localparam	RESPFIF_WIDTH = ( ID_WIDTH + 2 );			// ID, Resp

	
	reg							d_SLAVE_AWREADY, preSLAVE_AWREADY;

	wire [READFIF_WIDTH-1:0]	wrFifRdData;	
	reg [READFIF_WIDTH-1:0]		wrFifWrData;	
	
	wire [RESPFIF_WIDTH-1:0]	respFifRdData;	
	wire [RESPFIF_WIDTH-1:0]	respFifWrData;	

	reg							wrFifWr, wrFifRd;
	reg							respFifWr, respFifRd;
	
	wire						wrFifoFull, wrFifoEmpty;	
	wire						respFifoFull, respFifoEmpty;	
	
	wire						wrFifoOverRunErr, wrFifoUnderRunErr;
	wire						respFifoOverRunErr, respFifoUnderRunErr;

	
	reg [0:0]					awcurrState, awnextState;
	
	reg [15:0]					awCount, d_awCount;
	
	localparam	[0:0]			awstIDLE = 1'h0,	awstDATA = 1'h1;


	reg [1:0]					wcurrState, wnextState;
	
	localparam	[1:0]			wstIDLE = 1'h0,	wstDATA = 1'h1, wstIDLE_DATA = 2'h2;

	reg [1:0]					d_idleWrCycles, idleWrCycles;					// holds number of idle cycles per RdData Cycle

	reg [1:0]					idleWrCount;
	reg 						idleWrCountClr, idleWrCountIncr;
	
//======================================================================================================
// Local Declarationes for Slave Write Data 
//======================================================================================================
 
reg						d_SLAVE_WREADY;

reg [1:0]				wrBurstType, d_wrBurstType; 
reg [2:0]				wrWSize, d_wrWSize; 

reg	[8:0]				txLen, d_txLen, wburstLen, d_wburstLen;

reg	[ID_WIDTH-1:0]		respWID, d_respWID;
reg [1:0]				respResp;
 
reg [15:0]				txCount, d_txCount;	

//=============================================================================================
// Display messages only in Simulation - not synthesis
//=============================================================================================
`ifdef SIM_MODE	

	//=============================================================================================
	// Display messages for Write Address Channel
	//=============================================================================================
	always @( posedge sysClk )
		begin
			#1;
	
			if ( SLAVE_AWVALID ) 
				begin
					#1 $display( "%d, SLAVE  %d - Starting Write Address Transaction %d, AWADDR= %h,AWBURST= %h, AWSIZE= %h, WID= %h, AWLEN= %d", 
							$time, SLAVE_NUM, awCount, SLAVE_AWADDR, SLAVE_AWBURST, SLAVE_AWSIZE, SLAVE_AWID, SLAVE_AWLEN );

					if ( SLAVE_AWREADY )		// single beat
						begin
							#1 $display( "%d, SLAVE  %d - Ending Write Address Transaction %d, WID= %h, AWLEN= %d", 
									$time, SLAVE_NUM, awCount, SLAVE_AWID, SLAVE_AWLEN );
						end
					else
						begin
							@( posedge SLAVE_AWREADY )
								#1 $display( "%d, SLAVE  %d - Ending Write Address Transaction %d, WID= %h, AWLEN= %d", 
									$time, SLAVE_NUM, awCount, SLAVE_AWID, SLAVE_AWLEN );
						end
				end
		end	

	//=============================================================================================
	// Display messages for Write Data Channel
	//=============================================================================================
	always @( posedge sysClk )
		begin
			#1;
	
			if ( SLAVE_WVALID & ( wcurrState != wstIDLE ) )
				begin
					#1 $display( "%d, SLAVE  %d - Starting Write Data Transaction %d, WADDR= %h (%d), WID= %h, TXLEN= %d", 
							$time, SLAVE_NUM, txCount, memWrAddr, memWrAddr, respWID, wburstLen );

					if ( SLAVE_WLAST & SLAVE_WVALID & SLAVE_WREADY )		// single beat
						begin
							#1 $display( "%d, SLAVE  %d - Ending Write Data Transaction %d, WID= %h, TXLEN= %d", 
									$time, SLAVE_NUM, txCount, respWID, txLen );
						end
					else
						begin
							@( posedge ( SLAVE_WLAST & SLAVE_WVALID & SLAVE_WREADY ) )
								#1 $display( "%d, SLAVE  %d - Ending Write Data Transaction %d, WID= %h, TXLEN= %d", 
										$time, SLAVE_NUM, txCount, respWID, txLen );
						end
				end
		end

		
	//=============================================================================================
	// Display messages for checking size of burst at end of Write Data Channel
	//=============================================================================================
	always @( negedge sysClk )
		begin
			
			if ( SLAVE_WVALID & SLAVE_WREADY & SLAVE_WLAST )		// wait until end of burst
				begin
					if ( wburstLen != txLen )
						begin
							$display( "%d, AXISLAVEGEN %d WLAST Error, expBurstLen= %d, actBurstLen= %d \n\n", 
											$time, SLAVE_NUM, wburstLen, txLen );
									
							#1 $stop;
						end		
				end
		end

`ifdef VERBOSE
	//=============================================================================================
	// Display WDAT - data begin written into RAM
	//=============================================================================================
	always @( negedge sysClk )
		begin	
			if ( SLAVE_WVALID & SLAVE_WREADY )		
				begin
					$display( "%t, %m, memWrAddr=%h (%d), SLAVE_WDATA= %d, SLAVE_WSTRB= %h", $time, memWrAddr, memWrAddr, SLAVE_WDATA, SLAVE_WSTRB );
				end
		end		
`endif

		
`endif
	
	
//===========================================================================================
 // FIFO to hold open transactions - pushed on Write Address cycle and popped on Write data
 // cycle.
 //===========================================================================================
 FifoDualPort #(	.FIFO_AWIDTH( OPENTRANS_MAX ),
					.FIFO_WIDTH( READFIF_WIDTH ),
					.HI_FREQ( HI_FREQ ),
					.NEAR_FULL( 'd2 )
				)
		wrFif(
					.HCLK(	sysClk ),
					.fifo_reset( sysReset ),
					
					// Write Port
					.fifoWrite( wrFifWr ),
					.fifoWrData( wrFifWrData ),

					// Read Port
					.fifoRead( wrFifRd ),
					.fifoRdData( wrFifRdData ),
					
					// Status bits
					.fifoEmpty ( wrFifoEmpty ) ,
					.fifoOneAvail( ),
					.fifoRdValid(  ),
					.fifoFull(  ),
					.fifoNearFull( wrFifoFull ),
					.fifoOverRunErr( wrFifoOverRunErr ),
					.fifoUnderRunErr( wrFifoUnderRunErr )
				   
				);

				
FifoDualPort #(		.FIFO_AWIDTH( OPENTRANS_MAX ),
					.FIFO_WIDTH( RESPFIF_WIDTH ),
					.HI_FREQ( HI_FREQ ),
					.NEAR_FULL ( 'd2 )
				)
		rspFif(
					.HCLK(	sysClk ),
					.fifo_reset( sysReset ),
					
					// Write Port
					.fifoWrite( respFifWr ),
					.fifoWrData( respFifWrData ),

					// Read Port
					.fifoRead( respFifRd ),
					.fifoRdData( respFifRdData ),
					
					// Status bits
					.fifoEmpty ( respFifoEmpty ) ,
					.fifoOneAvail( ),
					.fifoRdValid ( ),
					.fifoFull( respFifoFull ),
					.fifoNearFull( ),
					.fifoOverRunErr( respFifoOverRunErr ),
					.fifoUnderRunErr( respFifoUnderRunErr )
				   
				);
   
   
//====================================================================================================
// Slave Write Address S/M
//===================================================================================================== 
 always @( * )
 begin
 
	awnextState <= awcurrState;
	
	d_SLAVE_AWREADY	<=  (waddr_rand_sig > 50);
	wrFifWr		<= 0;

	wrFifWrData <= { SLAVE_AWID, SLAVE_AWADDR, SLAVE_AWLEN, SLAVE_AWSIZE, SLAVE_AWBURST };
	
	d_awCount	<= awCount;
	
	case( awcurrState )
		awstIDLE: begin
					d_SLAVE_AWREADY <= (waddr_rand_sig > 50);
		
					if ( SLAVE_AWVALID & SLAVE_AWREADY )		// if both ends ready for transaction
						begin
							wrFifWrData <= { SLAVE_AWID, SLAVE_AWADDR, SLAVE_AWLEN, SLAVE_AWSIZE, SLAVE_AWBURST };
							wrFifWr	<= 1;
							d_awCount	<= awCount + 1'b1;

							awnextState	<= awstIDLE;
						end
					else if ( SLAVE_AWVALID & !SLAVE_AWREADY )
						begin
							awnextState	<= awstDATA;
						end
				end
		awstDATA : begin
					d_SLAVE_AWREADY <= 1'b1;

					if ( SLAVE_AWVALID & SLAVE_AWREADY )		// 	last beat
						begin
							d_SLAVE_AWREADY	<= (waddr_rand_sig > 50);
							
							wrFifWrData <= { SLAVE_AWID, SLAVE_AWADDR, SLAVE_AWLEN, SLAVE_AWSIZE, SLAVE_AWBURST };
							wrFifWr	  	<= 1;
							d_awCount	<= awCount + 1'b1;
	
							awnextState	<= awstIDLE;

						end
				end
	endcase
end


 always @(posedge sysClk or posedge sysReset)		
 begin
	if (sysReset)
		begin
			awcurrState 		<= awstIDLE;
			preSLAVE_AWREADY	<= 0;
			awCount				<= 0;

		end
	else
		begin
			awcurrState 		<= awnextState;
			preSLAVE_AWREADY	<= d_SLAVE_AWREADY;
			awCount				<= d_awCount;
			
		end
end


assign SLAVE_AWREADY = preSLAVE_AWREADY & !wrFifoFull & (waddr_rand_sig == 98);

assign 	respFifWrData = { respWID, respResp };

//====================================================================================================
// Counter for Idle on each Write Data
//====================================================================================================
always @(posedge sysClk or posedge sysReset )
begin
	if ( sysReset )
		begin
			idleWrCount	<= 0;		// initialise to 1
		end
	else if ( idleWrCountClr )
		begin
			idleWrCount	<= 0;		// initiales to 1
		end
	else if ( idleWrCountIncr )
		begin
			idleWrCount	<= idleWrCount + 1'b1;
		end
end


//=================================================================================================
// Create mask to "align" memWrAddr
//=================================================================================================
always @( * )
	begin
		case( wrWSize )
			3'h0 : memWrAddrAlignedMask <=   { (LOWER_COMPARE_BIT+ALIGNED_BITS  ){1'b1} };
			3'h1 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-1){1'b1} }, 1'b0 };
			3'h2 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-2){1'b1} }, 2'b0 };
			3'h3 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-3){1'b1} }, 3'b0 };
			3'h4 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-4){1'b1} }, 4'b0 };
			3'h5 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-5){1'b1} }, 5'b0 };
			3'h6 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-6){1'b1} }, 6'b0 };
			3'h7 : memWrAddrAlignedMask <= { { (LOWER_COMPARE_BIT+ALIGNED_BITS-7){1'b1} }, 7'b0 };
		endcase
	end
 //====================================================================================================
 // Slave Write Data S/M
//===================================================================================================== 
 always @( * )
 begin
 
	wnextState 		<= wcurrState;

	memWrData <= SLAVE_WDATA;
	memWr	  <= 0;
	
	d_SLAVE_WREADY	<= 0;

	wrFifRd	  	<= 0;			
	respFifWr	<= 0;

	d_respWID	<= respWID;
	d_wburstLen	<= wburstLen;
	d_memWrAddr	<= memWrAddr;
	d_txLen		<= txLen;
	d_wrBurstType <= wrBurstType;
	d_wrWSize	  <= wrWSize;
	
	d_idleWrCycles <= idleWrCycles;
	
	d_txCount	<= txCount;
	
	respResp	<= FORCE_ERROR 	? 2'b10  : 2'b00;
	
	idleWrCountClr	<= 1'b0;
	idleWrCountIncr	<= 1'b0;

	case( wcurrState )
		wstIDLE: begin
					
					d_txLen <= 0;
					
					d_wburstLen	<= 0;
					d_wrWSize	<= 0;
					d_respWID	<= 0;

					//READFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 
					d_memWrAddr	<= 0;

					
					if ( ~wrFifoEmpty )
						begin
							d_SLAVE_WREADY	<= 1'b1;
	
							d_wrBurstType <= wrFifRdData[1:0];
							d_wrWSize	  <= wrFifRdData[4:2 ]; 	// pickout AWSIZE

							d_wburstLen	<= wrFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ]; // pickout AWLEN
							d_respWID	<= wrFifRdData[READFIF_WIDTH-1: READFIF_WIDTH- ID_WIDTH];

							//localparam	READFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 
							d_memWrAddr	<= wrFifRdData[READFIF_WIDTH- ID_WIDTH-1: READFIF_WIDTH-ID_WIDTH - ADDR_WIDTH];  // pick out write start address

							wrFifRd <= 1;		// pop entry
															
							wnextState 	<= wstDATA;
						end
				end
						
		wstDATA : begin
					d_SLAVE_WREADY	<= 1'b1;
					
					idleWrCountClr 	<= 1'b1;
				
					if ( SLAVE_WVALID & SLAVE_WREADY )		// wait until address available for start
						begin
							memWr	  <= 1'b1; //&SLAVE_WSTRB;		// Hack - assumes all bytes have to be written on bus.

							case( wrBurstType )
								2'b00:		// fixed
									begin
										d_memWrAddr	<= memWrAddr;
									end
								2'b01:		// increment
									begin
										d_memWrAddr <= ( memWrAddr & memWrAddrAlignedMask) + ( 1 << wrWSize );
																				// increment by number of bytes transferred
									end
								2'b10:		// wrap - not handling wrap correctly
									begin
										d_memWrAddr <= ( memWrAddr & memWrAddrAlignedMask) + ( 1 << wrWSize );
																				// increment by number of bytes transferred
									end
								2'b11:
									begin
										$stop;		/// should not get here
									end								
							endcase
								
							if ( SLAVE_WLAST )			// 1-beat
								begin													
									d_txCount		<= txCount + 1'b1;
									d_txLen			<= 0;
									
									respFifWr		<= 1'b1;
									
									if ( ~wrFifoEmpty & ~SLAVE_DATA_IDLE_EN)		// another data available - and not IDLE_EN on
										begin
											d_wrBurstType <= wrFifRdData[1:0];
											d_wrWSize	  <= wrFifRdData[4:2 ]; 	// pickout AWSIZE

											d_wburstLen	<= wrFifRdData[READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-1: READFIF_WIDTH-ID_WIDTH-ADDR_WIDTH-8 ]; // pickout ARLEN
											d_respWID	<= wrFifRdData[READFIF_WIDTH-1: READFIF_WIDTH- ID_WIDTH];	
											//localparam	READFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 
											d_memWrAddr	<= wrFifRdData[READFIF_WIDTH- ID_WIDTH-1: READFIF_WIDTH-ID_WIDTH - ADDR_WIDTH];  // pick out write start address
											wrFifRd <= 1;		// pop entry
											
											d_SLAVE_WREADY	<= 1'b1;									
											wnextState 		<= wstDATA;
										end
									else
										begin
											d_SLAVE_WREADY	<= 1'b0;									
											wnextState 		<= wstIDLE;
										end
								end
							else
								begin
									d_txLen		<= txLen + 1'b1;
									
									//============================================================================
									// see if idle cycles to be inserted
									//============================================================================
									if ( SLAVE_DATA_IDLE_EN )
										begin
											d_SLAVE_WREADY	<= 1'b0;

											case (SLAVE_DATA_IDLE_CYCLES)
												2'b00:		// random cycles
													begin
														`ifdef SIM_MODE		// only use random when in simulation
															d_idleWrCycles <= $random(); 
														`else
															d_idleWrCycles <= 0; 
														`endif
													end
												2'b01:		// 1 idle cycle
													begin
														d_idleWrCycles <= 4'd1; 
													end
												2'b10:		// 2 idle cycle
													begin
														d_idleWrCycles <= 4'd2; 
													end
												2'b11:		// 3 idle cycle
													begin
														d_idleWrCycles <= 4'd3; 
													end
											endcase
							
											wnextState 		<= wstIDLE_DATA;
										end
									else
										begin
											d_idleWrCycles <= 0;
											wnextState 	<= wstDATA;
										end
								end
						end
				end
		wstIDLE_DATA : begin

					d_SLAVE_WREADY	<= 1'b0;
		
					if ( idleWrCount == idleWrCycles )		// if had all idle cycles
						begin
							d_SLAVE_WREADY	<= 1'b1;

							wnextState 		<= wstDATA;
						end
					else
						begin
							idleWrCountIncr	<= 1'b1;
							
							wnextState 		<= wstIDLE_DATA;
						end
				end			
	endcase
end


 always @(posedge sysClk or posedge sysReset)
 begin
 
	if (sysReset)
		begin
			txLen 			<= 0;
			memWrAddr		<= 0;
			
			respWID			<= 0;
			wburstLen		<= 0;
			SLAVE_WREADY	<= 0;
			txCount			<= 0;
			wrBurstType 	<= 0;
			wrWSize			<= 0;
			
			idleWrCycles	<= 0;

			wcurrState	<= wstIDLE;
		end
	else
		begin
			txLen 			<= d_txLen;
			memWrAddr		<= d_memWrAddr;
		
			respWID			<= d_respWID;
			wburstLen		<= d_wburstLen;
			SLAVE_WREADY	<= d_SLAVE_WREADY & !respFifoFull;
			
			txCount		<= d_txCount;
			wrBurstType <= d_wrBurstType;
			wrWSize		<= d_wrWSize;

			idleWrCycles <= d_idleWrCycles;
		
			wcurrState	<= wnextState;
		end
end

