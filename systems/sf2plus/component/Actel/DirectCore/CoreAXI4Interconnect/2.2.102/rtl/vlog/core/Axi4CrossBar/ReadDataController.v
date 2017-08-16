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
// File			: ReadDataController.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module controls which slave gets its read data selected to be sent to
//				this target master. It arbitrates between slave requestors and muxes
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

module ReadDataController # 
	(
		parameter [2:0] MASTER_NUM				= 3'b0,				// port number
				
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
		
		parameter [NUM_SLAVES-1:0]		MASTER_READ_CONNECTIVITY 		= {NUM_SLAVES{1'b1}},
		
		parameter  HI_FREQ	= 1,										// used to add registers to allow a higher freq of operation at cost of latency
	
		parameter	RD_ARB_EN = 1										// select arb or ordered rdata
   
	)
	(
		// Global Signals
		input  wire                                                    	sysClk,
		input  wire                                                    	sysReset,			// active high reset synchronoise to RE AClk - asserted async.
   
		//====================== Slave Data Ports  ================================================//
  
		input  wire [NUM_SLAVES*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		SLAVE_ID,
		input  wire [NUM_SLAVES*DATA_WIDTH-1:0]    						SLAVE_DATA,
		input  wire [NUM_SLAVES*2-1:0]                         			SLAVE_RESP,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_LAST,
		input  wire [NUM_SLAVES*USER_WIDTH-1:0]         				SLAVE_USER,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_VALID,
		
		output wire [NUM_SLAVES-1:0]                           			SLAVE_READY,		// output will have only 1 bit asserted for slave active
		
		//====================== Master Data  Ports  ================================================//
		
		output wire [ NUM_MASTERS_WIDTH + ID_WIDTH-1:0]  	   			masterID,
		output wire [DATA_WIDTH-1:0]     								MASTER_DATA,
		output wire [1:0]                          						MASTER_RESP,
		output wire                             						MASTER_LAST,
		output wire [USER_WIDTH-1:0]          							MASTER_USER,
		output wire          		                  					MASTER_VALID,

		input  wire			                           					MASTER_READY,
   
		//====================== DataControl Port ============================================//
		
		output wire	[(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 					currDataTransID,	// current data transaction ID
		output wire					  									openTransDec,		// indicates thread matching currDataTransID to be decremented

		//======================= Read Address Controller Port======================================//
		input wire														rdDataFifoWr,
		input wire	[(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 					rdSrcPort,
		input wire	[NUM_SLAVES_WIDTH-1:0]								rdDestPort,
		output wire 													rdFifoFull,	
		output wire														rdFifoActFull,
		output wire														rdFifoEmpty
		
	);
   						 

//================================================================================================
// Local Parameters
//================================================================================================

	localparam MASTERID_WIDTH		= ( NUM_MASTERS_WIDTH + ID_WIDTH );			// defines width masterID - includes infrastructure ID plus ID
	localparam THREAD_VEC_WIDTH		= ( MASTERID_WIDTH + NUM_SLAVES_WIDTH );	// defines width of per thread vector elements width

	
//=================================================================================================
// Local Declarationes
//=================================================================================================

	wire [NUM_SLAVES_WIDTH-1:0]					requestorSelEnc;
	
	wire										requestorSelValid;
	wire										arbEnable;
	wire [NUM_SLAVES-1:0]                       slaveValidQual;
	
	wire										rdFifoValid;
	

	generate 
		if ( RD_ARB_EN )		// arb between slave_RVALIDs - use when highly variable READ DATA paths
			begin : rdArb
		
				wire [NUM_SLAVES-1:0]						requestorSel;
		
				assign rdFifoFull	= 0;		// not used - so tie to 0 to ensure does not stop read addresses
				assign rdFifoActFull= 0;		// not used - so tie to 0 for testbench probes
				assign rdFifoEmpty	= 1;		// not used - so tie to 1 - for testbench
				
				
				//===========================================================================================================
				// RequestQual - only asserted bits in slaveValidQual for ports what are requesting access to master that
				// matches this ReadDataController instance.
				//============================================================================================================	
				RequestQual #	(
									.NUM_SLAVES 			( NUM_SLAVES ),
									.NUM_MASTERS_WIDTH		( NUM_MASTERS_WIDTH ), 	
									.ID_WIDTH   			( ID_WIDTH ),
									.CROSSBAR_MODE			( CROSSBAR_MODE )
								)
						reqQual(
									.SLAVE_VALID		( SLAVE_VALID ),
									.MASTER_NUM			( MASTER_NUM ),
									.SLAVE_ID			( SLAVE_ID ),
									.READ_CONNECTIVITY	( MASTER_READ_CONNECTIVITY ),
									.slaveValidQual		( slaveValidQual )
								) /* synthesis syn_hier = "remove" */;
								
								
				//===========================================================================================================
				// Slot Aribrator - performs a round-robin arbitration among valid requestors for ownership
				// of data bus.
				//============================================================================================================
				RoundRobinArb #( .N( NUM_SLAVES ), .N_WIDTH( NUM_SLAVES_WIDTH ), .HI_FREQ ( HI_FREQ )     )
							rrArb 	(
										// global signals
										.sysClk		( sysClk ),
										.sysReset	( sysReset ),

										.requestor		( slaveValidQual ),
										.arbEnable		( arbEnable ),				// arb again when selected master asserts increment (only 1 will)						
										.grant			( requestorSel 	 ),			// bit per master - 1-bit should only be set
										.grantEnc		( requestorSelEnc 	 ),		// encoded version of requestorSel
										.grantValid		( requestorSelValid )		// asserted when grant is valid
							
									) /* synthesis syn_hier = "remove" */;
									
			end	
		else		// use a FIFO to determine order slaves will be serviced
			begin : rdFif
	
					wire 						rdAddrMasterWr;
			
					wire [NUM_SLAVES_WIDTH-1:0]	rdfifoRdData;
	
					wire rdFifoEmptyQ1;
					wire rdFifoOverRunErr;
					wire rdFifoUnderRunErr;
		
					reg	slaveValidQualQ1;

					
					// Pick out Infrastructure ID from srcPort to determine which master this read is for - in not crossbar mode
					// all AR writes written into fifo as shared datapath
					assign rdAddrMasterWr = rdDataFifoWr & ( CROSSBAR_MODE	? ( rdSrcPort[MASTERID_WIDTH-1 : ID_WIDTH]  == MASTER_NUM )
																			: 1'b1    );	

					//===========================================================================================================
					// RequestQual - only asserted bits in slaveValidQual for ports that are requesting access to master that
					// matches this ReadDataController instance.
					//============================================================================================================	
					RequestQual #	(
										.NUM_SLAVES 			( NUM_SLAVES ),
										.NUM_MASTERS_WIDTH		( NUM_MASTERS_WIDTH ), 	
										.ID_WIDTH   			( ID_WIDTH ),
										.CROSSBAR_MODE			( CROSSBAR_MODE )
									)
						reqQual(
										.SLAVE_VALID		( SLAVE_VALID ),
										.MASTER_NUM			( MASTER_NUM ),
										.SLAVE_ID			( SLAVE_ID ),
										.READ_CONNECTIVITY	( MASTER_READ_CONNECTIVITY ),
										.slaveValidQual		( slaveValidQual )
								);					
								

					//====================================================================================================
					// FIFO to hold open read transactions - pushed on Address read cycle and popped on read data
					// cycle.
					//=====================================================================================================
					RdFifoDualPort #(	.HI_FREQ( HI_FREQ ),
										.FIFO_AWIDTH( OPEN_RDTRANS_MAX ),
										.FIFO_WIDTH( NUM_SLAVES_WIDTH ),
										.NEAR_FULL ( 'd2 ),
										.NUM_SLAVES( NUM_SLAVES )
									)
						rdFif	(
										.HCLK(	sysClk ),
										.fifo_reset( sysReset ),
					
										// Write Port
										.fifoWrite( rdAddrMasterWr ),
										.fifoWrData( rdDestPort ),				// slave read from

										// Read Port
										.fifoRead( arbEnable ),
										.fifoRdData( rdfifoRdData ),
										.slaveValidQual( slaveValidQual ),
										.requestorSelValid( requestorSelValid ),
					
										// Status bits
										.fifoEmpty ( rdFifoEmpty ) ,
										.fifoOneAvail(  ),
										.fifoRdValid ( rdFifoValid ),
										.fifoFull( rdFifoActFull  ),
										.fifoNearFull( rdFifoFull ),				// use 1 from full to allow cover race between "full" and arb
										.fifoOverRunErr( rdFifoOverRunErr ),
										.fifoUnderRunErr( rdFifoUnderRunErr )
								);
 
					
					//assign requestorSelValid = !rdFifoEmpty & rdFifoValid & slaveValidQual[rdfifoRdData];
					assign requestorSelEnc 	 = rdfifoRdData;

   							
			end

	endgenerate
	

	
	//===========================================================================================================
	// Slave Data Mux and Control - performs the MUX of slave requestor data vector to master and
	// controls response from master. 
	//============================================================================================================
	
	ReadDataMux # 
		(
			.NUM_MASTERS_WIDTH			( NUM_MASTERS_WIDTH ), 			// defines number of bits to encode master number
			
			.NUM_SLAVES     			( NUM_SLAVES ), 				// defines number of slaves
			.NUM_SLAVES_WIDTH 			( NUM_SLAVES_WIDTH ),			// defines number of bits to encoode slave number

			.ID_WIDTH   				( ID_WIDTH ), 
			.DATA_WIDTH 				( DATA_WIDTH ),
		
			.SUPPORT_USER_SIGNALS 		( SUPPORT_USER_SIGNALS ),
			.USER_WIDTH 				( USER_WIDTH   ),

			.MASTER_READ_CONNECTIVITY 	( MASTER_READ_CONNECTIVITY  )
   
		)
	rdmx	(
			// Global Signals
			.sysClk 	( sysClk ),
			.sysReset	( sysReset ),					// active high reset synchronoise to RE AClk - asserted async.

			// Slot Arbitrator
			.requestorSelValid( requestorSelValid ),	// indicates that slot arb has selected valid requestor to drive to Slave
			.requestorSelEnc( requestorSelEnc 	),		// indicates requestor selected by slot arb when requestorSelValid is asserted
			.arbEnable		( arbEnable			),
		
			// Slave Data Ports
			.SLAVE_ID( SLAVE_ID ),
			.SLAVE_DATA( SLAVE_DATA ),
			.SLAVE_RESP( SLAVE_RESP ),
			.SLAVE_LAST( SLAVE_LAST ),
			.SLAVE_USER( SLAVE_USER ),
			.SLAVE_VALID( SLAVE_VALID ),
			.SLAVE_READY( SLAVE_READY ),
		
			// Master Data  Ports
			.masterID( masterID ),
			.MASTER_DATA( MASTER_DATA ),
			.MASTER_RESP( MASTER_RESP ),
			.MASTER_LAST( MASTER_LAST ),
			.MASTER_USER( MASTER_USER ),
			.MASTER_VALID( MASTER_VALID ),
			.MASTER_READY( MASTER_READY ),
			
			// AddressControl Port 		
			.currDataTransID( currDataTransID ),	// current data transaction ID
			.openTransDec( openTransDec )			// indicates thread matching currDataTransID to be decremented   
		)  /* synthesis syn_hier = "remove" */;

 
		
endmodule // ReadDataController.v
