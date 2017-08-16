`timescale 1ns / 1ns


// *******************************************************************************/
// Cloudium Systems Ltd. Proprietary and Confidential
// 
// Copyright 2014, 2105 Cloudium Systems Ltd.  All rights reserved.
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
// (C) COPYRIGHT 2014, 2015  Cloudium Systems LTD.                      
// ALL RIGHTS RESERVED                                                        
//                                                                            
// File			: TragetMuxController.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module provides a revision for the Core. 
//	                                                               
//                                                                            
//                                                                            
//                                                                            
// Modification History:                                                      
// Date		By			Version		Change Description                        
//                                                                            
// 21/07/14		JN			1.0			Initial release version               
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
// synopsys translate_on//
// Defines the current FPGA version.
// Also defines the FPGA type  (encoder or decoder)
//  

module revision ( devRevision );

output  [31:0]   devRevision;

wire    [7:0]    relYear;
wire    [7:0]    relMonth;
wire    [7:0]    relDay;
wire    [7:0]    buildNum;
wire    [31:0]   devRevision;

assign relYear            = 8'h15;      // Date: Year
assign relMonth           = 8'h06;      // Date: Month      
assign relDay             = 8'h29;      // Date: Day
assign buildNum           = 8'b0000001; // Build number


assign devRevision = {relYear,relMonth,relDay, buildNum};

endmodule
