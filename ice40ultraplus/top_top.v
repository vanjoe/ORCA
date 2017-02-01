`ifndef VERILOG_TOP_V
`define VERILOG_TOP_V

module verilog_top
  (
	//spi
	spi_mosi   ,
	spi_miso  ,
	spi_ss    ,
	spi_sclk  ,
	cdone_led ,
	//uart
	txd ,
	rxd ,
	//clk
	cam_xclk  ,
	cam_vsync  ,
	cam_href  ,
	cam_dat   ,

	 //sccb
	sccb_scl  ,
	sccb_sda  );

	parameter USE_PLL = 1;
	parameter USE_CAM = 1;

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
	output 		rxd;
	output 		cdone_led;

	wire 		cam_xclk_internal;
	wire 		cam_xclk_internal_buf;
	wire [7:0]	cam_dat_internal;
	wire 		cam_href_internal;
	wire 		cam_vsync_internal;

//	assign cdone_led = 0;


	vhdl_top
	  #(
	    .USE_PLL(USE_PLL),
	    .USE_CAM(USE_CAM)
	    )
	sub_top
	  (
		.cam_dat (cam_dat_internal),
		.cam_xclk(cam_xclk_internal),
		.cam_vsync(cam_vsync_internal),
		.cam_href(cam_href_internal),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.spi_ss  (spi_ss  ),
		.spi_sclk(spi_sclk),
		.sccb_scl(sccb_scl),
		.sccb_sda(sccb_sda),
		.led(cdone_led),
		.txd(txd),
		.rxd(rxd)
		);

	SB_IO_OD
     odclk(
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
   defparam odclk.PIN_TYPE = 6'b000001;
   defparam odclk.NEG_TRIGGER = 1'b0;

	SB_IO_OD
     od0(
        .PACKAGEPIN (cam_dat[0]),
        .LATCHINPUTVALUE (0),
        .CLOCKENABLE (1),
        .INPUTCLK (cam_xclk_internal_buf),
        .OUTPUTCLK (0),
        .OUTPUTENABLE (0),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (cam_dat_internal[0]),
        .DIN1 ()
//        .DIN0 (),
//        .DIN1 (cam_dat_internal[0])
        );
   defparam od0.PIN_TYPE = 6'b000000;
   defparam od0.NEG_TRIGGER = 1'b0;


	SB_IO_OD
     od1(
        .PACKAGEPIN (cam_dat[1]),
        .LATCHINPUTVALUE (0),
        .CLOCKENABLE (1),
        .INPUTCLK (cam_xclk_internal_buf),
        .OUTPUTCLK (0),
        .OUTPUTENABLE (0),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (cam_dat_internal[1]),
        .DIN1 ()
//        .DIN0 (),
//        .DIN1 (cam_dat_internal[1])
        );
   defparam od1.PIN_TYPE = 6'b000000;
   defparam od1.NEG_TRIGGER = 1'b0;

	SB_IO
     od2(
        .PACKAGE_PIN (cam_dat[2]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[2]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[2])
        );
   defparam od2.PIN_TYPE = 6'b000000;
   defparam od2.NEG_TRIGGER = 1'b0;

	SB_IO
     od3(
        .PACKAGE_PIN (cam_dat[3]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[3]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[3])
        );
   defparam od3.PIN_TYPE = 6'b000000;
   defparam od3.NEG_TRIGGER = 1'b0;

	SB_IO
     od4(
        .PACKAGE_PIN (cam_dat[4]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[4]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[4])
        );
   defparam od4.PIN_TYPE = 6'b000000;
   defparam od4.NEG_TRIGGER = 1'b0;

	SB_IO
     od5(
        .PACKAGE_PIN (cam_dat[5]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[5]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[5])
        );
   defparam od5.PIN_TYPE = 6'b000000;
   defparam od5.NEG_TRIGGER = 1'b0;

	SB_IO
     od6(
        .PACKAGE_PIN (cam_dat[6]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[6]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[6])
        );
   defparam od6.PIN_TYPE = 6'b000000;
   defparam od6.NEG_TRIGGER = 1'b0;

	SB_IO
     od7(
        .PACKAGE_PIN (cam_dat[7]),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_dat_internal[7]),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_dat_internal[7])
        );
   defparam od7.PIN_TYPE = 6'b000000;
   defparam od7.NEG_TRIGGER = 1'b0;

	SB_IO
     odhref(
        .PACKAGE_PIN (cam_href),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_href_internal),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_href_internal)
        );
   defparam odhref.PIN_TYPE = 6'b000000;
   defparam odhref.NEG_TRIGGER = 1'b0;

	SB_IO
     odvsync(
        .PACKAGE_PIN (cam_vsync),
        .LATCH_INPUT_VALUE (0),
        .CLOCK_ENABLE (1),
        .INPUT_CLK (cam_xclk_internal_buf),
        .OUTPUT_CLK (0),
        .OUTPUT_ENABLE (0),
        .D_OUT_0 (),
        .D_OUT_1 (),
        .D_IN_0 (cam_vsync_internal),
        .D_IN_1 ()
//        .D_IN_0 (),
//        .D_IN_1 (cam_vsync_internal)
        );
   defparam odvsync.PIN_TYPE = 6'b000000;
   defparam odvsync.NEG_TRIGGER = 1'b0;

	assign cam_xclk_internal_buf = cam_xclk_internal;


endmodule // verilog_top

`endif //TOP_TOP_V
