`ifndef VERILOG_TOP_V
`define VERILOG_TOP_V

module verilog_top
  (
	//spi
	spi_mosi   ,
	spi_miso  ,
	spi_ss    ,
	spi_sclk  ,

	//uart
	txd ,

	//clk
	cam_xclk  ,
	cam_vsync  ,
	cam_href  ,
	cam_dat   ,

	 //sccb
	sccb_scl  ,
	sccb_sda  );


	input [7:0] cam_dat ;
	input 		cam_xclk;
	input 		cam_vsync;
	input 		cam_href;
	output 		spi_mosi;
	input 		spi_miso;
	output 		spi_ss  ;
	output 		spi_sclk;
	inout 		sccb_scl;
	inout 		sccb_sda;
	output 		txd    ;

	wire [7:0]	cam_dat_internal;
	wire 			cam_xclk_internal;


	vhdl_top sub_top
	  (
		.cam_dat (cam_dat_internal ),
		.cam_xclk(cam_xclk_internal),
		.cam_vsync(cam_vsync),
		.cam_href(cam_href),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.spi_ss  (spi_ss  ),
		.spi_sclk(spi_sclk),
		.sccb_scl(sccb_scl),
		.sccb_sda(sccb_sda),
		.txd(txd)
		);

   SB_IO_OD
     od0(
        .PACKAGEPIN (cam_xclk),
        .LATCHINPUTVALUE (0),
        .CLOCKENABLE (0),
        .INPUTCLK (0),
        .OUTPUTCLK (0),
        .OUTPUTENABLE (0),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (cam_xclk_internal),
        .DIN1 ()

        );
   defparam od0.PIN_TYPE = 6'b000001;
   defparam od0.NEG_TRIGGER = 1'b0;


	SB_IO_OD
     od1(
        .PACKAGEPIN (cam_dat[0]),
        .LATCHINPUTVALUE (0),
        .CLOCKENABLE (0),
        .INPUTCLK (0),
        .OUTPUTCLK (0),
        .OUTPUTENABLE (0),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (cam_dat_internal[0]),
        .DIN1 ()

        );
   defparam od1.PIN_TYPE = 6'b000001;
   defparam od1.NEG_TRIGGER = 1'b0;


	SB_IO_OD
     od2(
        .PACKAGEPIN (cam_dat[1]),
        .LATCHINPUTVALUE (0),
        .CLOCKENABLE (0),
        .INPUTCLK (0),
        .OUTPUTCLK (0),
        .OUTPUTENABLE (0),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (cam_dat_internal[1]),
        .DIN1 ()

        );
   defparam od2.PIN_TYPE = 6'b000001;
   defparam od2.NEG_TRIGGER = 1'b0;


	assign cam_dat_internal[7:2] = cam_dat[7:2];


endmodule // verilog_top

`endif //TOP_TOP_V
