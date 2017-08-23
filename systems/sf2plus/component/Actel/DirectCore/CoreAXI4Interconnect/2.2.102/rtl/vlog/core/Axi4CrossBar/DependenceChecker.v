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
// File			: DependenceChecker.v                                            
// Author		: Olga Birkvalde                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module qualifies a requestor to check on dependencies with outstanding 
//				transactions. A request is pass through when (a) no outstanding transactions for that
//				ID (b) current request is for same target as previous transaction for ID (if outstanding 
//				requests) and not reached maxOutStanding transactions for that ID.
//	                                                               
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/07/14		OB			1.0			Initial release version        
// 02/10/14		JN			1.1       	Add in DERR Slave decoding
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
// *******************************************************************************/
// synopsys translate_off
//`include "../include/Timescale.h"
// synopsys translate_on

module DependenceChecker (
								masterAddr,
								masterValid,
								masterID,
								stopTrans,
								
								// TransactionController
								threadAvail,
								threadValid,
								threadCount,
								threadSlaveID,
	
								currTransSlaveValid,						// asserted when currTransSlaveID is valid
								currTransSlaveID,							// slaveID for current transaction
								currTransID,								// ID for current transaction
								
								// SlotArbitrator
								validQual
								
						 );


//======================================================================================================
// Parameter Declarations
//======================================================================================================

	parameter NUM_SLAVES 			= 4;		// defines number of slaves	- includes derrSlave
	parameter NUM_SLAVES_WIDTH 		= 2;		// defines number of bits to encoode slave number - includes derrSlave

	parameter MASTERID_WIDTH		= 4;		// defines number of bits to in masterID - includes Infrastructure ID + requestor ID
	
	parameter ADDR_WIDTH 			= 32;		// number of address bits to be decoded
	parameter ADDR_WIDTH_BITS		=  5;		// defines number of bits for ADDR_WIDTh - 64 -6, 32 = 5

	parameter NUM_THREADS			= 1;		// defined number of indpendent threads per master supported 
	parameter NUM_THREADS_WIDTH		= 1;		// defined number of bits to encode threads number 
	parameter OPEN_TRANS_MAX		= 3;		// max number of outstanding transactions 
	parameter OPEN_TRANS_WIDTH		= 2;		// width of open transaction count 

	parameter UPPER_COMPARE_BIT 	= 15;		// Defines the upper bit of range to compare
	parameter LOWER_COMPARE_BIT 	= 12;		// Defines lower bound of compare - bits below are dont care

	// No address space defined for derrSlace
	parameter [ ( (NUM_SLAVES-1)* (ADDR_WIDTH-UPPER_COMPARE_BIT) )-1 : 0 ] 			SLOT_BASE_VEC = 0;		// SLOT Base per slave 
	parameter [ ( (NUM_SLAVES-1)* (UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1 : 0 ] 	SLOT_MIN_VEC  = 0;		// SLOT Min per slave 
	parameter [ ( (NUM_SLAVES-1)* (UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1 : 0 ] 	SLOT_MAX_VEC  = 1;		// SLOT Max per slave 

	parameter [NUM_SLAVES-1:0]		CONNECTIVITY	= {NUM_SLAVES{1'b1}};			// onnectivity map - ie which slaves this master can access

	
	//========================== Master Port ==========================================

	input 	[ADDR_WIDTH-1:0]			masterAddr;									// address to be decoded
	input								masterValid;								// indicates Master has a valid address available
	
	input	[MASTERID_WIDTH-1:0]		masterID;									// unique ID per infrastructure Master port - includes infrastructure + ID

	//========================== TransactionController Port ===========================
	
	input								threadAvail;								// indicates a thread slot available for new threadID
	input								threadValid;								// indicates matched currTransID and threadCount and threadSlaveID valid
	input 	[OPEN_TRANS_WIDTH-1:0]		threadCount;
	input	[NUM_SLAVES_WIDTH-1:0]		threadSlaveID;
	
	output								currTransSlaveValid;						// asserted when currTransSlaveID is valid
	output	[NUM_SLAVES_WIDTH-1:0] 		currTransSlaveID;							// matched slaveID
	output	[MASTERID_WIDTH-1:0]		currTransID;								// ID for current transaction

	//====================== WrFifo Port ===============================================
	input wire 	[NUM_SLAVES-1:0]		stopTrans;									// indicates to address control to "stop" allowing 
																					// Address transactions.	

	//========================== SlotArbitrator Port  ===================================
	
	output								validQual;									// Indictaes this slave matched address

	
//=====================================================================================
// Local Declarations
//=====================================================================================

	localparam	[NUM_SLAVES_WIDTH-1:0]	DERR_SLAVEID	= NUM_SLAVES-1;				// Slave ID for DERR Slave
	
	
	wire 	[OPEN_TRANS_WIDTH-1:0]		threadCount;
	wire	[NUM_SLAVES_WIDTH-1:0]		threadSlaveID;

 	wire								currTransSlaveValid;					// asserted when currTransSlaveID is valid
	wire	[NUM_SLAVES_WIDTH-1:0] 		currTransSlaveID;						// slaveID for current transaction
	wire	[MASTERID_WIDTH-1:0]		currTransID;							// ID for current transaction

	wire								validQual;								// Indictaes this slave matched address
	
	wire	[NUM_SLAVES-2:0]			slaveMatch;								// Indictaes this slave matched address - not derrSlave
	wire	[NUM_SLAVES-2:0]			threadSlaveMatch;						// Indicates threadSlaveID matched slaveID decoded
	
	wire	[NUM_SLAVES-1:0]			validQualVec;							// Indictaes slave matched - one-hot encoded
																				// (MSB is derrSlave)

	
	//=====================================================================================
	 // Generates a binary coded from onehotone encoded
	 //====================================================================================
	function [4:0] fnc_hot2enc
    (
      input [31:0]  one_hot
    );
		begin
			if (one_hot == 0 )
				begin
					//$display("$t, DependencyChecker Error - one-hot error", $time, one_hot );
					//$stop;
				end
				
			fnc_hot2enc[0] = |(one_hot & 32'b1010_1010_1010_1010_1010_1010_1010_1010);
			fnc_hot2enc[1] = |(one_hot & 32'b1100_1100_1100_1100_1100_1100_1100_1100);
			fnc_hot2enc[2] = |(one_hot & 32'b1111_0000_1111_0000_1111_0000_1111_0000);
			fnc_hot2enc[3] = |(one_hot & 32'b1111_1111_0000_0000_1111_1111_0000_0000);
			fnc_hot2enc[4] = |(one_hot & 32'b1111_1111_1111_1111_0000_0000_0000_0000);
			
		end
	endfunction
	
	
	//================================================================================================
	// Generare a Master Address Decoder for each configured slave - but not for not derrSlave
	//================================================================================================
	genvar i;
	generate
		for (i=0; i< NUM_SLAVES-1; i=i+1 )		// do not decode for derrSlave
			begin
				MasterAddressDecoder 
					#( 	.NUM_SLAVES_WIDTH	( NUM_SLAVES_WIDTH 	),		// defines number of slaves
						.NUM_SLAVES			( NUM_SLAVES-1	   	), 		// defines number of slaves	- does not include derrSlave
						.SLAVE_NUM	 	  	( i 				),		// defines slave that this decoder is for
						.ADDR_WIDTH 	 	( ADDR_WIDTH		),		// number of address bits to be decoded
						.UPPER_COMPARE_BIT  ( UPPER_COMPARE_BIT ),		// Defines the upper bit of range to compare
						.LOWER_COMPARE_BIT  ( LOWER_COMPARE_BIT ),		// Defines lower bound of compare - bits below are dont care
						.SLOT_BASE_ADDR		( SLOT_BASE_VEC[ (i+1)*(ADDR_WIDTH-UPPER_COMPARE_BIT)-1: i*(ADDR_WIDTH-UPPER_COMPARE_BIT) ]  ),					// slot base address
						.SLOT_MIN_ADDR		( SLOT_MIN_VEC [ ((i+1)*(UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1:i*(UPPER_COMPARE_BIT-LOWER_COMPARE_BIT) ]  ),	// slot min address
						.SLOT_MAX_ADDR 		( SLOT_MAX_VEC [ ((i+1)*(UPPER_COMPARE_BIT-LOWER_COMPARE_BIT))-1:i*(UPPER_COMPARE_BIT-LOWER_COMPARE_BIT) ]  ),	// slot max address
						.CONNECTIVITY		( CONNECTIVITY[NUM_SLAVES-1:0]	)		// connectivity map - ie which slaves this master can access

					)
				u_MstAdrDec 
					(
						.masterAddr( masterAddr ),
						.match( slaveMatch[i] ),					
						.slaveMatched(  )
					);
	
				assign threadSlaveMatch[i] = ( threadSlaveID == i[NUM_SLAVES_WIDTH-1:0] );
				
				//=====================================================================================================
				// Check dependancy of current request to avoid deadlocks - this transaction is qualified to
				// request arbitration if valid asserted (ie active request) and if (a) there are no outstanding
				// transactions for thread or (b) the current transaction matches target (ie slaveID) of outstanding
				// transaction and not reached max outstanding transactions for this thread.
				//=====================================================================================================

				assign 	validQualVec[i] = masterValid & slaveMatch[i] & !stopTrans[i] &
													(   	( !threadValid & threadAvail  )					// set valid if no open transactions and thread slot available
														| 	( threadValid & (threadSlaveMatch[i]  )    		// or matched open thread and to same slave and
																		  & ( threadCount != OPEN_TRANS_MAX ) )					// not reach max open transaction
														);
	

			end
	endgenerate

	assign currTransSlaveValid = ( slaveMatch != 0 );						// asserted when a slave has been decoded

	//===========================================================================================================
	// Define validQualVec for Derr Slave to be same as other slaves to allow normal logic transInc/Dec to work
	// - bar only decoded when no other slave decoded.
	//===========================================================================================================

	assign validQualVec[NUM_SLAVES-1]	= masterValid & !currTransSlaveValid & !stopTrans[NUM_SLAVES-1];
														
	assign currTransSlaveID = currTransSlaveValid ? { fnc_hot2enc( slaveMatch ) } 				// set to decoded slave target
												  : DERR_SLAVEID;
	assign currTransID = masterID;
	
	assign	validQual= ( validQualVec == 0 ) ? 1'b0 : 1'b1;		// assert if any bit in vector set.

	
	
endmodule // DependenceChecker.v
