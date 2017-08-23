// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This module provides a AXI4 Slave test source.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************
`timescale 1ns / 1ns

reg [15:0]	respCount, d_respCount;


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
	
			if ( SLAVE_BVALID )
				begin
					#1 $display( "%d, SLAVE  %d - Starting Write Response Transaction %d, BID= %h, BRESP= %h", 
							$time, SLAVE_NUM, respCount, SLAVE_BID, SLAVE_BRESP );

					if ( SLAVE_BREADY & SLAVE_BVALID )		// single beat
						begin
							#1 $display( "%d, SLAVE  %d - Ending Write Response Transaction %d, BID= %h", 
									$time, SLAVE_NUM, respCount, SLAVE_BID );
						end
					else
						begin
							@( posedge ( SLAVE_BREADY & SLAVE_BVALID)  )
								#1 $display( "%d, SLAVE  %d - Ending Write Response Transaction %d, BID= %h", 
									$time, SLAVE_NUM, respCount, SLAVE_BID );
						end
				end
		end

`endif



//=================================================================================================
// Local Declarationes for Slave Write Response Channel 
//=================================================================================================
 
reg [ID_WIDTH-1:0] 			d_SLAVE_BID;
reg [1:0]                   d_SLAVE_BRESP;
reg [USER_WIDTH-1:0]        d_SLAVE_BUSER;
reg                         d_SLAVE_BVALID;

reg [0:0]					bcurrState, bnextState;

localparam	[0:0]			bstIDLE = 1'h0,	bstDATA = 1'h1;


 //====================================================================================================
 // Slave Read Data S/M
//===================================================================================================== 
 always @( * )
 begin
 
	bnextState <= bcurrState;
	
	d_SLAVE_BID		<= SLAVE_BID;
	d_SLAVE_BRESP	<= SLAVE_BRESP;
	d_SLAVE_BUSER	<= 0;
	d_SLAVE_BVALID	<= 0;

	respFifRd	  	<= 0;

	d_respCount		<= respCount;

	case( bcurrState )
		bstIDLE: begin
					
					if ( ~respFifoEmpty )		// data to read
						begin
							//RESPFIF_WIDTH = ( ID_WIDTH + 2 );			// ID, Resp

							d_SLAVE_BID		<= respFifRdData[RESPFIF_WIDTH-1: RESPFIF_WIDTH-ID_WIDTH];
							d_SLAVE_BRESP	<= respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0];

							respFifRd		<= 1;		// pop fifo 

							bnextState 		<= bstDATA;
						end
				end
		rstDATA : begin
					d_SLAVE_BVALID	<= 1'b1;

					if ( SLAVE_BREADY & SLAVE_BVALID )
						begin
						
							d_respCount		<= respCount + 1'b1;

							if ( ~respFifoEmpty )				// if another burst request - start on next clock
								begin
									d_SLAVE_BVALID	<= 1'b1;
									d_SLAVE_BID		<= respFifRdData[RESPFIF_WIDTH-1: RESPFIF_WIDTH-ID_WIDTH];
									d_SLAVE_BRESP	<= respFifRdData[RESPFIF_WIDTH-ID_WIDTH-1: 0];
								
									respFifRd	<= 1;		// pop fifo 
									bnextState 	<= bstDATA;
								end
							else
								begin
									d_SLAVE_BVALID	<= 1'b0;
									d_SLAVE_BID		<= 0;
									d_SLAVE_BRESP	<= 0;
									
									bnextState <= bstIDLE;
								end
						end
					else			// not ready
						begin
									
						end
				end
	endcase
end


 always @(posedge sysClk or posedge sysReset)
 begin
 
	if (sysReset)
		begin
			SLAVE_BID		<= 0;
			SLAVE_BRESP		<= 0;
			SLAVE_BUSER		<= 0;
			SLAVE_BVALID	<= 0;
			respCount		<= 0;
			
			bcurrState	<= bstIDLE;
		end
	else
		begin
			SLAVE_BID		<= d_SLAVE_BID;
			SLAVE_BRESP		<= d_SLAVE_BRESP;
			SLAVE_BUSER		<= d_SLAVE_BUSER;
			SLAVE_BVALID	<= d_SLAVE_BVALID;	
			respCount		<= d_respCount;
			
			bcurrState	<= bnextState;
		end
end


 // Axi4SlaveGen_RespWr.v
