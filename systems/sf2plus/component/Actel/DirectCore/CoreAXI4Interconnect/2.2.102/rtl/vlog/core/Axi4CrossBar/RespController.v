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
// File			: RespController.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module controls which slave gets its response selected to be sent to
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

module RespController # 
	(
		parameter integer NUM_MASTERS			= 2, 				// defines number of masters
		parameter integer NUM_MASTERS_WIDTH		= 1, 				// defines number of bits to encode master number
		
		parameter integer NUM_SLAVES     		= 2, 				// defines number of slaves
		parameter integer NUM_SLAVES_WIDTH 		= 1,				// defines number of bits to encoode slave number

		parameter integer ID_WIDTH   			= 1, 

		parameter integer SUPPORT_USER_SIGNALS 	= 0,
		parameter integer USER_WIDTH 			= 1,

		parameter [NUM_MASTERS*NUM_SLAVES-1:0] 		MASTER_WRITE_CONNECTIVITY 		= {NUM_MASTERS*NUM_SLAVES{1'b1}},
		parameter [NUM_MASTERS*NUM_SLAVES-1:0] 		MASTER_READ_CONNECTIVITY 		= {NUM_MASTERS*NUM_SLAVES{1'b1}},
		
		parameter	HI_FREQ						= 0					// used to add registers to allow a higher freq of operation at cost of latency
   
	)
	(
		// Global Signals
		input  wire                                                    	sysClk,
		input  wire                                                    	sysReset,			// active high reset synchronoise to RE AClk - asserted async.
   
		//====================== Slave Data Ports  ================================================//
  
		input  wire [NUM_SLAVES*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		SLAVE_ID,
		input  wire [NUM_SLAVES*2-1:0]                         			SLAVE_RESP,
		input  wire [NUM_SLAVES*USER_WIDTH-1:0]         				SLAVE_USER,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_VALID,
		
		output wire [NUM_SLAVES-1:0]                           			SLAVE_READY,
		
		//====================== Master Data  Ports  ================================================//

		output wire [NUM_MASTERS*ID_WIDTH-1:0]          				MASTER_ID,
		output wire [NUM_MASTERS*2-1:0]                          		MASTER_RESP,
		output wire [NUM_MASTERS*USER_WIDTH-1:0]          				MASTER_USER,
		output wire [NUM_MASTERS-1:0]                            		MASTER_VALID,

		input  wire [NUM_MASTERS-1:0]                            		MASTER_READY,
   
		//====================== DataControl Port ============================================//
		
		output wire	[NUM_MASTERS*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		currDataTransID,	// current data transaction ID
		output wire	[NUM_MASTERS-1:0]  									openTransDec		// indicates thread matching currDataTransID to be decremented
	
	);
   						 
						 
//================================================================================================
// Local Parameters
//================================================================================================

	localparam MASTERID_WIDTH		= ( NUM_MASTERS_WIDTH + ID_WIDTH );			// defines width masterID - includes infrastructure ID plus ID
	localparam THREAD_VEC_WIDTH		= ( MASTERID_WIDTH + NUM_SLAVES_WIDTH );	// defines width of per thread vector elements width

	
//=================================================================================================
// Local Declarationes
//=================================================================================================
 	wire	[NUM_SLAVES-1:0]					requestorSel;
	wire	[NUM_SLAVES_WIDTH-1:0]				requestorSelEnc;
	wire										requestorSelValid;
	wire										arbEnable;
	
	
	//===========================================================================================================
	// Slot Aribrator - performs a round-robin arbitration among valid requestors for ownership
	// of data bus.
	//============================================================================================================
	RoundRobinArb #( .N( NUM_SLAVES ), .N_WIDTH( NUM_SLAVES_WIDTH ), .HI_FREQ( HI_FREQ )    )
				rrArb 	(
							// global signals
							.sysClk		( sysClk ),
							.sysReset	( sysReset ),

							.requestor		( SLAVE_VALID ),
							.arbEnable		( arbEnable ),				// arb again when selected master asserts increment (only 1 will)						
							.grant			( requestorSel 	 ),			// bit per master - 1-bit should only be set
							.grantEnc		( requestorSelEnc 	),		// encoded version of requestorSel
							.grantValid		( requestorSelValid )		// asserted when grant is valid
				
						);
	
	
	
	//===========================================================================================================
	// Slave Data Mux and Control - performs the MUX of slave requestor data vector to master and
	// controls response from master. 
	//============================================================================================================
	
	SlaveDataMuxController # 
		(
			.NUM_MASTERS				( NUM_MASTERS ), 				// defines number of masters
			.NUM_MASTERS_WIDTH			( NUM_MASTERS_WIDTH ), 			// defines number of bits to encode master number
			
			.NUM_SLAVES     			( NUM_SLAVES ), 				// defines number of slaves
			.NUM_SLAVES_WIDTH 			( NUM_SLAVES_WIDTH ),			// defines number of bits to encoode slave number

			.ID_WIDTH   				( ID_WIDTH ), 
		
			.SUPPORT_USER_SIGNALS 		( SUPPORT_USER_SIGNALS ),
			.USER_WIDTH 				( USER_WIDTH   ),

			.MASTER_READ_CONNECTIVITY 	( MASTER_READ_CONNECTIVITY  )
   
		)
	slmx	(
			// Global Signals
			.sysClk 	( sysClk ),
			.sysReset	( sysReset ),					// active high reset synchronoise to RE AClk - asserted async.

			// Slot Arbitrator
			.requestorSelValid( requestorSelValid ),	// indicates that slot arb has selected valid requestor to drive to Slave
			.requestorSelEnc( requestorSelEnc	),		// indicates requestor selected by slot arb when requestorSelValid is asserted			
			.arbEnable		( arbEnable			),
		
			// Slave Data Ports
			.SLAVE_ID( SLAVE_ID ),
			.SLAVE_RESP( SLAVE_RESP ),
			.SLAVE_USER( SLAVE_USER ),
			.SLAVE_VALID( SLAVE_VALID ),
			.SLAVE_READY( SLAVE_READY ),
		
			// Master Data  Ports
			.MASTER_ID( MASTER_ID ),
			.MASTER_RESP( MASTER_RESP ),
			.MASTER_USER( MASTER_USER ),
			.MASTER_VALID( MASTER_VALID ),
			.MASTER_READY( MASTER_READY ),
			
			// AddressControl Port 		
			.currDataTransID( currDataTransID ),	// current data transaction ID
			.openTransDec( openTransDec )			// indicates thread matching currDataTransID to be decremented   
		);

 
		
endmodule // RespController.v
