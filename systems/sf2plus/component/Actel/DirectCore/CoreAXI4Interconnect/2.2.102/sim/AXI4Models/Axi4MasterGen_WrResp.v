// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Master write response channel.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

//====================================================================================================
// Local Declarationes for Master Write Response Channel 
//====================================================================================================

localparam	[2:0]		bstIDLE = 3'h0,	bstDATA = 3'h1;

reg						d_MASTER_BREADY, bIdle;

reg [2:0]				bcurrState, bnextState;

reg	[15:0]				respCount, d_respCount;


//=============================================================================================
// Display messages only in Simulation - not synthesis
//=============================================================================================
`ifdef SIM_MODE

	//=============================================================================================
	// Display messages for Write Response Channel
	//=============================================================================================
	always @( posedge sysClk )
		begin
			#1;
	
			if ( MASTER_BVALID )
				begin
					#1 $display( "%d, MASTER %d - Starting Write Response Transaction %d, BID= %h, BRESP= %h", 
										$time, MASTER_NUM, respCount, MASTER_BID, MASTER_BRESP );

					if ( MASTER_BREADY & MASTER_BVALID)		// single beat
						begin
							#1 $display( "%d, MASTER %d - Ending Write Response Transaction %d, BID= %h, wrStatus= %b", 
										$time, MASTER_NUM, respCount, MASTER_BID, masterWrStatus );
						end
					else
						begin
							@( posedge ( MASTER_BREADY & MASTER_BVALID) )
								#1 $display( "%d, MASTER %d - Ending Write Response Transaction %d, BID= %h, wrStatus= %b", 
										$time, MASTER_NUM, respCount, MASTER_BID, masterWrStatus );
						end
				end
		end

	// Check BResp is as expected
	always @( posedge sysClk )
		begin
			#1;		
			
			if ( MASTER_BREADY & MASTER_BVALID)		// single beat
				if ( MASTER_BRESP != respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0] )
					begin
						$display( "%d, MASTER %d ERROR - expWResp= %h, act BRESP= %h", $time, MASTER_NUM, 
											respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0], MASTER_BRESP );

						#1 $stop;
					end		
		end
		
`endif



//====================================================================================================
// Master Write Response S/M
//===================================================================================================== 
 always @( * )
 begin
 
	bnextState <= bcurrState;

	//d_MASTER_BREADY	<= MASTER_BREADY;	
	d_MASTER_BREADY	<= d_MASTER_BREADY_default;	
	
	bIdle	 	<= 0;
	respFifRd	<= 0;
	masterRespDone  <= 0;
	masterWrStatus	<= 0;

	d_respCount <= respCount;		// running counter of number of responses completed
	
	case( bcurrState )
		bstIDLE: begin
					bIdle	<= 1;
			
					d_MASTER_BREADY		<= d_MASTER_BREADY_default;
			
					if ( MASTER_BVALID & MASTER_BREADY )	
						begin
							bIdle		<= 0;

							masterWrStatus <= 	( 	( MASTER_BID ==  respFifRdData[RESPFIF_WIDTH-1: RESPFIF_WIDTH-ID_WIDTH]   	)
												  & ( MASTER_BRESP == respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0]   				)
												);
							masterRespDone  <= 1;
							respFifRd		<= 1'b1;

							d_respCount <= respCount + 1'b1;
							
						end
					else if ( MASTER_BVALID & !MASTER_BREADY )		// move to assert ready
						begin
							d_MASTER_BREADY	<= 1'b1;
							bnextState 	<= bstDATA;
						end
				end
		bstDATA : begin
					bIdle				<= 0;
					d_MASTER_BREADY		<= 1'b1;
			
					if ( MASTER_BVALID & MASTER_BREADY )	
						begin
							
							masterWrStatus <= 	( 	( MASTER_BID ==  respFifRdData[RESPFIF_WIDTH-1: RESPFIF_WIDTH-ID_WIDTH]   	)
												  & ( MASTER_BRESP == respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0]   				)
												);
												
							masterRespDone  <= 1;
							respFifRd		<= 1'b1;

							d_respCount <= respCount + 1'b1;
					
							d_MASTER_BREADY	<= d_MASTER_BREADY_default;
							
							bnextState 	<= bstIDLE;
						end
					else			// not ready
						begin
									
						end
				end
	endcase
end


 always @(posedge sysClk or posedge sysReset )
 begin
 
	if (sysReset)
		begin
			MASTER_BREADY	<= 1'b0;
			bcurrState		<= bstIDLE;
			respCount		<= 0;

		end
	else
		begin
			MASTER_BREADY	<= d_MASTER_BREADY;

			bcurrState		<= bnextState;
			
			respCount		<= d_respCount;

		end
end

		
		
 // Axi4MasterGen_WrResp.v
