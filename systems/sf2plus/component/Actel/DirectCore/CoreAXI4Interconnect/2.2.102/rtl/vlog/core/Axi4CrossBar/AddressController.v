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
// File			: AddressController.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module controls which master gets its address selected to be sent to
//				target slave. It arbitrates between master requestors and tracks which
//				master transaction has been performed to avoid deadlock conditions. 
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
// 02/06/15		JH			1.2			Updated to have one Connectivity list rather read & write as
//										module re-used for both read & write addresses. Now only have
//										a MASTER_CONNECTIVITY parameter instead of MASTER_READ_CONNECTIVITY and
//										MASTER_WRITE_CONNECTIVITY.   
// 29/06/16     JHayes      1.3         Change to handle differences between read and write operations on the 
//                                      stopTrans signal. For writes, pass in stopTrans unchanged as the number 
//                                      of FIFOs matches the number of slaves. However, in contrast, for reads, 
//                                      the relevant FIFO is on a per master basis so replication of the appropriate 
//                                      stopTrans signal by the number of slaves, as dependence checker is looking 
//                                      at stopTrans signal on a per slave basis.            
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

module AddressController # 
	(
		parameter integer NUM_MASTERS			= 2, 				// defines number of masters
		parameter integer NUM_MASTERS_WIDTH		= 1, 				// defines number of bits to encode master number
		
		parameter integer NUM_SLAVES     		= 2, 				// defines number of slaves
		parameter integer NUM_SLAVES_WIDTH 		= 1,				// defines number of bits to encoode slave number

		parameter integer ID_WIDTH   			= 1, 

		parameter integer ADDR_WIDTH      		= 20,
		parameter integer ADDR_WIDTH_BITS		=  5,				// defines number of bits for ADDR_WIDTh - 64 -6, 32 = 5
		
		parameter NUM_THREADS			= 1,		// defined number of indpendent threads per master supported 
		parameter NUM_THREADS_WIDTH		= 1,		// defined number of bits to encode threads number 
		parameter OPEN_TRANS_MAX		= 3,		// max number of outstanding transactions 
		parameter OPEN_TRANS_WIDTH		= 2,		// width of open transaction count 

		parameter UPPER_COMPARE_BIT 	= 15,		// Defines the upper bit of range to compare
		parameter LOWER_COMPARE_BIT 	= 12,		// Defines lower bound of compare - bits below are dont care

		// Define memory map for slaves - none for DERR slave
		parameter [ ( (NUM_SLAVES-1)* (ADDR_WIDTH-UPPER_COMPARE_BIT) )-1 : 0 ] 			SLOT_BASE_VEC = { 5'h1F, 5'h0 },		// SLOT Base per slave 
		parameter [ ( (NUM_SLAVES-1)* (UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1 : 0 ] 	SLOT_MIN_VEC  = { 2'h0, 2'h0  },		// SLOT Min per slave 
		parameter [ ( (NUM_SLAVES-1)* (UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1 : 0 ] 	SLOT_MAX_VEC  = { 3'b111, 3'b111 },		// SLOT Max per slave 

		parameter integer SUPPORT_USER_SIGNALS 	= 0,
		parameter integer AUSER_WIDTH 			= 1,

		parameter [NUM_MASTERS*NUM_SLAVES-1:0] 		MASTER_CONNECTIVITY	= { NUM_MASTERS*NUM_SLAVES{1'b1} },					// includes DERR_SLAVE

		parameter HI_FREQ 			= 1,				// increases freq of operation at cost of added latency
        parameter WR_MODULE         = 1                 // jhayes : Parameter to indicate whether a read or write address controller required.
  
	)
	(
		// Global Signals
		input  wire                                                    	sysClk,
		input  wire                                                    	sysReset,			// active high reset synchronoise to RE AClk - asserted async.
   
		//====================== Master Ports  ================================================//

		// Master Address Ports
		input  wire [NUM_MASTERS*ID_WIDTH-1:0]        	   				MASTER_AID,
		input  wire [NUM_MASTERS*ADDR_WIDTH-1:0] 		          		MASTER_AADDR,
		
		input  wire [NUM_MASTERS*8-1:0]                          		MASTER_ALEN,
		input  wire [NUM_MASTERS*3-1:0]                          		MASTER_ASIZE,
		input  wire [NUM_MASTERS*2-1:0]                          		MASTER_ABURST,
		input  wire [NUM_MASTERS*2-1:0]                          		MASTER_ALOCK,
		input  wire [NUM_MASTERS*4-1:0]                          		MASTER_ACACHE,
		input  wire [NUM_MASTERS*3-1:0]                          		MASTER_APROT,
		input  wire [NUM_MASTERS*4-1:0]                          		MASTER_AQOS,
		input  wire [NUM_MASTERS*AUSER_WIDTH-1:0]         				MASTER_AUSER,
		input  wire [NUM_MASTERS-1:0]                            		MASTER_AVALID,
		output wire [NUM_MASTERS-1:0]                            		MASTER_AREADY,
   
		//====================== Slave Ports  ================================================//
   
		// Slave Address Port
		output wire [NUM_SLAVES*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		SLAVE_AID,
		output wire [NUM_SLAVES*8-1:0]                         			SLAVE_ALEN,
		
		output wire [(NUM_SLAVES-1)*ADDR_WIDTH-1:0]          			SLAVE_AADDR,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*3-1:0]                      		SLAVE_ASIZE,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*2-1:0]                      		SLAVE_ABURST,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*2-1:0]                      		SLAVE_ALOCK,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*4-1:0]                      		SLAVE_ACACHE,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*3-1:0]                      		SLAVE_APROT,		// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*4-1:0]                      		SLAVE_AQOS,			// not routed to DECERR Slaves
		output wire [(NUM_SLAVES-1)*AUSER_WIDTH-1:0]        			SLAVE_AUSER,		// not routed to DECERR Slaves		

		output wire [NUM_SLAVES-1:0]                           			SLAVE_AVALID,
		input  wire [NUM_SLAVES-1:0]                           			SLAVE_AREADY,
   
 
		//====================== DataControl Port ============================================//
		
		input wire	[NUM_MASTERS*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		currDataTransID,	// current data transaction ID
		input wire	[NUM_MASTERS-1:0]  									openTransDec,		// indicates thread matching currDataTransID to be decremented
		
		output wire														dataFifoWr,
		output wire	[(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 					srcPort,
		output wire	[NUM_SLAVES_WIDTH-1:0]								destPort,

		//====================== WrFifo Port ===============================================
		input wire 	[32:0]		stopTrans									// indicates to address control to "stop" allowing Address transactions.
                                                                            // jhayes : Widened to maximum width of 9, to include max number of FIFOs and the DERR_SLAVE.
	);
   						 
						 
//================================================================================================
// Local Parameters
//================================================================================================

	localparam MASTERID_WIDTH		= ( NUM_MASTERS_WIDTH + ID_WIDTH );			// defines width masterID - includes infrastructure ID plus ID

	
//=================================================================================================
// Local Declarationes
//=================================================================================================
 
	wire 	[ADDR_WIDTH-1:0]		masterAddr [NUM_MASTERS-1:0];
	wire 	[MASTERID_WIDTH-1:0]	masterID [NUM_MASTERS-1:0];
	wire	[NUM_MASTERS-1:0]		masterValid	;
	
	wire	[NUM_SLAVES_WIDTH-1:0]					transSlaveID [NUM_MASTERS-1:0];		// slaveID for current transaction			
	wire	[(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		dataTransID	 [NUM_MASTERS-1:0];		// data transaction ID
	
	wire	[NUM_MASTERS-1:0]			validQual;					// bit-mask of valid requestors from masters that are qualified (ie pass dependence check)
	wire	[NUM_MASTERS-1:0]			openTransInc;				// bit-mask to increment open transaction selected
	
	wire	[NUM_MASTERS*NUM_SLAVES_WIDTH-1:0]	targetSlave;		// slave that requestors want to perform transaction with

	wire	[NUM_MASTERS-1:0]					requestorSel;
	wire	[NUM_MASTERS_WIDTH-1:0]				requestorSelEnc;
	wire										requestorSelValid;
	wire										arbEnable;
    
    wire    [NUM_SLAVES-1:0]                    i_stopTrans [NUM_MASTERS-1:0]; // jhayes : Internal version of stopTrans, massaged to suit reads vs writes.

	
//================================================================================================
// Generare a MasterControl for each master port
//================================================================================================

	assign openTransInc = { requestorSel & { NUM_MASTERS{ arbEnable } }  };			// set trans inc for master selected
	
	genvar i;
	generate
		for (i=0; i< NUM_MASTERS; i=i+1 )
			begin	: mstctrlBlk

				// pick out components of the individual master
				assign 	masterAddr[i]		= MASTER_AADDR[( (i+1)*ADDR_WIDTH)-1 :(i*ADDR_WIDTH) ];
				assign 	masterValid[i]		= MASTER_AVALID[i];
				assign 	masterID [i]		= { i[NUM_MASTERS_WIDTH-1:0], MASTER_AID[( (i+1)*ID_WIDTH)-1 :(i*ID_WIDTH) ] };			// append infrastructure ID with ID from master
	
				assign	targetSlave[(i+1)*NUM_SLAVES_WIDTH-1:i*NUM_SLAVES_WIDTH] = transSlaveID[i];									// slaveID for this master			
				assign	dataTransID[i]	= currDataTransID[(i+1)*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:i*(NUM_MASTERS_WIDTH+ID_WIDTH)];		// dataTransID for this master
	
                // jhayes : For writes, pass in stopTrans unchanged as the number of FIFOs matches the number of slaves.
                // However, in contrast, for reads, the relevant FIFO is on a per master basis so replication of the appropriate stopTrans 
                // signal by the number of slaves, as dependence checker is looking at stopTrans signal on a per slave basis. 
                assign i_stopTrans[i] = WR_MODULE ? stopTrans[NUM_SLAVES-1:0] : {NUM_SLAVES{stopTrans[i]}}; 
    
				MasterControl # 
							(
								.NUM_SLAVES 		( NUM_SLAVES ),
								.NUM_SLAVES_WIDTH 	( NUM_SLAVES_WIDTH ),	
								.MASTERID_WIDTH		( MASTERID_WIDTH ),
								.ADDR_WIDTH 		( ADDR_WIDTH ),
								.ADDR_WIDTH_BITS	( ADDR_WIDTH_BITS ),	
								.NUM_THREADS		( NUM_THREADS ),
								.NUM_THREADS_WIDTH	( NUM_THREADS_WIDTH ),
								.OPEN_TRANS_MAX		( OPEN_TRANS_MAX ),
								.OPEN_TRANS_WIDTH	( OPEN_TRANS_WIDTH ),

								.UPPER_COMPARE_BIT	( UPPER_COMPARE_BIT ), 
								.LOWER_COMPARE_BIT 	( LOWER_COMPARE_BIT ),

								.SLOT_BASE_VEC 		( SLOT_BASE_VEC ),
								.SLOT_MIN_VEC		( SLOT_MIN_VEC ), 
								.SLOT_MAX_VEC		( SLOT_MAX_VEC ),
								.CONNECTIVITY		( MASTER_CONNECTIVITY[ NUM_SLAVES*i +: NUM_SLAVES ]  )
							)
					mstctrl(
								.sysClk				( sysClk 			),
								.sysReset			( sysReset 			),			// active high reset synchronoise to RE AClk - asserted async.
								.masterAddr			( masterAddr[i] 	),			// address to be decoded
								.masterValid		( masterValid[i] 	),			// indicates Master has a valid address available
								.masterID			( masterID[i]		),			// unique ID per infrastructure Master port - includes infrastructure + ID
								.validQual			( validQual[i]		),			// Indictaes this slave matched address
								.openTransInc		( openTransInc[i] 	),			// Increment openTransVec for thread matching currTransID
								.currTransSlaveID	( transSlaveID[i]	),			// slaveID this  master is targetting
								.currDataTransID	( dataTransID[i]	),			// current data transaction ID
								.openTransDec		( openTransDec[i] 	),			// indicates thread matching currDataTransID to be decremented
								.stopTrans			( i_stopTrans[i]			)
							)  /* synthesis syn_hier = "remove" */;	

			end
	endgenerate


	generate
		if (NUM_MASTERS == 1)			// no need to arb - always master0
			begin	: noArb
				assign requestorSel = 1;	
				assign requestorSelEnc = 0;
				assign requestorSelValid = validQual;
			end
		else
			begin	: rrArb
				//===========================================================================================================
				// Slot Aribrator - performs a round-robin arbitration among "qualified" valid requestors for ownership
				// of address bus.
				//============================================================================================================
				RoundRobinArb #( .N( NUM_MASTERS ), .N_WIDTH( NUM_MASTERS_WIDTH ), .HI_FREQ( HI_FREQ )   )
					rrArb 	(
								// global signals
								.sysClk		( sysClk ),
								.sysReset	( sysReset ),
	
								.requestor		( validQual ),
								.arbEnable		( arbEnable ),				// arb again when selected master asserts increment (only 1 will)						
								.grant			( requestorSel 	 ),			// bit per master - 1-bit should only be set
								.grantEnc		( requestorSelEnc 	),		// encoded version of requestorSel
								.grantValid		( requestorSelValid )		// asserted when grant is valid
				
							) /* synthesis syn_hier = "remove" */;
		
			end
	endgenerate
	
	
	//===========================================================================================================
	// Target Mux and Control - performs the MUX of "granted" requestor address vector to target and
	// controls response from target. Conditionally generate TargetMuxController based on NUM_MASTERS_WIDTH
	// to get aroound "elaboration" issues
	//============================================================================================================
	
	TargetMuxController # 
		(
			.NUM_MASTERS				( NUM_MASTERS ), 				// defines number of masters
			.NUM_MASTERS_WIDTH			( NUM_MASTERS_WIDTH ), 			// defines number of bits to encode master number
			
			.NUM_SLAVES     			( NUM_SLAVES ), 				// defines number of slaves
			.NUM_SLAVES_WIDTH 			( NUM_SLAVES_WIDTH ),			// defines number of bits to encoode slave number

			.ID_WIDTH   				( ID_WIDTH ), 

			.ADDR_WIDTH      			( ADDR_WIDTH ),
			.ADDR_WIDTH_BITS			( ADDR_WIDTH_BITS ),				// defines number of bits for ADDR_WIDTh - 64 -6, 32 = 5
		
			.SUPPORT_USER_SIGNALS 		( SUPPORT_USER_SIGNALS ),
			.AUSER_WIDTH 				( AUSER_WIDTH   ),

			.MASTER_CONNECTIVITY 		( MASTER_CONNECTIVITY ), 
			.HI_FREQ 					( HI_FREQ )
   
		)
	trgmx	(
			// Global Signals
			.sysClk 	( sysClk ),
			.sysReset	( sysReset ),					// active high reset synchronoise to RE AClk - asserted async.

			// Slot Arbitrator
			.requestorSelValid( requestorSelValid ),	// indicates that slot arb has selected valid requestor to drive to Slave
			.requestorSelEnc( requestorSelEnc 	),		// encoded version of requestorSel
			.targetSlave	( targetSlave 		),		// slave that requestors wants to perform transaction with
			.arbEnable		( arbEnable			),
		
			//====================== Master Ports  ================================================//
			.MASTER_AID		( MASTER_AID ),
			.MASTER_AADDR	( MASTER_AADDR ),
		
			.MASTER_ALEN	( MASTER_ALEN ),
			.MASTER_ASIZE	( MASTER_ASIZE ),
			.MASTER_ABURST	( MASTER_ABURST ),
			.MASTER_ALOCK	( MASTER_ALOCK ),
			.MASTER_ACACHE	( MASTER_ACACHE ),
			.MASTER_APROT	( MASTER_APROT ),
			.MASTER_AQOS	( MASTER_AQOS ),
			.MASTER_AUSER	( MASTER_AUSER ),
			.MASTER_AREADY	( MASTER_AREADY ),
   
			//====================== Slave Ports  ================================================//
			.SLAVE_AID		( SLAVE_AID ),
			.SLAVE_AADDR	( SLAVE_AADDR ),
			.SLAVE_ALEN		( SLAVE_ALEN ),
			.SLAVE_ASIZE	( SLAVE_ASIZE ),
			.SLAVE_ABURST	( SLAVE_ABURST ),
			.SLAVE_ALOCK	( SLAVE_ALOCK ),
			.SLAVE_ACACHE	( SLAVE_ACACHE ),
			.SLAVE_APROT	( SLAVE_APROT ),
			.SLAVE_AQOS		( SLAVE_AQOS ),
			.SLAVE_AUSER	( SLAVE_AUSER ),
			.SLAVE_AVALID	( SLAVE_AVALID ),
			.SLAVE_AREADY	( SLAVE_AREADY ),
			
			//====================== DataController Ports  ================================================//
			.dataFifoWr( dataFifoWr ),
			.srcPort( srcPort ),
			.destPort( destPort )
			
		)	/* synthesis syn_hier = "remove" */; 

`ifdef VERBOSE
always @( stopTrans  )
begin
	if ( stopTrans )
		$display("%t, stopTrans asserted: %m", $time);
	else
		$display("%t, stopTrans desserted: %m", $time);

end
`endif


endmodule // AddressController.v
