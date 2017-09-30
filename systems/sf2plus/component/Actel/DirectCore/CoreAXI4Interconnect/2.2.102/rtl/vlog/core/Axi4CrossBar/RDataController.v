`timescale 1ns / 1ns


// *******************************************************************************/
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
// File			: RDataController.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module controls which slave gets its data selected to be sent to
//				target master. It arbitrates between slave requestors and muxes
//				slave data signals to target master based on SLAVE_ID.
//	                                                               
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/07/14		OB			1.0			Initial release version
// 26/02/15		JH			1.1			Add HI_FREQ parameter to allow higher freq of operation 
//										to be traded off for extra latency.                    
//
//
// SVN Revision Information:
// SVN $Revision: 4805 $
// SVN $Date: 2014-07-21 17:48:48 +0530 (Mon, 21 Jul 2014) $
//
// Resolved SARs
// SAR      Date     Who   Description
//
// Notes: 
//
// ********************************************************************/
// synopsys translate_off
//`include "../include/Timescale.h"
// synopsys translate_on

module RDataController # 
	(
		parameter integer NUM_MASTERS			= 2, 				// defines number of masters
		parameter integer NUM_MASTERS_WIDTH		= 1, 				// defines number of bits to encode master number
		
		parameter integer NUM_SLAVES     		= 2, 				// defines number of slaves
		parameter integer NUM_SLAVES_WIDTH 		= 1,				// defines number of bits to encoode slave number

		parameter integer ID_WIDTH   			= 1, 
		parameter integer DATA_WIDTH 			= 32,

		parameter integer SUPPORT_USER_SIGNALS 	= 0,
		parameter integer USER_WIDTH 			= 1,

		parameter integer CROSSBAR_MODE			= 1,				// defines whether non-blocking (ie set 1) or shared access data path
		parameter integer OPEN_RDTRANS_MAX		= 2,

		parameter [NUM_MASTERS*NUM_SLAVES-1:0] 		MASTER_READ_CONNECTIVITY 		= {NUM_MASTERS*NUM_SLAVES{1'b1}},

		parameter	HI_FREQ						= 0, 				// used to add registers to allow a higher freq of operation at cost of latency
		parameter	RD_ARB_EN 					= 1					// select arb or ordered rdata
	
   
	)
	(
		// Global Signals
		input  wire                                                    	sysClk,
		input  wire                                                    	sysReset,			// active high reset synchronoise to RE sysClk - asserted async.
   
		//====================== Slave Data Ports  ================================================//
  		input  wire [NUM_SLAVES*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		SLAVE_ID,
		input  wire [NUM_SLAVES*DATA_WIDTH-1:0]    						SLAVE_DATA,
		input  wire [NUM_SLAVES*2-1:0]                         			SLAVE_RESP,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_LAST,
		input  wire [NUM_SLAVES*USER_WIDTH-1:0]         				SLAVE_USER,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_VALID,
		
		output wire [NUM_SLAVES-1:0]                           			SLAVE_READY,
		
		//====================== Master Data  Ports  ================================================//
		output wire [NUM_MASTERS*ID_WIDTH-1:0]          				MASTER_ID,
		output wire [NUM_MASTERS*DATA_WIDTH-1:0]     					MASTER_DATA,
		output wire [NUM_MASTERS*2-1:0]                          		MASTER_RESP,
		output wire [NUM_MASTERS-1:0]                            		MASTER_LAST,
		output wire [NUM_MASTERS*USER_WIDTH-1:0]          				MASTER_USER,
		output wire [NUM_MASTERS-1:0]                            		MASTER_VALID,

		input  wire [NUM_MASTERS-1:0]                            		MASTER_READY,
   
		//====================== DataControl Port ============================================//
		
		output wire	[NUM_MASTERS*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		currDataTransID,	// current data transaction ID
		output wire	[NUM_MASTERS-1:0]  									openTransDec,		// indicates thread matching currDataTransID to be decremented

		//======================= Read Address Controller Port======================================//
		input wire														rdDataFifoWr,
		input wire	[(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 					rdSrcPort,
		input wire	[NUM_SLAVES_WIDTH-1:0]								rdDestPort,
		output wire [1+NUM_MASTERS-1:0]									rdFifoFull	
		
	);
   						 
						 
//================================================================================================
// Local Parameters
//================================================================================================

	localparam MASTERID_WIDTH		= ( NUM_MASTERS_WIDTH + ID_WIDTH );			// defines width masterID - includes infrastructure ID plus ID
	localparam THREAD_VEC_WIDTH		= ( MASTERID_WIDTH + NUM_SLAVES_WIDTH );	// defines width of per thread vector elements width

	wire	 [NUM_MASTERS-1:0]		rdFifoActFull;								// internal probe signal
	wire	 [NUM_MASTERS-1:0]		rdFifoEmpty;								// internal probe signal
	
	//=======================================================================================================================
	// ReadDataController arbitrates between Slaves requestors (RVALID),  drivers to selected targeted Master based SLAVE_RID
	// and "pops" open transaction with currDataTransID when openTransDec at end of transaction.
	//=======================================================================================================================     
 	genvar i;
	generate
	if (CROSSBAR_MODE == 1)			// implement full non-blocking data path for read data
		begin : MD
		
			// Local parameters
			wire [MASTERID_WIDTH-1:0]	masterID		[NUM_MASTERS -1:0];					
			wire [NUM_SLAVES-1:0]		slaveReady		[NUM_MASTERS -1:0];			// temp store of vectors from each master read controller
			reg [NUM_SLAVES-1:0]		SLAVE_READYVec	[NUM_MASTERS -1:0];			// temp store of vectors from each master read controller

			//==========================================================================
			// Declare a ReadDataController for each Master port
			//==========================================================================
			for (i=0; i< NUM_MASTERS; i=i+1 )
				begin
				
					ReadDataController # 
						(
							.MASTER_NUM					( i	),					// Port number
							.NUM_MASTERS				( NUM_MASTERS ), 				// defines number of masters
							.NUM_MASTERS_WIDTH			( NUM_MASTERS_WIDTH ), 			// defines number of bits to encode master number
							.NUM_SLAVES     			( NUM_SLAVES ), 				// defines number of slaves
							.NUM_SLAVES_WIDTH 			( NUM_SLAVES_WIDTH ),			// defines number of bits to encoode slave number
							.ID_WIDTH   				( ID_WIDTH ), 
							.DATA_WIDTH 				( DATA_WIDTH ),
							.SUPPORT_USER_SIGNALS 		( SUPPORT_USER_SIGNALS ),
							.USER_WIDTH 				( USER_WIDTH ),
							.CROSSBAR_MODE				( CROSSBAR_MODE ),
							.OPEN_RDTRANS_MAX			( OPEN_RDTRANS_MAX ),							
							.MASTER_READ_CONNECTIVITY 	( MASTER_READ_CONNECTIVITY[((i+1)*NUM_SLAVES)-1:i*NUM_SLAVES] ),   // which slaves can be read from this master
							.HI_FREQ					( HI_FREQ ),
							.RD_ARB_EN					( RD_ARB_EN )							
							)
					rdcon	(
								// Global Signals
								.sysClk ( sysClk ),
								.sysReset( sysReset ),			// active high reset synchronoise to RE sysClk - asserted async.

								// Slave Data Ports  
								.SLAVE_VALID	( SLAVE_VALID ),
								.SLAVE_ID		( SLAVE_ID ),
								.SLAVE_DATA		( SLAVE_DATA ),
								.SLAVE_RESP		( SLAVE_RESP ),
								.SLAVE_LAST		( SLAVE_LAST ),
								.SLAVE_USER		( SLAVE_USER ),
								.SLAVE_READY	( slaveReady[i] ),

								// Master Data  Port  
								.masterID		( masterID[i] ),
								.MASTER_DATA	( MASTER_DATA[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] ),
								.MASTER_RESP	( MASTER_RESP[(i+1)*2-1:i*2] ),
								.MASTER_LAST	( MASTER_LAST[i] ),
								.MASTER_USER	( MASTER_USER[(i+1)*USER_WIDTH-1:i*USER_WIDTH] ),
								.MASTER_VALID	( MASTER_VALID[i] ),
								.MASTER_READY	( MASTER_READY[i] ),
      
								// Data Controller  
								.currDataTransID( currDataTransID[(i+1)*MASTERID_WIDTH-1:i*MASTERID_WIDTH] ),	// indicates transaction to be decremented 
								.openTransDec( openTransDec[i] ),			// indicates ID of transaction to be decremented

								// Address Controller
								.rdDataFifoWr( rdDataFifoWr ),
								.rdSrcPort( rdSrcPort ),
								.rdDestPort( rdDestPort ),
								.rdFifoEmpty( rdFifoEmpty[i] ),
								.rdFifoActFull( rdFifoActFull[i] ),
								.rdFifoFull( rdFifoFull[i] ) 			// indicates to address control to "stop" address transactions
																		// DERR_SLAVE never full!
							)/* synthesis syn_hier = "flatten,remove" */;
							
					// Drop Infrastructure component from ID 
					assign MASTER_ID[(i+1)*ID_WIDTH-1:i*ID_WIDTH] = masterID[i][MASTERID_WIDTH-NUM_MASTERS_WIDTH-1:0];


					
					
					//====================================================================================================
					// "OR" all slaveReadys - each vector should have only 1 bit set
					//====================================================================================================
					always @(*)
						begin
							if (i == 0)
								SLAVE_READYVec[0] <= slaveReady[0];
							else
								// OR all slaveReady vectors to allow each "active" master to pass its ready.
								SLAVE_READYVec[i] <= slaveReady[i] | SLAVE_READYVec[i-1];
						end
					
				end
       
        // always assign rdFifoFull for DERR_SLAVE    bbriscoe: moved this to outside the 'for' loop.
        assign rdFifoFull[NUM_MASTERS] = 0;
        
				assign SLAVE_READY = SLAVE_READYVec[NUM_MASTERS-1];
				
		end
	else
		begin : SD			// implement shared read datapath - only one read mux path

			// Declare local paramaters for shared-mode
			wire [NUM_SLAVES-1:0]			slaveReady;
			
			wire [MASTERID_WIDTH-1:0]		masterID;
			wire [DATA_WIDTH-1:0]     		masterDATA;
			wire [1:0]	                    masterRESP;
			wire 				          	masterLAST;
			wire [USER_WIDTH-1:0]           masterUSER;

			reg	[NUM_MASTERS-1:0]  			currTransDec;
			
			wire [(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		dataTransID;	// current data transaction ID
			wire											transDec;
			wire											rdFifoFulltmp, rdFifoActFulltmp, rdFifoEmptytmp;
			
			wire 				              	masterVALID;
			reg									masterREADY;

			reg [NUM_MASTERS_WIDTH-1:0]			targetMaster, targetMasterQ1;
			reg	[NUM_MASTERS-1:0] 				aMASTER_VALID;
			

	
			ReadDataController # 
				(
					.MASTER_NUM					( {NUM_MASTERS_WIDTH{1'b0} }  ),// Port number - not used in Shared Data mode
					.NUM_MASTERS				( NUM_MASTERS ), 				// defines number of masters
					.NUM_MASTERS_WIDTH			( NUM_MASTERS_WIDTH ), 			// defines number of bits to encode master number
					.NUM_SLAVES     			( NUM_SLAVES ), 				// defines number of slaves
					.NUM_SLAVES_WIDTH 			( NUM_SLAVES_WIDTH ),			// defines number of bits to encoode slave number
					.ID_WIDTH   				( ID_WIDTH ), 
					.DATA_WIDTH 				( DATA_WIDTH ),
					.SUPPORT_USER_SIGNALS 		( SUPPORT_USER_SIGNALS ),
					.USER_WIDTH 				( USER_WIDTH ),
					.CROSSBAR_MODE				( CROSSBAR_MODE ),
					.OPEN_RDTRANS_MAX			( OPEN_RDTRANS_MAX ),							
					.MASTER_READ_CONNECTIVITY 	( {NUM_MASTERS*NUM_SLAVES{1'b1} } ),   // no pruning as one common path
					.HI_FREQ					( HI_FREQ ),
					.RD_ARB_EN					( RD_ARB_EN )							
				)
			rdcon	(
					// Global Signals
					.sysClk ( sysClk ),
					.sysReset( sysReset ),			// active high reset synchronoise to RE sysClk - asserted async.
								
					// Slave Data Ports  
					.SLAVE_VALID	( SLAVE_VALID ),
					.SLAVE_ID		( SLAVE_ID ),
					.SLAVE_DATA		( SLAVE_DATA ),
					.SLAVE_RESP		( SLAVE_RESP ),
					.SLAVE_LAST		( SLAVE_LAST ),
					.SLAVE_USER		( SLAVE_USER ),
					.SLAVE_READY	( slaveReady ),

					// Master Data  Port  
					.masterID		( masterID ),
					.MASTER_DATA	( masterDATA ),
					.MASTER_RESP	( masterRESP ),
					.MASTER_LAST	( masterLAST ),
					.MASTER_USER	( masterUSER ),
					.MASTER_VALID	( masterVALID ),
					.MASTER_READY	( masterREADY ),
      
					// Data Controller  
					.currDataTransID( dataTransID ),	// indicates transaction to be decremented 
					.openTransDec( transDec ),			// indicates ID of transaction to be decremented

					// Address Controller
					.rdDataFifoWr( rdDataFifoWr ),
					.rdSrcPort( rdSrcPort ),
					.rdDestPort( rdDestPort ),
					.rdFifoEmpty( rdFifoEmptytmp ),
					.rdFifoActFull( rdFifoActFulltmp ),
					.rdFifoFull( rdFifoFulltmp ) 			// indicates to address control to "stop" address transactions
														// DERR_SLAVE never full!
					)  /* synthesis syn_hier = "flatten,remove" */;


			// Masters have requests stopped when full - stop for any master as common data-path
			assign rdFifoFull = { 1'b0, { NUM_MASTERS{ rdFifoFulltmp } }   };		// MSD is for DERR_SLAVE - never stopped

			assign rdFifoActFull = { NUM_MASTERS{ rdFifoActFulltmp } };
			assign rdFifoEmpty = { NUM_MASTERS{ rdFifoEmptytmp } };
			
			//=============================================================================
			// Route all "common" signals to all master interfaces
			//=============================================================================
			for (i=0; i< NUM_MASTERS; i=i+1 )
				begin
					assign MASTER_ID[  (i+1)*ID_WIDTH-1  :i*ID_WIDTH]		= masterID[MASTERID_WIDTH-NUM_MASTERS_WIDTH-1:0];	// Strip off infrastructure ID
					assign MASTER_DATA[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] 	= masterDATA;
					assign MASTER_RESP[(i+1)*2-1   		 :i*2]				= masterRESP;
					assign MASTER_LAST[(i+1)*1-1		 :i*1]				= masterLAST;
					assign MASTER_USER[(i+1)*USER_WIDTH-1:i*USER_WIDTH] 	= masterUSER;
				end

			//================================================================================
			// Mux VALID and Reads based on Master target port for read
			//================================================================================
			always @(*)
				begin
	
					aMASTER_VALID 	<= 0;		// initialise to 0 to indicate no transaction
					
					targetMaster <= masterID[MASTERID_WIDTH-1:ID_WIDTH];	// pick out target master from RID
					
					aMASTER_VALID[ targetMaster ]	<= masterVALID;
					masterREADY 					<= MASTER_READY[targetMaster];  

					currTransDec					<= 0;
					currTransDec[ targetMasterQ1 ] 	<= transDec;

				end

			//======================================================================
			// Pass transDec back to approbriate master - needs to be clocked
			// as targetMaster changes before transDec asserted.
			//======================================================================
			always @(posedge sysClk)
				begin
					targetMasterQ1	<= targetMaster;
				end
				
			// Data Controller  signals routed to all ports
			assign currDataTransID	=  { NUM_MASTERS{ dataTransID } };
			assign openTransDec		= currTransDec;
			
			assign MASTER_VALID = aMASTER_VALID;		
			assign SLAVE_READY  = slaveReady;	
				
		end
			
	endgenerate

	
endmodule // RDataController.v
