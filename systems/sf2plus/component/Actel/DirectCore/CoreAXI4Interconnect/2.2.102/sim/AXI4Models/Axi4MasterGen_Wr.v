// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Master Write test source.
//              It initialiates a Master write on Write Address channel.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

//================================================================================================
// Local Parameters
//================================================================================================
 
localparam	WRFIF_WIDTH = ( ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 );			// ID, Addr, LEN and SIZE, and Burst 
localparam	RESPFIF_WIDTH = ( ID_WIDTH + 2 );			// ID, Resp

  wire [4:0]   wr_addr_beat;
  wire [4:0]   wr_to_boundary_master;
   wire      [9:0]  WriteAddrMaskWrap;

wire [(DATA_WIDTH/8)-1:0] mask_strb;

wire [5:0] 			WriteAddrMask;
wire						wrfifoOverRunErr, wrfifoUnderRunErr;

reg		[WRFIF_WIDTH-1:0]			wrFifWrData;
wire	[WRFIF_WIDTH-1:0]		wrFifRdData;
reg		[WRFIF_WIDTH-1:0]			wrFifRdDataHold;

reg							wrFifWr, wrFifRd;
wire						wrFifoFull, wrFifoEmpty, wrFifoOneAvail;

reg							respFifWr, respFifRd;
wire						respFifoFull, respFifoEmpty;

wire	[RESPFIF_WIDTH-1:0]	respFifRdData;
wire	[RESPFIF_WIDTH-1:0]	respFifWrData;	

reg		[ID_WIDTH-1:0]		respWID, d_respWID;
reg		[ADDR_WIDTH-1:0]	d_masterWrAddr, masterWrAddr;			// used to track address being sent out.

 //===========================================================================================
 // FIFO to hold open transactions - pushed on Address Read cycle and popped on write data
 // cycle.
 //===========================================================================================
 FifoDualPort #(	.FIFO_AWIDTH( OPENTRANS_MAX ),
					.FIFO_WIDTH( WRFIF_WIDTH ),
					.HI_FREQ( HI_FREQ ),
					.NEAR_FULL ( 'd2 )
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
					.fifoOneAvail( wrFifoOneAvail ),
					.fifoRdValid(	),
					.fifoFull( wrFifoFull ),
					.fifoNearFull(	),
					.fifoOverRunErr( wrfifoOverRunErr ),
					.fifoUnderRunErr( wrfifoUnderRunErr )
					 
				);

assign mstWrAddrFull = wrFifoFull;


//===========================================================================================
// Storage latch for data cycle to be processed
//===========================================================================================
always @(posedge sysClk or	posedge sysReset )
begin
	
	if ( sysReset )
		begin
			wrFifRdDataHold	<= 0;
		end
	else if ( wrFifRd )
		begin
			wrFifRdDataHold	<= wrFifRdData;
		end
end


//===========================================================================================
 // FIFO to hold open transactions - pushed on Write Data cycle and popped on write response
 // cycle.
 //===========================================================================================				
	FifoDualPort #(	.FIFO_AWIDTH( OPENTRANS_MAX ),
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
					.fifoOneAvail(		 ),
					.fifoRdValid(	),
					.fifoFull( respFifoFull ),
					.fifoNearFull(	),
					.fifoOverRunErr( respFifoOverRunErr ),
					.fifoUnderRunErr( respFifoUnderRunErr )
					 
				);

				
assign 	respFifWrData = { respWID, expWResp };


//====================================================================================================
// Local Declarationes for Master Write Address 
//====================================================================================================

localparam	[2:0]		wstIDLE = 3'h0,	wstDATA = 3'h1;

reg [(DATA_WIDTH/8)-1:0]	 	d_MASTER_WSTRB;
reg 												d_MASTER_WLAST, d_MASTER_WVALID;
reg [USER_WIDTH-1:0]				d_MASTER_WUSER;

reg [2:0]				wcurrState, wnextState;

reg	[DATA_WIDTH-1:0]	d_txLen, txLen;

reg [15:0]				txCount, d_txCount;
reg [15:0]				awCount, d_awCount;

