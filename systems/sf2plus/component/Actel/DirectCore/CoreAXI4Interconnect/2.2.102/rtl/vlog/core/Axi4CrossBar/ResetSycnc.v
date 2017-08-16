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
// File			: ResetSync.v                                            
// Author		: J. Nolan                                                  
// Date			: 21/07/14                                                    
// Version		: 1.0                                                     	  
//                                                                            
// Abstract	: 	This module provides active high synchronised version of sysReset_N to sysClk
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

module ResetSycnc  
	(
		input  wire             	sysClk,
		input  wire                 sysReset_L,			// active low reset synchronoise to RE AClk - asserted async.

		output reg					sysReset			// active high sysReset synchronised to sysClk
	);
   						 
						 
//================================================================================================
// Local Parameters
//================================================================================================

	
	
//=================================================================================================
// Local Declarationes
//=================================================================================================
 

//=================================================================================================
always @(posedge sysClk or negedge sysReset_L)
begin
	if( ~sysReset_L )
		sysReset <= 1'b1;			// active high reset on
	else
		sysReset <= 1'b0;			// active high reset off
end


endmodule // ResetSycnc.v
