`timescale 1ns / 1ns


// *************************************************************************************************************/
// Cloudium Systems Ltd. Proprietary and Confidential
//   
// Copyright 2014 Cloudium Systems Ltd.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE CLOUDIUM SYSTEMS LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING. 
//                                                                            
//                                                                             
// This confidential and proprietary software may be used only as authorised  
// by a licensing agreement from Cloudium Systems Ltd.                        
//                                                                            
// In the event of publication, the following notice is applicable:           
//                                                                            
// (C) COPYRIGHT 2014  Cloudium Systems LTD.                      
// ALL RIGHTS RESERVED                                                        
//                                                                            
// File			: SlvAXI4ProtocolConv.v                                            
// Author		: Olga Birkvalde                                                  
// Date			: 02/03/15                                                   
// Version		: 1.1                                                     	  
//                                                                            
// Abstract	: 	This file provides an Protocol Converter for AXI3 or AXILite slave write channels. 
//                                                               
//              Note: AXI3 Interleaving not supported in AXI3 interface module.                                                              
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 02/09/14		OB			1.0			Initial release version 
// 22/02/15		JH			1.1			Modified to allow both AXI3 and AXI4Lite slaves to be handled in this module.               
// 28/02/15		JH			1.2			Fixed bug where unaligned address not handled correctly.   
// 17/06/16     JHayes      1.3         Fixed bug for SAR76932. Issue of WID signals (used in AXI3), changing at invalid 
//                                      time (when WVALID was high).  
// 24/06/16     JHayes      1.4         Fixed bug to do with large AXI3 transactions (i.e. number of data 
//                                      words greater than 16) being received, ensuring that no unrelated transactions 
//                                      appear between related AXI3 transactions. Otherwise it causes problems
//                                      for the AXI3 to AXI4 conversion logic for the Write Response channel.  
// 27/06/16     JHayes      1.5         Bug around making sure that AXI4-lite B transactions received will send the correct 
//                                      BID field when putting AXI4 transactions back together again in this conversion logic,
//                                      sending after the expected number of AXI4-lite transactions have been received.
// 30/06/16     JHayes      1.6         Fixing of bug to do with normal AXI3 transactions following large AXI3 transactions, 
//                                      leading to WID signals changing when WVALID was high.
//
// *************************************************************************************************************/
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// synopsys translate_off
//`include "../include/Timescale.h"
// synopsys translate_on