wire [7:0]				curTxLen, curTxLenHold;
wire [ID_WIDTH-1:0]		curWID, curWIDHold;


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
	
			if ( MASTER_AWVALID )
				begin
					#1 $display( "%d, MASTER %d - Starting Write Address Transaction %d, AWADDR= %h, AWBURST= %h, AWSIZE= %h, WID= %h, AWLEN= %d", 
											$time, MASTER_NUM, awCount, MASTER_AWADDR, MASTER_AWBURST, MASTER_AWSIZE, MASTER_AWID, MASTER_AWLEN );

					if ( MASTER_AWREADY )		// single beat
						begin
							#1 $display( "%d, MASTER %d - Ending Write Address Transaction %d, WID= %h, AWLEN= %d", 
											$time, MASTER_NUM, awCount, MASTER_AWID, MASTER_AWLEN );
						end
					else
						begin
							@( posedge MASTER_AWREADY )
								#1 $display( "%d, MASTER %d - Ending Write Address Transaction %d, WID= %h, AWLEN= %d", 
											$time, MASTER_NUM, awCount, MASTER_AWID, MASTER_AWLEN );
						end
				end
		end	


	//=============================================================================================
	// Display messages for Write Data Channel
	//=============================================================================================
	always @( negedge sysClk )
		begin
			#1;
	
			if ( MASTER_WVALID )
				begin
					#1 $display( "%d, MASTER %d - Starting Write Data Transaction %d, WADDR= %h (%d), WID= %h, TXLEN= %d, WSTRB= %h", 
										$time, MASTER_NUM, txCount, masterWrAddr, masterWrAddr, curWIDHold, curTxLenHold, MASTER_WSTRB );

					if ( MASTER_WLAST &	MASTER_WVALID & MASTER_WREADY )		// single beat
						begin
							#1 $display( "%d, MASTER %d - Ending Write Data Transaction %d, WID= %h, TXLEN= %d", 
										$time, MASTER_NUM, txCount, curWIDHold, txLen );
						end
					else
						begin
							@( posedge ( MASTER_WLAST &	MASTER_WVALID & MASTER_WREADY )	)
								#1 $display( "%d, MASTER %d - Ending Write Data Transaction %d, WID= %h, TXLEN= %d", 
										$time, MASTER_NUM, txCount, curWIDHold, txLen );
						end
				end
		end

`ifdef VERBOSE
	//=============================================================================================
	// Display Write Data
	//=============================================================================================
	always @( negedge sysClk )
		begin
			#1;

			if ( MASTER_WVALID & MASTER_WREADY )
				begin
					#1 $display( "%t, MASTER %d - ADDR= %h (%d), WDATA= %d, WSTRB= %h", 
										$time, MASTER_NUM, masterWrAddr, masterWrAddr, MASTER_WDATA, MASTER_WSTRB );
				end
		end		
`endif

