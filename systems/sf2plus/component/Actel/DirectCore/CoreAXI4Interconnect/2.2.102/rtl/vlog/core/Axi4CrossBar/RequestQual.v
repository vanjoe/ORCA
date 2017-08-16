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
// File			: RequestQual.v                                             
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module only asserted bits in slaveValidQual for ports what are requesting access to master that
// 				matches this ReadDataController instance.                              
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/07/14		OB			1.0			Initial release version 
// 29/06/16     JHayes      1.1         Change to deal with warning from width of MASTER_NUM field. 
//                                      Now set to maximum length and resized to use relevant bits 
//                                      internally.              
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

module RequestQual # 
	(
		parameter integer NUM_SLAVES 			= 8, 				// defines number of slaves requestors  
		parameter integer NUM_MASTERS_WIDTH		= 1, 				// defines number of bits to encode master number
		parameter integer ID_WIDTH   			= 1,
		parameter integer CROSSBAR_MODE			= 1				// defines whether non-blocking (ie set 1) or shared access data path
	)
	(
		input  wire [NUM_SLAVES-1:0]    								SLAVE_VALID,
		input  wire [2:0]					                			MASTER_NUM,     // jhayes : change to width to match maximum width possible.
  		input  wire [NUM_SLAVES*(NUM_MASTERS_WIDTH+ID_WIDTH)-1:0] 		SLAVE_ID,
		input  wire [NUM_SLAVES-1:0]									READ_CONNECTIVITY,
		
		output  reg [NUM_SLAVES-1:0]    								slaveValidQual
	);
						 
//================================================================================================
// Local Parameters
//================================================================================================
	localparam MASTERID_WIDTH		= ( NUM_MASTERS_WIDTH + ID_WIDTH );			// defines width masterID - includes infrastructure ID plus ID


//=================================================================================================
// Local Declarationes
//=================================================================================================
	reg	[NUM_MASTERS_WIDTH-1:0]		slaveTargetID	[0:NUM_SLAVES-1];

//=================================================================================================

genvar i;
generate 
	for (i=0; i < NUM_SLAVES; i=i+1)
		begin
			always @(*)
				begin
				// pick out infrastructure component from SLAVE_ID - ie target master
				slaveTargetID[i] 	<= SLAVE_ID[(i+1)*MASTERID_WIDTH-1:(i*MASTERID_WIDTH)+ ID_WIDTH];
			
				// Only assert slaveValidQual to arbitrator when slave valid is asserted and the SLAVE_ID is targetting this
				// master and READ_CONNECTIVITY is set for this slave
				slaveValidQual[i]	<= READ_CONNECTIVITY[i] & SLAVE_VALID[i] &  
												( CROSSBAR_MODE ?  ( slaveTargetID[i] == MASTER_NUM[NUM_MASTERS_WIDTH-1:0] )    // jhayes : change to use relevant bits of MASTER_NUM for comparison.
															    : 1'b1 );	// all slaves arb togather in non-crossbar mode - does not
																			// matter which master they want to connect to - only one path
				end
		end
		
endgenerate


endmodule // RequestQual.v