`timescale 1ns/1ns

module SlvAxi4ProtConvWrite #

	(
	
		parameter integer 	SLAVE_NUMBER		= 0,			//current slave
		parameter [1:0] 	SLAVE_TYPE			= 2'b11,		// Protocol type = AXI4 - 2'b00, AXI4Lite - 2'b01, AXI3 - 2'b11	
		
		parameter integer 	ADDR_WIDTH      	= 20,			// valid values - 16 - 64
		parameter integer 	DATA_WIDTH 			= 32,			// valid widths - 32, 64, 128, 256
		
		parameter integer 	USER_WIDTH 			= 1,			// defines the number of bits for USER signals RUSER and WUSER
	
		parameter integer 	ID_WIDTH   			= 1,				// number of bits for ID (ie AID, WID, BID) - valid 1-8 
		parameter integer 	SLV_AXI4PRT_ADDRDEPTH 		= 8,		// Number transations width - 1 => 2 transations, 2 => 4 transations, etc.
		parameter integer 	SLV_AXI4PRT_DATADEPTH		= 8			// Number transations width - 1 => 2 transations, 2 => 4 transations, etc.
	)
	(

	//=====================================  Global Signals   ========================================================================
	input  wire           			ACLK,
	input  wire          			sysReset,
  // External side

	// Slave Write Address Ports
	output wire [ID_WIDTH-1:0]   	SLAVE_AWID,	
	output wire [ADDR_WIDTH-1:0] 	SLAVE_AWADDR,
	output reg [3:0]    	       	SLAVE_AWLEN,
	output wire [2:0]           	SLAVE_AWSIZE,
	output wire [1:0]           	SLAVE_AWBURST,
	output wire [1:0]            	SLAVE_AWLOCK,
	output wire [3:0] 	         	SLAVE_AWCACHE,
	output wire [2:0]           	SLAVE_AWPROT,
	output reg	                 	SLAVE_AWVALID,
	input wire                		SLAVE_AWREADY,

	
	// Slave Write Data Ports	
	output wire [ID_WIDTH-1:0]   	SLAVE_WID,	
	output wire [DATA_WIDTH-1:0]  	SLAVE_WDATA,
	output wire [(DATA_WIDTH/8)-1:0] SLAVE_WSTRB,
	output reg                   	SLAVE_WLAST,
	output reg                  	SLAVE_WVALID,
	input wire                   	SLAVE_WREADY,

			
	// Slave Write Response Ports	
	input wire [ID_WIDTH-1:0]		SLAVE_BID,
	input  wire [1:0]           	SLAVE_BRESP,
	input  wire      				SLAVE_BVALID,
	output reg						SLAVE_BREADY,


	//================================================= Internal AXI4 Side Ports  ================================================//

	// Slave Write Address Ports	
	input  wire [ID_WIDTH-1:0]   	int_slaveAWID,
	input  wire [ADDR_WIDTH-1:0] 	int_slaveAWADDR,
	input  wire [7:0]           	int_slaveAWLEN,
	input  wire [2:0]           	int_slaveAWSIZE,
	input  wire [1:0]           	int_slaveAWBURST,
	input  wire [1:0]            	int_slaveAWLOCK,
	input  wire [3:0]          		int_slaveAWCACHE,
	input  wire [2:0]           	int_slaveAWPROT,
	input  wire [3:0]           	int_slaveAWREGION,
	input  wire [3:0]           	int_slaveAWQOS,
	input  wire [USER_WIDTH-1:0] 	int_slaveAWUSER,
	input  wire                  	int_slaveAWVALID,
	output reg                		int_slaveAWREADY,
	
	// Slave Write Data Ports	
	input wire [DATA_WIDTH-1:0]   	int_slaveWDATA,
	input wire [(DATA_WIDTH/8)-1:0]	int_slaveWSTRB,
	input wire                   	int_slaveWLAST,
	input wire [USER_WIDTH-1:0] 	int_slaveWUSER,
	input wire                  	int_slaveWVALID,
	output reg                  	int_slaveWREADY,
	
	// Slave Write Response Ports	
	output wire [ID_WIDTH-1:0]		int_slaveBID,
	output wire [1:0]           	int_slaveBRESP,
	output wire [USER_WIDTH-1:0]  	int_slaveBUSER,
	output reg      				int_slaveBVALID,
	input wire						int_slaveBREADY

	);
	

	//================================== Local parameters ==============================
	
	localparam	AWLEN_BITS	= ( SLAVE_TYPE == 2'b11 ) ? 4 : 8;			// AXI3 bursts brokwn into 16 beats or less, AXILite into single beat
	localparam	MAX_BEATS	= ( SLAVE_TYPE == 2'b11 ) ? 'd16 : 'd1;		// AXI3 max bursts beats 16, AXILite is 1
	
	
	//================================== Internal ==============================

	//Write ID+number of responses to combine fifo
/*	reg 					wrFifoIdRd;
	reg 					wrFifoIdWr;
	wire 					wrFifoIdFull;
	wire 					wrFifoIdEmpty;
	
	wire [ID_WIDTH-1:0]	wrIdFifDIn;				// AWID bits
	wire [ID_WIDTH-1:0]	wrIdFifDOut;			// AWID bits
*/
    //Write ID+number of responses to combine fifo
	reg 					wrFifoLenRd;
	reg 					wrFifoLenWr;
	wire 					wrFifoLenFull;
	wire 					wrFifoLenEmpty;
    
    // wire                    lastBurstOutstanding;       // jhayes : Used to indicate that ID FIFO has only entry remaining.
     // bbriscoe: lastBurstOutstanding not needed, using latAxi3Long instead.
	
	wire [ID_WIDTH+(AWLEN_BITS-1):0]	wrLenFifDIn;			// AWLEN bits
	wire [ID_WIDTH+(AWLEN_BITS-1):0]	wrLenFifDOut;			// AWLEN bits 
	
	//Write Data + last fifo
	reg 					wrFifoDataRd;
	reg 					wrFifoDataWr;
	wire 					wrFifoDataFull;
	wire 					wrFifoDataEmpty;
	wire [(DATA_WIDTH/8)+DATA_WIDTH:0] 	wrDataFifDIn;  // WSTRB width + data width + last bit indication
	wire [(DATA_WIDTH/8)+DATA_WIDTH:0] 	wrDataFifDOut; // WSTRB width + data width + last bit indication

	// andreag: signals for correct WRAP burst address computation
	wire [10:0] wrap_nibble;
	wire [10:0] wrap_mask;

  // Data & address timing control
  reg [4:0] beatCnt;

	//============================================================================				
	// Holds Write Address from Master. Used to decouple Master side from slave
	// side by allowing FIFO to hold multiple entries. Written on Address phase
	// but not popped unit Response complete.
	//=============================================================================
	
    FifoDualPort #	(	.FIFO_AWIDTH( SLV_AXI4PRT_ADDRDEPTH ),		// depth of holding buffer 2^SLV_AXI4PRT_ADDRDEPTH
						.FIFO_WIDTH	( ID_WIDTH + AWLEN_BITS ),		// Storing AWLEN[7:0] - so burst can be broken into smaller bursts 
						.HI_FREQ	( 1'b0 )						
					)
		wrLenFif(
					.HCLK		( ACLK ),
					.fifo_reset	( sysReset ),

					// Write Port
					.fifoWrite	( wrFifoLenWr ),
					.fifoWrData	( wrLenFifDIn ),

					// Read Port
					.fifoRead	( wrFifoLenRd ),
					.fifoRdData	( wrLenFifDOut ),
					
					// Status bits
					.fifoEmpty	( wrFifoLenEmpty ) ,
					.fifoOneAvail( ),
					.fifoRdValid ( ),
					.fifoFull	( wrFifoLenFull ),
					.fifoNearFull( ),
					.fifoOverRunErr( ),
					.fifoUnderRunErr( ) 
				);
                
/*                
    FifoDualPort #	(	.FIFO_AWIDTH( SLV_AXI4PRT_ADDRDEPTH ),		// depth of holding buffer 2^SLV_AXI4PRT_ADDRDEPTH
						.FIFO_WIDTH	( ID_WIDTH),		// Storing AWID - so burst can be broken into smaller bursts 
						.HI_FREQ	( 1'b0 )						
					)
		wrIdFif(
					.HCLK		( ACLK ),
					.fifo_reset	( sysReset ),

					// Write Port
					.fifoWrite	( wrFifoIdWr ),
					.fifoWrData	( wrIdFifDIn ),

					// Read Port
					.fifoRead	( wrFifoIdRd ),
					.fifoRdData	( wrIdFifDOut ),
					
					// Status bits
					.fifoEmpty	( wrFifoIdEmpty ) ,
					.fifoOneAvail( ), // bbriscoe: not needed, using latAxi3Long instead.
					.fifoRdValid ( ),
					.fifoFull	( wrFifoIdFull ),
					.fifoNearFull( ),
					.fifoOverRunErr( ),
					.fifoUnderRunErr( ) 
				);
*/				
				
		//==========================================================================				
		// Data FIFO to decouple Master from Slave sides. Master writes in an
		// slave reads out - can be operating on different "burst"
		//==========================================================================
		FifoDualPort #(	.FIFO_AWIDTH( SLV_AXI4PRT_DATADEPTH ),
						.FIFO_WIDTH	( (DATA_WIDTH/8)+DATA_WIDTH+1 ),
						.HI_FREQ 	( 1'b0 )
						)
		wrDataFif(
					.HCLK( ACLK ),
					.fifo_reset( sysReset ),

					// Write Port
					.fifoWrite( wrFifoDataWr ),
					.fifoWrData( wrDataFifDIn ),

					// Read Port
					.fifoRead( wrFifoDataRd ),
					.fifoRdData( wrDataFifDOut),
					
					// Status bits
					.fifoEmpty ( wrFifoDataEmpty ) ,
					.fifoOneAvail( ),
					.fifoRdValid ( ),
					.fifoFull( wrFifoDataFull ),
					.fifoNearFull( ),
					.fifoOverRunErr( ),
					.fifoUnderRunErr( )
				   
				);   

	
//========================= AWChan registers ==========================

	reg						latchAWAll;
	
	reg 					loadNumTrans;
	reg 					decrNumTrans;
	reg 					clearNumTrans;
	
	reg [AWLEN_BITS-1:0]	numTrans;
	
	reg [ID_WIDTH-1:0]		latAWID;
	reg [2:0]				latAWSIZE;
	reg [1:0]				latAWBURST;
	reg [1:0]				latAWLOCK;
	reg [3:0]				latAWCACHE;
	reg [2:0]				latAWPROT;
	reg [7:0]				latAWLEN;
	
	wire [3:0]				lastTransLen;		// only used in AXI3 slave
	
	reg						loadAddrW;
	reg						incrAddrW;
	reg	[ADDR_WIDTH-1:0]	currentAddrW;
	
	//Address Write Channel States
	reg [1:0]				IdleAWrite = 2'b00,	AWrite = 2'b01, WaitFifoEmpty = 2'b10;
	reg [1:0]				currStateAWr, nextStateAWr;

  
 reg setFirstTrans;
 reg clearFirstTrans;
 reg firstTrans;
	
//=========================================================================== 

assign SLAVE_AWID 		= 'h0;
assign SLAVE_AWSIZE 	= (SLAVE_TYPE == 2'b01) ? $clog2(DATA_WIDTH/8) : latAWSIZE;
assign SLAVE_AWBURST 	= latAWBURST;
assign SLAVE_AWLOCK 	= latAWLOCK;
assign SLAVE_AWCACHE 	= latAWCACHE;
assign SLAVE_AWPROT 	= latAWPROT;
assign SLAVE_AWADDR 	= currentAddrW;

// bbriscoe: USing latched versions as we've moved FIFO writing to second state (When SLAVE_AWREADY = 1)
assign wrLenFifDIn 		= { latAWID, latAWLEN[7:8-AWLEN_BITS] };    // Save AWLEN to be used to drive out in bursts to slave. 
//assign wrIdFifDIn 		= latAWID;		// Save AWID to be used to drive out in bursts to slave.

assign wrap_nibble = 11'h00f << latAWSIZE;
assign wrap_mask = (lastTransLen << latAWSIZE);

//===========================================================================
// Address recalculation
//===========================================================================
always @(posedge ACLK or posedge sysReset )
	begin
	
		if ( sysReset )
			begin
				currentAddrW <= 0;
			end
		else if (loadAddrW)
			begin
				currentAddrW <= int_slaveAWADDR;
			end
		else if (incrAddrW)
			begin
				//====================================================================		
				// Compute address based on Burst-type and address alginment
				// Fixed =00, Incr=01, Wrap =10 - Wrap not handled as not needed
				// for AXI3 and makes no sense for AXI4Lite (Caches not used here)
				//======================================================================			
				if ( latAWBURST == 2'b00 )			// Fixed type burst
					begin
						currentAddrW	<= currentAddrW;		// all beats use the same address.
					end
				else if (( latAWBURST == 2'b10 ) && (SLAVE_TYPE == 2'b01))
					begin
						if ((currentAddrW[10:0] & wrap_mask) == (wrap_mask & wrap_nibble)) begin
						        currentAddrW <= {currentAddrW[ADDR_WIDTH-1:11], (currentAddrW[10:0] & ~wrap_mask)};
					        end else begin
							currentAddrW <= currentAddrW + (1 << latAWSIZE); // AXI4-Lite burst length is always 1
						end
					end
				else	
					begin
						/// compute bytes sent in burst - handle mis-aligned
						case (latAWSIZE)
							3'd0	: currentAddrW <= currentAddrW + MAX_BEATS;
							3'd1	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:1] + MAX_BEATS, 1'd0 };
							3'd2	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:2] + MAX_BEATS, 2'd0 };
							3'd3	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:3] + MAX_BEATS, 3'd0 };
							3'd4	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:4] + MAX_BEATS, 4'd0 };
							3'd5	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:5] + MAX_BEATS, 5'd0 };
							3'd6	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:6] + MAX_BEATS, 6'd0 };
							3'd7	: currentAddrW <= { currentAddrW[ADDR_WIDTH-1:7] + MAX_BEATS, 7'd0 };
							default :
								currentAddrW <= { ADDR_WIDTH{ 1'bx} };
						endcase
					end
			end
		else 
			begin
				currentAddrW <= currentAddrW;
			end
	end	

	
//========================================================================	
// numTrans indicates how many burst to be done
//========================================================================
always @(posedge ACLK or posedge sysReset)
	begin
		if ( sysReset )
			begin
				numTrans <= 0;
			end
		else if ( clearNumTrans )
			begin
				numTrans <= 0;
			end			
		else if ( loadNumTrans )
			begin
				numTrans <= int_slaveAWLEN[7:8-AWLEN_BITS];
			end
		else if ( decrNumTrans )
			begin
				numTrans <= numTrans - 1'b1;
			end
		else 
			begin
				numTrans <= numTrans;
			end
	end	
	
	
//===========================================================================
// Latch the data for re-transaction 
//===========================================================================
always @(posedge ACLK or posedge sysReset)
	begin
	
		if ( sysReset )
			begin
				latAWID 	<= 0;
				latAWSIZE 	<= 0;
				latAWBURST 	<= 0;
				latAWLOCK 	<= 0;
				latAWCACHE 	<= 0;
				latAWPROT 	 <= 0;
        latAWLEN     <= 0;

			end
		else if ( latchAWAll )
			begin
				latAWID 	<= int_slaveAWID;
				latAWSIZE 	<= int_slaveAWSIZE;
				latAWBURST 	<= int_slaveAWBURST;
				latAWLOCK 	<= int_slaveAWLOCK;
				latAWCACHE 	<= int_slaveAWCACHE;
				latAWPROT 	<= int_slaveAWPROT;
        latAWLEN <= int_slaveAWLEN;

			end
	
	end	

assign lastTransLen = latAWLEN[3:0]; // bbriscoe: Only need bottom 4 bits for last tx, all others will be 16
		
//==============================================================================
// Address Write channel from AXI4 port (XBAR) State Machine	
//==============================================================================
 always @(posedge ACLK or posedge sysReset )
	begin
		if ( sysReset )
			begin
				currStateAWr <= IdleAWrite;
        firstTrans <= 0;
			end
		else
			begin
      
				currStateAWr <= nextStateAWr;
        
        if(setFirstTrans) firstTrans <= 1;
        if(clearFirstTrans) firstTrans <= 0;
 
			end
			
	end
 

 
 always @(*)
	begin
		int_slaveAWREADY <= 0;
//		wrFifoIdWr 		 <= 0;
		wrFifoLenWr		 <= 0;
		latchAWAll 		 <= 0;
		loadAddrW 		 <= 0;
		loadNumTrans 	 <= 0;
		clearNumTrans 	 <= 0;
		incrAddrW 		 <= 0;
		decrNumTrans 	 <= 0;
		SLAVE_AWLEN[3:0] <= 0;		// only used in AXI3 - AXILite does not use SLAVE_AWLEN
		SLAVE_AWVALID 	 <= 0;
		
    setFirstTrans <= 0;
    clearFirstTrans <= 0;
    
		nextStateAWr	<= currStateAWr;
		
		case( currStateAWr )
			IdleAWrite:
				begin
					if (int_slaveAWVALID)
						begin

							if (!wrFifoLenFull) 
                                                                    // we take the more pessimistic Full flag to control whether we 
                                                                    // will take another entry into our ID and LEN FIFOs.
								begin
									int_slaveAWREADY	<= 1'b1;
									loadAddrW 			<= 1'b1;
									latchAWAll 			<= 1'b1;
									loadNumTrans 		<= 1'b1;			
									// wrFifoIdWr 			<= 1'b1;

									nextStateAWr 		<= AWrite;
                  setFirstTrans <= 1; // bbriscoe: setting for the first transaction
								end
						end
				end
			AWrite:
				begin
          if (SLAVE_AWREADY & firstTrans)
            begin
  //            wrFifoIdWr 			<= 1'b1; // bbriscoe: Delaying writing to the FIFO until SLAVE_WREADY is asserted.
              wrFifoLenWr 		<= 1'b1; // bbriscoe: Delaying writing to the FIFO until SLAVE_WREADY is asserted.
              clearFirstTrans <= 1; // bbriscoe: cleared after writing the to the fifo
            end
					if ( numTrans == 0 )	//last transfer in the burst
						begin
							SLAVE_AWLEN[3:0]	<= lastTransLen;	// only used in AXI3 - AXILite does not use SLAVE_AWLEN
							SLAVE_AWVALID 		<= 1'b1;

							if (SLAVE_AWREADY)
								begin
									clearNumTrans 	<= 1'b1;

                        nextStateAWr <= IdleAWrite;
								end
          end
					else //Not the last transfer burst
						begin
							SLAVE_AWLEN[3:0] 	<= 4'b1111; 		// only used in AXI3 - AXILite does not use SLAVE_AWLEN
							SLAVE_AWVALID 		<= 1'b1;
						
							if (SLAVE_AWREADY)
								begin
									incrAddrW 		<= 1'b1;
									decrNumTrans 	<= 1'b1;			
								end
						end
				end
                
        WaitFifoEmpty:      // jhayes : Waiting in this state for Len FIFO to empty in the case of large AXI3 transactions.
        begin
          if(wrFifoLenEmpty)
            begin
              nextStateAWr <= IdleAWrite;
            end
        end
			default:
				begin		
					int_slaveAWREADY <= 1'bx;
//					wrFifoIdWr 		 <= 1'bx;
					wrFifoLenWr		 <= 1'bx;
					latchAWAll 		 <= 1'bx;
					loadAddrW 		 <= 1'bx;
					loadNumTrans 	 <= 1'bx;
					clearNumTrans 	 <= 1'bx;
					incrAddrW 		 <= 1'bx;
					decrNumTrans 	 <= 1'bx;
					SLAVE_AWLEN[3:0] <= 4'bxxxx;		// only used in AXI3 - AXILite does not use SLAVE_AWLEN
					SLAVE_AWVALID 	 <= 1'bx;
				
					nextStateAWr <= 2'bxx;	
				end
				
		endcase
		
	end

	
//============================ WChan registers ====================================	
// Write Data Channel Get data from master States
//=================================================================================

	reg [0:0]				WGetData = 1'b0;
	reg [0:0]				currStateWrGD, nextStateWrGD;
	

//==================== ============================ ========================
assign wrDataFifDIn = {int_slaveWSTRB, int_slaveWDATA, int_slaveWLAST};  //Write Data stored in wrDataFifo


//=================================================================================
// Data Write channel State Machine (store data from master)
//=================================================================================
always @(posedge ACLK or posedge sysReset )
	begin
	
		if ( sysReset )
			begin
				currStateWrGD <= WGetData;
			end
		else
			begin
				currStateWrGD <= nextStateWrGD;
			end
	end
 
 
 always @(*)
	begin
		int_slaveWREADY <= 1'b0;
		wrFifoDataWr 	<= 1'b0;
		
		nextStateWrGD	<= currStateWrGD;
		
		case( currStateWrGD )
			WGetData:
				begin
					if ( int_slaveWVALID )
						begin
							if ( !wrFifoDataFull )
								begin
									wrFifoDataWr 	<= 1'b1;
									int_slaveWREADY <= 1'b1;
								end
						end
				end
			default:
				begin
					wrFifoDataWr 	<= 1'bx;
					int_slaveWREADY <= 1'bx;
					
					nextStateWrGD 	<= 1'bx;	
				end
				
		endcase
		
	end
	
//============================ WChan registers ====================================	
//Write Data Channel Send data to slave States
//=================================================================================
reg [1:0]				WSendData = 2'b00;
reg [1:0]				WWaitEndBurst = 2'b01;
reg [1:0]				WWaitRestartData = 2'b10;
reg [1:0]				currStateWrSD, nextStateWrSD;
	
//WChan registers
reg 					incrCountWrData;
reg 					setCountWrData;
reg [3:0]				countWrData;	
	
wire					W_last;

//=================================================================================

// assign W_last = ( SLAVE_TYPE == 2'b11 ) ? wrDataFifDOut[0] : 1'b1;		// For AXILite 1- beat so always W_last - to help trim logic for AXI4Lite
assign W_last = wrDataFifDOut[0];
 
assign SLAVE_WSTRB 	= wrDataFifDOut[(DATA_WIDTH/8)+DATA_WIDTH:DATA_WIDTH+1];
assign SLAVE_WDATA 	= wrDataFifDOut[DATA_WIDTH:1];
assign SLAVE_WID 	= 0;  								//bits for ID


//=================================================================================
// Counter to assert slave WLAST at correct time
//=================================================================================
always @(posedge ACLK or posedge sysReset )
	begin
		if ( sysReset )
			begin
				countWrData <= 4'b0000;
			end
		else if ( setCountWrData )
			begin
				countWrData <= 4'b0000;
			end
		else if (incrCountWrData)
			begin
				countWrData <= countWrData + 1'b1;
			end
		else 
			begin
				countWrData <= countWrData;
			end
	end	

	
//=================================================================================
// Data Write channel State Machine (send data to slave)
//=================================================================================
always @(posedge ACLK or posedge sysReset )
	begin
		if ( sysReset )
			begin
				currStateWrSD <= WSendData;
			end
		else
			begin
				currStateWrSD <= nextStateWrSD;
			end
			
	end
 
 
 always @(*)
	begin

		SLAVE_WLAST 	<= 0;
		SLAVE_WVALID 	<= 0;
		wrFifoDataRd 	<= 0;
//		wrFifoIdRd  	<= 0;
		setCountWrData 	<= 0;
		incrCountWrData <= 0;
		
		nextStateWrSD 	<= currStateWrSD;
		
		case( currStateWrSD )
			WSendData:
				begin
					if ( !wrFifoDataEmpty) // & !wrFifoIdEmpty ) // bbriscoe: extra control added, !wrFifoIdEmpty, to make sure that data does not pass out command
          
						begin
							if ( ( countWrData == ( MAX_BEATS -1'b1 )  ) | W_last )  // each last beat transfer or last transfer in the burst
								begin
									SLAVE_WLAST <=1'b1;
								end

								SLAVE_WVALID <=1'b1;
					
							if ( SLAVE_WREADY )
								begin
									wrFifoDataRd <= 1'b1;

									if ( W_last ) // last transfer in the burst
										begin
											setCountWrData <= 1'b1;
								//			wrFifoIdRd     <= 1'b1;

										end
									else //Not the last transfer in the burst
										begin
											incrCountWrData <= 1'b1;
										end
							
								end
						end
				end

			default:
				begin
					SLAVE_WLAST 	<= 1'bx;
					SLAVE_WVALID 	<= 1'bx;
					wrFifoDataRd 	<= 1'bx;
					setCountWrData 	<= 1'bx;
					incrCountWrData <= 1'bx;
				
					nextStateWrSD 	<= 2'bxx;	
				end
				
		endcase
		
	end
	

	
//============================ Response channel registers =============================
// Response Channel States
//=====================================================================================
reg [0:0]				Idle_WrResp = 1'b0,	SendWrResp	= 1'b1;
reg [0:0]				currStateResp, nextStateResp;
	
// RespChan registers
reg 					setResponseCombi; //combined response value
reg						clearResponseCombi;
reg [1:0] 				responseCombi;
	
reg [AWLEN_BITS-1:0]	countResp;
reg						resetCountResp;
reg						incrCountResp;

wire [ID_WIDTH-1:0] 		latBID_sel;	
reg [ID_WIDTH-1:0] 		latBID;
reg						setBID;

//=================================================================================
	
always @(posedge ACLK or posedge sysReset )
	begin
	
		if ( sysReset )
			begin
				responseCombi <= 0;
			end
		else if ( clearResponseCombi )
			begin
				responseCombi <= 0;
			end			
		else if ( setResponseCombi )
			begin
				responseCombi <= SLAVE_BRESP;
			end
	end


//==================================================================================================	
// Responses counter (How many responses to combine from slave before sending response to master)
//==================================================================================================
always @(posedge ACLK or posedge sysReset )
	begin
	
		if ( sysReset )
			begin
				countResp <= 0;
			end
		else if ( resetCountResp )
			begin
				countResp <= 0;
			end
		else if ( incrCountResp )
			begin
				countResp <= countResp + 1'b1;
			end
		else
			begin
				countResp <= countResp;
			end
	end
         assign latBID_sel = wrLenFifDOut[ID_WIDTH+AWLEN_BITS-1:AWLEN_BITS]; // jhayes : Fix to do with SAR77217, ensuring that an AXI4 Lite transaction will have a BID field when converting back to AXI4.
	
always @(posedge ACLK or posedge sysReset )
	begin
		if ( sysReset )
			begin
				latBID <= 0;
			end
		else if ( setBID )
			begin
            latBID <= latBID_sel;
			end
		else
			begin
				latBID <= latBID;
			end
	end

	
//=================================================================================
// Response channel State Machine
//=================================================================================
always @(posedge ACLK or posedge sysReset )
	begin
		if ( sysReset )
			begin
				currStateResp <= Idle_WrResp;
			end
		else
			begin
				currStateResp <= nextStateResp;
			end
	end
 
 assign int_slaveBID 	= latBID;
 assign int_slaveBUSER 	= 0;
 assign int_slaveBRESP 	= responseCombi;

 
 always @(*)
	begin		
		wrFifoLenRd	<= 0;
		setBID 		<= 0;
		setResponseCombi 	<= 0;
		incrCountResp 		<= 0;
		resetCountResp 		<= 0;
		int_slaveBVALID 	<= 0;
		clearResponseCombi 	<= 0;
		SLAVE_BREADY 		<= 1'b0;
		
		nextStateResp 		<= currStateResp;
	
		case( currStateResp )
			Idle_WrResp:
				begin
					if (!wrFifoLenEmpty)
						begin
							SLAVE_BREADY <= 1'b1;
							
							if ( SLAVE_BVALID )
								begin
									setBID <= 1'b1;
									
									if ( SLAVE_BRESP != 2'b00 )
										begin
											if ( responseCombi == 2'b00 )
												begin
													setResponseCombi <= 1'b1;
												end
										end
										
									if ( countResp == wrLenFifDOut[AWLEN_BITS-1:0] )
										begin
											nextStateResp <= SendWrResp;
										end
									else
										begin
											incrCountResp <= 1'b1;
										end
								end
						end
				end
			SendWrResp:
				begin
					int_slaveBVALID <= 1'b1;
					
					if ( int_slaveBREADY ) // from master-side
						begin
							wrFifoLenRd 		<= 1'b1;
							clearResponseCombi 	<= 1'b1;
							resetCountResp 		<= 1'b1;
							nextStateResp 		<= Idle_WrResp;
						end
				end
			default:
				begin
					nextStateResp <= 1'bx;	
					
					wrFifoLenRd	<= 1'bx;
					setBID 		<= 1'bx;
					setResponseCombi 	<= 1'bx;
					incrCountResp 		<= 1'bx;
					resetCountResp 		<= 1'bx;
					int_slaveBVALID 	<= 1'bx;
					clearResponseCombi 	<= 1'bx;
				end
				
		endcase
		
	end
	
endmodule		// SlvAxi4ProtConvWrite.v