`endif


assign	curTxLen 			= wrFifRdData[12:5];										// pick out txLen from FIFO data
assign	curTxLenHold	= wrFifRdDataHold[12:5];								// pick out txLen from Hold data

assign	curWID				= wrFifRdData[WRFIF_WIDTH-1:WRFIF_WIDTH-ID_WIDTH];				// pick out WID from FIFO data
assign	curWIDHold		= wrFifRdDataHold[WRFIF_WIDTH-1:WRFIF_WIDTH-ID_WIDTH];		// pick out WID from Hold data

wire	[ADDR_WIDTH-1:0]	wDStartAddr;
wire	[2:0]							wD_AWSIZE, repMultip;
reg		[2:0]							wD_AWSIZE_next, wD_AWSIZE_reg;
wire	[1:0]							wD_AWBURST;
 
assign repMultip		= (1 << wD_AWSIZE);
assign wDStartAddr	= wrFifRdData[WRFIF_WIDTH-ID_WIDTH-1:WRFIF_WIDTH-ID_WIDTH-ADDR_WIDTH]; 
assign wD_AWSIZE		= wrFifRdData[4:2];
assign wD_AWBURST	 	= wrFifRdData[1:0];

assign WriteAddrMask = (6'h3f << wD_AWSIZE_reg);
assign WriteAddrMaskWrap = (10'h3ff << $clog2((wrBurstLen+1) * ( 1 << wrASize )));

  assign wr_addr_beat = wrStartAddr[wrASize+:4] & wrBurstLen;
  assign wr_to_boundary_master = (wrBurstLen + 1) - wr_addr_beat;

//====================================================================================================
// Master Data S/M
//===================================================================================================== 
 always @( * )
 begin
 
	wnextState 		<= wcurrState;
	masterWrDone	<= 0;
	wrFifRd			<= 0;
	respFifWr		<= 0;

	d_MASTER_WUSER	<= MASTER_WUSER;

	d_MASTER_WLAST	<= 0;
	d_MASTER_WVALID	<= 0;

	d_txCount	<= txCount;

	d_respWID	<= respWID;

	d_txLen 	<= txLen;
	d_masterWrAddr <= masterWrAddr;
	wD_AWSIZE_next <= wD_AWSIZE_reg;

	case( wcurrState )
		wstIDLE: begin
					d_respWID	<= 0;
					d_respWID	<= wrFifRdData[WRFIF_WIDTH-1: WRFIF_WIDTH- ID_WIDTH];

					if ( wrFifoEmpty )
						begin
							d_txLen 		<= 0;
							d_MASTER_WUSER 	<= 0;
						end
					else if ( ~wrFifoEmpty )
						begin
							d_MASTER_WVALID	<= 1;
							d_MASTER_WLAST	<= ( curTxLen == 0 );		// only 1-beat

							d_masterWrAddr <= wDStartAddr;
							wD_AWSIZE_next <= wD_AWSIZE;

							wAddrMask <= (wDStartAddr[5:0] & ((DATA_WIDTH/8)-1)) >> wD_AWSIZE;
							d_MASTER_WUSER	<= 0;

							wrFifRd			<= 1;						// pop fifo - use hold for current cycle.
							
							wnextState	<= wstDATA;
						end
				end
		wstDATA : begin
					
					d_respWID	<= wrFifRdDataHold[WRFIF_WIDTH-1: WRFIF_WIDTH- ID_WIDTH];
				
					d_MASTER_WVALID	<= 1;
					d_MASTER_WLAST	<= MASTER_WLAST;		// only if set until VALID/READY Seen
					wAddrMask <= ((masterWrAddr+wD_AWSIZE*(txLen+1)) & ((DATA_WIDTH/8)-1)) >> wD_AWSIZE;

					if ( MASTER_WREADY & MASTER_WVALID & MASTER_WLAST)
						begin

							masterWrDone	<= 1;
							respFifWr		<= 1;

							d_MASTER_WUSER	<= 0;

							d_txLen		<= 0;
							d_txCount 	<= txLen + 1;

							if (~wrFifoEmpty)		// another data transaction available
								begin
									d_MASTER_WLAST	<= ( curTxLen == 0 );		
									d_MASTER_WVALID	<= 1;

									d_masterWrAddr <= wDStartAddr;

									d_respWID			<= wrFifRdData[WRFIF_WIDTH-1: WRFIF_WIDTH- ID_WIDTH];
									wrFifRd				<= 1;			// pop entry - next entry is in hold
									wnextState		<= wstDATA;
								end
							else					// no other entries to handle
								begin
									d_MASTER_WLAST	<= 0;		
									d_MASTER_WVALID	<= 0;
									d_respWID		<= wrFifRdDataHold[WRFIF_WIDTH-1: WRFIF_WIDTH- ID_WIDTH];
									wrFifRd			<= 0;

									wnextState	<= wstIDLE;
								end
						end
					else if ( MASTER_WREADY & MASTER_WVALID & ~MASTER_WLAST)
						begin
							d_txCount 	<= txLen + 1;
							d_txLen			<= txLen + 1;
							if (MASTER_AWBURST == 2'b00) begin
							 	d_masterWrAddr <= masterWrAddr;
							end
              else if (MASTER_AWBURST == 2'b10) begin
                if (txLen == (wr_to_boundary_master-1)) begin
                d_masterWrAddr <= { masterWrAddr[ADDR_WIDTH-1:10], (masterWrAddr[9:0] & WriteAddrMaskWrap)};
                end else begin
                d_masterWrAddr <= masterWrAddr + (1 << wD_AWSIZE_reg);
                end
              end
							else begin
								d_masterWrAddr <= { masterWrAddr[ADDR_WIDTH-1:6], (masterWrAddr[5:0] & WriteAddrMask) } + (1 << wD_AWSIZE_reg);
							end

							if ( (curTxLenHold -1'b1) == txLen[7:0] ) 		// last beat
								begin
									d_MASTER_WLAST	<= 1;
									wnextState	<= wstDATA;
								end
							else
								begin
									d_MASTER_WUSER	<= MASTER_WUSER -1'b1;		// rotate
									wnextState	<= wstDATA;
								end
						end
					end
	endcase
end

always @(*)
begin	
		//==============================================================
		// Set WSTRB bits based on alignment - just for startAddress
		//==============================================================
		// The below case statement(DATA_WIDTH) allows the strobes to be applied properly. The size of the bus determines the
		// max transfer size
			case (DATA_WIDTH)
			// The case statement (MASTER_AWSIZE) applies a strobe on a 'per-byte' basis. The strobe is set the the correct size, 
			// depending on the transfer size, and is then shifted by the apptoptiate number of bytes.
			'd32 :	case(wD_AWSIZE_next)
							 3'b000 : d_MASTER_WSTRB	<= 4'h1 << (d_masterWrAddr[1:0]);
							 3'b001 : d_MASTER_WSTRB	<= 4'h3 << 2*(d_masterWrAddr[1]);
							 3'b010 : d_MASTER_WSTRB	<= 4'hF;														 // No shift as size = data width
							endcase
			'd64 :	case(wD_AWSIZE_next)
							 3'b000 : d_MASTER_WSTRB	<= 8'h1 << (d_masterWrAddr[2:0]);
							 3'b001 : d_MASTER_WSTRB	<= 8'h3 << 2*(d_masterWrAddr[2:1]);
							 3'b010 : d_MASTER_WSTRB	<= 8'hF << 4*(d_masterWrAddr[2]);
							 3'b011 : d_MASTER_WSTRB	<= 8'hFF;														// No shift as size = data width
							endcase
			'd128 : case(wD_AWSIZE_next)
							 3'b000 : d_MASTER_WSTRB	<= 16'h1 << (d_masterWrAddr[3:0]);
							 3'b001 : d_MASTER_WSTRB	<= 16'h3 << 2*(d_masterWrAddr[3:1]);
							 3'b010 : d_MASTER_WSTRB	<= 16'hF << 4*(d_masterWrAddr[3:2]);
							 3'b011 : d_MASTER_WSTRB	<= 16'hFF << 8*(d_masterWrAddr[3]);
							 3'b100 : d_MASTER_WSTRB	<= 16'hFFFF;													// No shift as size = data width
							endcase
			'd256 : case(wD_AWSIZE_next)
							 3'b000 : d_MASTER_WSTRB	<= 32'h1 << (d_masterWrAddr[4:0]);
							 3'b001 : d_MASTER_WSTRB	<= 32'h3 << 2*(d_masterWrAddr[4:1]);
							 3'b010 : d_MASTER_WSTRB	<= 32'hF << 4*(d_masterWrAddr[4:2]);
							 3'b011 : d_MASTER_WSTRB	<= 32'hFF << 8*(d_masterWrAddr[4:3]);
							 3'b100 : d_MASTER_WSTRB	<= 32'hFFFF << 16*(d_masterWrAddr[4]);
							 3'b101 : d_MASTER_WSTRB	<= 32'hFFFF_FFFF;										 // No shift as size = data width
							endcase
			'd512 : case(wD_AWSIZE_next)
							 3'b000 : d_MASTER_WSTRB	<= 64'h1 << (d_masterWrAddr[5:0]);
							 3'b001 : d_MASTER_WSTRB	<= 64'h3 << 2*(d_masterWrAddr[5:1]);
							 3'b010 : d_MASTER_WSTRB	<= 64'hF << 4*(d_masterWrAddr[5:2]);
							 3'b011 : d_MASTER_WSTRB	<= 64'hFF << 8*(d_masterWrAddr[5:3]);
							 3'b100 : d_MASTER_WSTRB	<= 64'hFFFF << 16*(d_masterWrAddr[5:4]);
							 3'b101 : d_MASTER_WSTRB	<= 64'hFFFF_FFFF << 32*(d_masterWrAddr[5]);
							 3'b110 : d_MASTER_WSTRB	<= 64'hFFFF_FFFF_FFFF_FFFF;					 // No shift as size = data width
							endcase
			endcase

end


always @(posedge sysClk or posedge sysReset )
 begin
 
	if (sysReset)
		begin
			wcurrState 	<= wstIDLE;

			txLen 		<= 0;
			txCount		<= 0;

			MASTER_WVALID	<= 0;
			MASTER_WDATA	<= 0;
			MASTER_WSTRB	<= 0;
			MASTER_WUSER	<= 0;
			MASTER_WLAST	<= 0;

			respWID	<= 0;
			masterWrAddr	<= 0;

			wD_AWSIZE_reg <= 3'h0;

		end
	else
		begin
			wcurrState	<= wnextState;

			txLen			<= d_txLen;
			txCount 	<= d_txCount;

			wD_AWSIZE_reg <= wD_AWSIZE_next;

			MASTER_WVALID	<= d_MASTER_WVALID;
			MASTER_WDATA	<= d_txLen + MASTER_NUM + baseValue;				// have all Master use a unique sequence
			MASTER_WLAST	<= d_MASTER_WLAST;
			MASTER_WSTRB	<= d_MASTER_WSTRB & mask_strb;
			MASTER_WUSER	<= d_MASTER_WUSER;

			respWID				<= d_respWID;
			masterWrAddr	<= d_masterWrAddr;
		end
end

assign mask_strb = ~((1 << (d_masterWrAddr[5:0] & ((DATA_WIDTH/8)-1)))-1);

//====================================================================================================
// Local Declarationes for Master Write Address 
//====================================================================================================
reg [ID_WIDTH-1:0]					d_MASTER_AWID;
reg [ADDR_WIDTH-1:0]				d_MASTER_AWADDR;
reg [7:0]								 		d_MASTER_AWLEN;
reg [2:0]								 		d_MASTER_AWSIZE;
reg [2:0]								 		max_AWSIZE;
reg [1:0]								 		d_MASTER_AWBURST;
reg [1:0]								 		d_MASTER_AWLOCK;
reg [3:0]								 		d_MASTER_AWCACHE;
reg [2:0]									 	d_MASTER_AWPROT;
reg [3:0]										d_MASTER_AWREGION;
reg [3:0]								 		d_MASTER_AWQOS;		// not used
reg [USER_WIDTH-1:0]				d_MASTER_AWUSER;
reg												 	d_MASTER_AWVALID;

reg [2:0]										awcurrState, awnextState;

localparam	[2:0]	 awstIDLE = 3'h0,	awstDATA = 3'h1;

//=====================================================================================================
// Master Write Address S/M
//=====================================================================================================
always @( * )
 begin

	awnextState <= awcurrState;

	d_MASTER_AWID			<= MASTER_AWID;
	d_MASTER_AWADDR		<= MASTER_AWADDR;
	d_MASTER_AWLEN		<= MASTER_AWLEN;
	d_MASTER_AWSIZE 	<= MASTER_AWSIZE;
	d_MASTER_AWBURST	<= MASTER_AWBURST;
	d_MASTER_AWLOCK		<= MASTER_AWLOCK;
	d_MASTER_AWCACHE	<= MASTER_AWCACHE;
	d_MASTER_AWPROT		<= MASTER_AWPROT;
	d_MASTER_AWREGION	<= MASTER_AWREGION;
	d_MASTER_AWQOS		<= MASTER_AWQOS;		// not used
	d_MASTER_AWUSER		<= MASTER_AWUSER;
	d_MASTER_AWVALID	<= MASTER_AWVALID;	

	mstWAddrIdle	<= 0;
	wrFifWr				<= 0;

	masterWrAddrDone	<= 0;
	if (wrASize > MASTER_ASIZE_DEFAULT)
		begin
			max_AWSIZE <= MASTER_ASIZE_DEFAULT;
			$display( "%d, MASTER %d ERROR - requested transfer size exceed data width limitation and is reset to %b", $time, MASTER_NUM, MASTER_ASIZE_DEFAULT );
		end
	else
		begin
			max_AWSIZE <= wrASize;
		end

	wrFifWrData <= { wrAID, wrStartAddr, wrBurstLen, max_AWSIZE, BurstType };

	d_awCount	<= awCount;

	case( awcurrState )
		awstIDLE: begin
					mstWAddrIdle			<= 1;

					if ( wrStart & !wrFifoFull )						// start write address transaction
						begin
							d_MASTER_AWVALID	<= 1'b1;

							d_MASTER_AWID			<= wrAID;
							d_MASTER_AWADDR		<= wrStartAddr;			// make up data to be easy read in simulation
							d_MASTER_AWLEN 		<= wrBurstLen;
							d_MASTER_AWSIZE 	<= max_AWSIZE;
							d_MASTER_AWBURST	<= BurstType;
							d_MASTER_AWLOCK		<= 0;
							d_MASTER_AWCACHE	<= 0;
							d_MASTER_AWPROT		<= 0;
							d_MASTER_AWREGION	<= 0;
							d_MASTER_AWQOS		<= 0;		// not used
							d_MASTER_AWUSER		<= 1;

							awnextState <= awstDATA;
							
							//========================================================================================
							// Initiate Write Channel early if MASTER_WREADY_Default asserted - ie do not wait
							// till Write Address transactioon completed.
							//=========================================================================================
							if ( MASTER_WREADY_Default )
								begin
									wrFifWr		<= 1;		// push fifo 
								end
						end
				end
		awstDATA : begin
					d_MASTER_AWVALID	<= 1'b1;

					if ( MASTER_AWVALID & MASTER_AWREADY )
						begin
						
							masterWrAddrDone <= 1'b1;
							d_awCount	<= awCount + 1'b1;

							//========================================================================================
							// Initiate Write Channel if MASTER_WREADY_Default not asserted - ie start write data
							// after Write Address transactioon completed.
							//=========================================================================================
							if ( ~MASTER_WREADY_Default )
								begin
									wrFifWr		<= 1;		// push fifo 
								end

							if ( wrStart & !wrFifoFull)				// if another burst request and space
								begin
									d_MASTER_AWVALID	<= 1'b1;
									d_MASTER_AWID			<= wrAID;
									d_MASTER_AWADDR		<= wrStartAddr;				// make up data to be easy read in simulation
									d_MASTER_AWLEN 		<= wrBurstLen;
									d_MASTER_AWSIZE 	<= max_AWSIZE;

									awnextState <= awstDATA;

									//========================================================================================
									// Initiate Write Channel early if MASTER_WREADY_Default asserted - ie do not wait
									// till Write Address transactioon completed.
									//=========================================================================================
									if ( MASTER_WREADY_Default )
										begin
											wrFifWrData <= { wrAID, wrStartAddr, wrBurstLen, max_AWSIZE, BurstType };
											wrFifWr			<= 1;		// push fifo 
										end
								end
							else
								begin
									d_MASTER_AWVALID	<= 1'b0;
									awnextState				<= awstIDLE;
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
			MASTER_AWVALID	<= 1'b0;

			MASTER_AWID	  	<= 0;
			MASTER_AWADDR 	<= 0;				// make up data to be easy read in simulation
			MASTER_AWLEN  	<= 0;
			MASTER_AWSIZE 	<= 0;
			MASTER_AWBURST	<= 0;
			MASTER_AWLOCK 	<= 0;
			MASTER_AWCACHE	<= 0;
			MASTER_AWPROT 	<= 0;
			MASTER_AWREGION	<= 0;
			MASTER_AWQOS	  <= 0;		// not used
			MASTER_AWUSER 	<= 0;

			awCount			<= 0;

			awcurrState	<= awstIDLE;
		end
	else
		begin
			MASTER_AWVALID	<= d_MASTER_AWVALID;

			MASTER_AWID	<= d_MASTER_AWID;
			MASTER_AWADDR	<= d_MASTER_AWADDR;				// make up data to be easy read in simulation
			MASTER_AWLEN 	<= d_MASTER_AWLEN;
			MASTER_AWSIZE 	<= d_MASTER_AWSIZE;
			MASTER_AWBURST	<= d_MASTER_AWBURST;
			MASTER_AWLOCK	<= d_MASTER_AWLOCK;
			MASTER_AWCACHE	<= d_MASTER_AWCACHE;
			MASTER_AWPROT 	<= d_MASTER_AWPROT;
			MASTER_AWREGION	<= d_MASTER_AWREGION;
			MASTER_AWQOS	<= d_MASTER_AWQOS;		// not used
			MASTER_AWUSER   <= d_MASTER_AWUSER;

			awCount		<= d_awCount;
			
			awcurrState	<= awnextState;
		end
end

		

