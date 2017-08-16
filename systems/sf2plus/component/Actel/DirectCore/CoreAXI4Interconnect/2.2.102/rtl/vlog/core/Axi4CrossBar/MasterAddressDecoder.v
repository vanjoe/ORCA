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
// File			: MasterAddrDecoder.v                                            
// Author		: Olga Birkvalde                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This file decodes which slave device the master is addressing. The match is
//				combinationally output. It matches if the master address input matches the 
//				address range for the slave.
//	                                                               
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/07/14		OB			1.0			Initial release version               
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

module MasterAddressDecoder (
								masterAddr,
								match,					
								slaveMatched
							 );


//===================================================
// Parameter Declarations
//===================================================

	parameter NUM_SLAVES_WIDTH 	= 4;				// defines number bits for encoding slave number
	parameter NUM_SLAVES 		= 4;				// defines number of slaves	- includes derrSlave
	parameter SLAVE_NUM	 		= 0;				// defines slave that this decoder is for
	parameter ADDR_WIDTH 		= 32;				// number of address buts to be decoded
	
	parameter UPPER_COMPARE_BIT = 15;				// Defines the upper bit of range to compare
	parameter LOWER_COMPARE_BIT = 12;				// Defines lower bound of compare - bits below are 
													// dont care
													
	parameter [ADDR_WIDTH-1:UPPER_COMPARE_BIT]			SLOT_BASE_ADDR = 0;		// Base address of Slot
	parameter [UPPER_COMPARE_BIT-1:LOWER_COMPARE_BIT]	SLOT_MIN_ADDR = 0;		// slot min address
	parameter [UPPER_COMPARE_BIT-1:LOWER_COMPARE_BIT]	SLOT_MAX_ADDR = 0;		// slot max address
	parameter [NUM_SLAVES-1:0]							CONNECTIVITY = {NUM_SLAVES{1'b1}};	// onnectivity map - ie which slaves this master can access
	
//==========================================================================
// I/O Declarations
//============================================================================

	input 	[ADDR_WIDTH-1:0]		masterAddr;		// address to be decoded

	output							match;			// Indictaes this slave matched address
	output 	[NUM_SLAVES_WIDTH-1:0] 	slaveMatched;	// encoded number of slave
	
	
//============================================================================
// Local Declarationes
//============================================================================


	reg								match;			// Indictaes this slave matched address
	wire 	[NUM_SLAVES_WIDTH-1:0] 	slaveMatched;	// encoded number of slave
	
 
 
//==============================================================================
// Simple decode matching
//==============================================================================

assign slaveMatched = SLAVE_NUM;		// simply return number of slave instance

always @( * )
begin
	match <= 		( masterAddr[ADDR_WIDTH-1:UPPER_COMPARE_BIT] == SLOT_BASE_ADDR			 )		// base address matches
				&	( masterAddr[UPPER_COMPARE_BIT-1:LOWER_COMPARE_BIT] >= SLOT_MIN_ADDR	 )
				&	( masterAddr[UPPER_COMPARE_BIT-1:LOWER_COMPARE_BIT] <= SLOT_MAX_ADDR	 )
				&	CONNECTIVITY[SLAVE_NUM];														// only match if master can access this slave

end



endmodule // MasterAddressDecoder.v
