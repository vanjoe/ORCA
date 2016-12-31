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
	input 		spi_mosi;
	output 		spi_miso;
	output 		spi_ss  ;
	output 		spi_sclk;
	inout 		sccb_scl;
	inout 		sccb_sda;
	output 		txd    ;

	wire [7:0]	cma_dat_internal;
	wire 			cam_xclk_internal;


	top vhdl_top
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
		.sccb_sda(sccb_sda)
		);



	assign cam_dat_internal = cam_dat;
	assign cam_xclk = cam_xclk;

endmodule // verilog_top

`endif //TOP_TOP_V
