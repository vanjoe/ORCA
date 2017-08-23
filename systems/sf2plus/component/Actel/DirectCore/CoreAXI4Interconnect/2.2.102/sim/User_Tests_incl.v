// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: CoreAXI4Interconnect testbench
//
// Revision Information:
// Date     Description:     Tests for user testbench to verify operation with all ports defined as Masters & Slaves.
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************

begin
    $display( "\n\n===============================================================================================================" );
    $display( "                        User Testing with all Masters- all Slaves" ); 
    $display( "===============================================================================================================\n\n" );

    for (multiSize = 0; multiSize < 8; multiSize = multiSize+1)
    begin

    for (burst = 0; burst < 3; burst = burst+1)
    begin
    
    #100;
    @(posedge ACLK);
    $display( "\n\n===============================================================================================================" );
    $display( "%t  --- Test 1 - Check Write Connectivity map - Write from each Master to each slave       ", $time );
    $display( "===============================================================================================================\n\n" );

    //===========  Write to each slave from each master =====================
    for ( j=0; j<NUM_MASTERS; j=j+1 )
      begin
        WRITE_CONNECTIVITY = MASTER_WRITE_CONNECTIVITY[(j*NUM_SLAVES) +: NUM_SLAVES ];
      
        for ( k=0; k <NUM_SLAVES; k=k+1 )	
          begin

            TxSize <= multiSize % (1+($clog2(MASTER_PORTS_DATA_WIDTH[(32*j)+:32]/8)));
            wrAddr[ADDR_WIDTH-1:ADDR_WIDTH-ADDR_DEC_WIDTH]	<= k[ADDR_DEC_WIDTH-1:0];
            wrAddr[NUM_AXISLAVE_BITS-1:NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH]	<= j[NUM_MASTERS_WIDTH-1:0];		// map each Master into different memory area in Slave
            wrAddr[NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-1:NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-NUM_SLAVES_WIDTH]	<= k[NUM_SLAVES_WIDTH-1:0];		// map each Slave into different memory area in Slave
            wrAddr[NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-NUM_SLAVES_WIDTH-1:0]  <= 0;

            @(posedge M_CLK[j]);
            @(posedge M_CLK[j]);

            for (cnt = 0; cnt < MAX_TX_MST_SLV; cnt = cnt + 1)
            begin
        
            wrID			<= k+j+1;

            
            wrResp			<= ( WRITE_CONNECTIVITY[k] ) ? 2'b0 : 2'b11;

            $display("WRITE transaction: master %d type %d slave %d master data width", j, MASTER_TYPE[(2*j)+:2], k, MASTER_PORTS_DATA_WIDTH[(32*j)+:32]);
            if (MASTER_TYPE[(2*j)+:2] == 2'b10) begin // AHB master
              #1;
              hburst <= (cnt % 8);
              hsize <= TxSize;
              haddr <= 32'h0 |  (wrAddr & ~((1<< TxSize)-1));
              hwrite <= 1'b1;
              start_tx <= 1 << j;

              @(posedge M_CLK[j]);
              start_tx <= 'b0;
              #1;
              @(posedge end_tx[j]);
            end
            else begin

              offset_addr = (((((cnt+CNT_INIT)%(((burst == 1)&& (MASTER_TYPE[(2*j)+:2] == 2'b00) ) ? 256 : 16))+1) << TxSize));
              #1 next_addr = ((wrAddr+offset_addr));

              if (wrAddr[ADDR_WIDTH-1:12] == (next_addr >> 12) ) begin
                if (burst == 2) begin
                    wrLen <= 2**((cnt % 4) + 1) - 1;
                 end
                 else begin
                    wrLen			<= (cnt+CNT_INIT) % (((burst == 1) && (MASTER_TYPE[(2*j)+:2] == 2'b00)) ? 256 : 16);
                 end
                 no_tx = 0;
              end
              else begin
                if (burst == 2) begin
                  if (((13'h1000 - wrAddr[11:0]) >> TxSize) < 2) begin
                    no_tx = 1;
                    wrLen = 1;
                  end
                  else begin
                    no_tx = 0;
                    wrLen <= 2**((((13'h1000 - wrAddr[11:0]) >> TxSize) % 4) + 1) - 1;
                  end
                end
                else begin
                  no_tx = 0;
                  wrLen     <= ((12'hFFF - wrAddr[11:0]) >> TxSize);
                end
              end
            
            if (burst == 2'b10) begin // WRAP burst
              wrAddr[5:0] <= 6'h0;
            end
            
            if (MASTER_TYPE[(2*j)+:2] == 2'b01) begin // AXI4-Lite master
                wrLen <=  'b0;
                TxSize <= $clog2(MASTER_PORTS_DATA_WIDTH[(32*j)+:32]/8);
            end
            if (no_tx == 0) begin
                #1 AXI4Write( j[7:0], (wrAddr), wrID, wrLen, burst, TxSize, wrResp  );				// master to each slave

              #1 $display("\n %t, Waiting for masterRespDone[%d] to assert for write to slave[%d]\n", $time,  j, k );
          
              @(posedge masterRespDone[j] )
                begin
                  #1;

                  if ( WRITE_CONNECTIVITY[k] )	// if master can write to slave
                    begin
                      if ( ~masterWrStatus[j] )
                        begin
                          #1 $display("%t, MASTER Error - masterWrStatus = %b", $time,  masterWrStatus[j] );
                          $stop;
                        end
                      passStatus = passStatus & masterWrStatus[j];	
                    end
                  else							// if master cannot wrote to slave - should get DECRR back
                    begin
                      if ( ~masterWrStatus[j] )
                        begin
                          #1 $display("%t, MASTER Error - expected DECERR- masterWrStatus = %b", $time,  masterWrStatus[j] );
                          $stop;
                        end
                      else
                        begin
                          #1 $display("\n%t, MASTER DECERR ok - expected DECERR- masterWrStatus = %b\n", $time,  masterWrStatus[j] );
                        end
                      passStatus = passStatus & masterWrStatus[j];
                    end
                end
            end
            
          end


            if  (MASTER_TYPE[(2*j)+:2] == 2'b10) begin
              if (hburst == 1)
                wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + (UNDEF_AHB_BURST[(8*j)+:8] << TxSize));
              else
                wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + ((2**(1+hburst[2:1])+2) << TxSize));
            end
            else if (burst == 2'b10) begin
              wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + (2 << ($clog2(wrLen+1)+TxSize));
            end
            else begin
              wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( wrAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + ((cnt+CNT_INIT+2) << TxSize));
            end

            end
          end

      end

      
    $display( "\n\n===============================================================================================================" );
    $display( "%t  --- Test 2 - Check Read Connectivity map - Read from each Slave to each Master       ", $time );
    $display( "==============================================================================================================\n\n " );
  

    //===========  Read from each slave from each master =====================
    for ( j=0; j<NUM_MASTERS; j=j+1 )
      begin
        READ_CONNECTIVITY = MASTER_READ_CONNECTIVITY[(j*NUM_SLAVES) +: NUM_SLAVES ];

        for ( k=0; k <NUM_SLAVES; k=k+1 )	
          begin
            TxSize <= multiSize % (1+($clog2(MASTER_PORTS_DATA_WIDTH[(32*j)+:32]/8)));
            rdAddr[ADDR_WIDTH-1:ADDR_WIDTH-ADDR_DEC_WIDTH]	<= k[ADDR_DEC_WIDTH-1:0];
            rdAddr[NUM_AXISLAVE_BITS-1:NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH]	<= j[NUM_MASTERS_WIDTH-1:0];		// map each Master into different memory area in Slave
            rdAddr[NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-1:NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-NUM_SLAVES_WIDTH]	<= k[NUM_SLAVES_WIDTH-1:0];		// map each Slave into different memory area in Slave
            rdAddr[NUM_AXISLAVE_BITS-NUM_MASTERS_WIDTH-NUM_SLAVES_WIDTH-1:0]  <= 0;

            @(posedge M_CLK[j]);
            @(posedge M_CLK[j]);

            for (cnt = 0; cnt < MAX_TX_MST_SLV; cnt = cnt + 1)
            begin
            
              rdID			<= k+j+1;
              rdResp			<= READ_CONNECTIVITY[k] ? 2'b0 : 2'b11;

              $display("READ transaction: master %d type %d slave %d master data width %d", j, MASTER_TYPE[(2*j)+:2], k, MASTER_PORTS_DATA_WIDTH[(32*j)+:32]);
              if (MASTER_TYPE[(2*j)+:2] == 2'b10) begin // AHB master
                #1;
                hburst <=  (cnt % 8);
                hsize <= TxSize;
                haddr <= 32'h0 | (rdAddr & ~((1<< TxSize)-1));
                hwrite <= 1'b0;
                start_tx <= 1 << j;
                @(posedge M_CLK[j]);
                start_tx <= 'b0;
                #1;
                @(posedge end_tx[j]);
              end
              else begin

                offset_addr = (((((cnt+CNT_INIT)%(((burst == 1)&& (MASTER_TYPE[(2*j)+:2] == 2'b00) ) ? 256 : 16))+1) << TxSize));
                #1 next_addr = ((rdAddr+offset_addr));

                if (rdAddr[ADDR_WIDTH-1:12] == (next_addr >> 12))  begin
                  if (burst == 2) begin
                    rdLen <= 2**((cnt % 4) + 1) - 1;
                  end
                  else begin
                    rdLen			<= (cnt+CNT_INIT) % (((burst == 1) && (MASTER_TYPE[(2*j)+:2] == 2'b00)) ? 256 : 16);
                  end
                    no_tx = 0;
                end
                else begin
                  if (burst == 2) begin
                    if (((13'h1000 - rdAddr[11:0]) >> TxSize) < 2) begin
                      no_tx = 1;
                      rdLen = 1;
                    end
                    else begin
                      no_tx = 0;
                      rdLen <= 2**((((13'h1000 - rdAddr[11:0]) >> TxSize) % 4) + 1) - 1;
                    end
                  end
                  else begin
                    no_tx = 0;
                    rdLen     <= ((12'hFFF - rdAddr[11:0]) >> TxSize);
                  end
                end

              if (burst == 2'b10) begin // WRAP burst
                rdAddr[5:0] <= 6'h00;
              end
              
              if (MASTER_TYPE[(2*j)+:2] == 2'b01) begin // AXI4-Lite master
                rdLen <=  'b0;
                TxSize <= $clog2(MASTER_PORTS_DATA_WIDTH[(32*j)+:32]/8);
              end
                    
              if (no_tx == 0) begin
                #1 AXI4Read( j[7:0], (rdAddr), rdID, rdLen, burst, TxSize, rdResp  );				// master to each slave

                #1 $display("\n %t, Waiting for masterRdDone[%d] to assert for read from slave[%d]\n", $time,  j, k );

                @(posedge masterRdDone[j] )
                  begin
                    #1;
                    if ( READ_CONNECTIVITY[k] )	// if master can read from slave
                      begin
                        if ( ~masterRdStatus[j] )
                          begin
                            #1 $display("%t, MASTER Error - masterRdStatus = %b", $time,  masterRdStatus[j] );
                            $stop;
                          end
                        passStatus = passStatus & masterRdStatus[j];	
                      end
                    else							// if master cannot wrote to slave - should get DECRR back
                      begin
                        if ( ~masterRdStatus[j] )
                          begin
                            #1 $display("%t, MASTER Error - expected DECERR- masterRdStatus = %b", $time,  masterRdStatus[j] );
                            $stop;
                          end
                        else
                          begin
                            #1 $display("\n%t, MASTER DECERR ok - expected DECERR- masterRdStatus = %b\n", $time,  masterRdStatus[j] );
                          end
                        passStatus = passStatus & masterRdStatus[j];
                      end
                  end
              end
             end

              if  (MASTER_TYPE[(2*j)+:2] == 2'b10) begin
                if (hburst == 1)
                  rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + (UNDEF_AHB_BURST[(8*j)+:8] << TxSize));
                else
                  rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + ((2**(1+hburst[2:1])+2) << TxSize));
              end
              else if (burst == 2'b10) begin
                rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + (2 << ($clog2(rdLen+1)+TxSize));
              end
              else begin
                rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] <= ( rdAddr[NUM_AXISLAVE_BITS-NUM_SLAVES_WIDTH-NUM_MASTERS_WIDTH-1:0] + ((cnt+CNT_INIT+2) << TxSize));
              end
              
            end
        end
      end
      
    end
  end


    #50;
    if (passStatus)
      begin
        $display( "\n\n==============================================================================================" );
        $display( "%t Passed : all tests passed", $time );
        $display( "==============================================================================================\n\n" );
        //$stop;
      end
    else
      begin
        $display( "\n\n============================================================================================" );
        $display( "%t FAIL : at least 1 tests failed ", $time );
        $display( "==============================================================================================\n" );
      end


    #500 
    $stop;
    $finish;

end		// User_Tests_incl.v
