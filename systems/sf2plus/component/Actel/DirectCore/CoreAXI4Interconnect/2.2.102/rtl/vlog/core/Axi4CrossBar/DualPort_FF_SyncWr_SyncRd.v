`timescale 1ns / 1ns


// *******************************************************************************/
// Cloudium Systems Ltd. Proprietary and Confidential
// 
// Copyright 2013 Cloudium Systems Ltd.  All rights reserved. 
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
// (C) COPYRIGHT 2011, 2012, 2013  Cloudium Systems LTD.                      
// ALL RIGHTS RESERVED                                                        
//                                                                            
// File			: DualPort_RAM_SyncWr_SyncRd.v                                            
// Author		: John Hickey                                                  
// Date			: 21/08/13                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This file infers a dual-port ram based on FFs with sync write port and
//				a sync read port.
//
//                                                               
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/08/13		JH			1.0			Initial release version   
// 26/02/15		JH			1.1			Add HI_FREQ parameter to allow higher freq of operation 
//										to be traded off for extra latency.                 
//
//
// SVN Revision Information:
// SVN $Revision: 4805 $
// SVN $Date: 2008-11-27 17:48:48 +0530 (Thu, 27 Nov 2008) $
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

module DualPort_FF_SyncWr_SyncRd (
					// AHB global signals
					HCLK,

					// Write Port
					fifoWrAddr,	
					fifoWrite,
					fifoWrData,

					// Read Port
					fifoRdAddr,
					fifoRdData
				   
				)
				
		/* synthesis syn_ramstyle = "registers" */;

   

//============================================
// Parameter Declarations
//============================================

	parameter HI_FREQ	= 1;
	
	parameter FIFO_AWIDTH = 9;
	
	parameter FIFO_WIDTH = 8;
	
	localparam FIFO_DEPTH = 1 << FIFO_AWIDTH;


//============================================================================
// I/O ports
//============================================================================

// Inputs - AHB
	input HCLK;								// ahb system clock

	
// Write Port signals
	input [FIFO_WIDTH-1:0]	fifoWrData;		// Data to be written to ram
	input [FIFO_AWIDTH-1:0] fifoWrAddr;		// Addr to be written to in RAM
	input fifoWrite;						// Indicates address defined by fifoWrAddr to be written

 // Read Port signals
	output [FIFO_WIDTH-1:0]	 fifoRdData;	// Data to be written to ram
	input  [FIFO_AWIDTH-1:0] fifoRdAddr;	// Addr to be read from RAM

   
//============================================
// I/O Declarations
//============================================

	wire [FIFO_WIDTH-1:0]		fifoRdData;		// Data to be read from register
	reg  [FIFO_WIDTH-1:0]		fifoRdDataQ1;	// Data to be read from register - sync

	
//============================================
// Local Declarations
//============================================

	reg [FIFO_WIDTH-1:0] mem [0:FIFO_DEPTH-1];	// RAM array declaration

//====================================================================================
// Infer dual port ram - one sync write port - once async or sync read port based on
// HI_FREQ
//==================================================================================


assign fifoRdData = HI_FREQ ?  fifoRdDataQ1 : mem[fifoRdAddr];

always@ (posedge HCLK )
begin

	fifoRdDataQ1 <= mem[fifoRdAddr];
	
	if (fifoWrite)
		mem[fifoWrAddr] <= fifoWrData;

end


endmodule // DualPort_FF_SyncWr_SyncRd.v
