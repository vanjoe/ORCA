
module verilog_top
  (
   //spi
   spi_mosi,
   spi_miso,
   spi_ss,
   spi_sclk,

   //uart
   txd ,
   rxd ,

   //led
   r_out,
   g_out,
   b_out

   );
   output      spi_mosi;
   input       spi_miso;
   output      spi_ss  ;
   output      spi_sclk;
   output 		txd ;
   input 		rxd ;
   output r_out;
   output g_out;
   output b_out;


	wire r,g,b;

	vhdl_top
	  sub_top (
				  .spi_mosi(spi_mosi),
				  .spi_miso(spi_miso),
				  .spi_ss(spi_ss),
				  .spi_sclk(spi_sclk),

				  //uart	 //uart
				  .txd (txd ),
				  .rxd (rxd ),

				  //led	 //led
				  .r_out (r),
				  .g_out (g),
				  .b_out (b)
				  );

	SB_RGBA_DRV RGBA_DRIVER (
									 .CURREN(1),
									 .RGBLEDEN(1),
									 .RGB0PWM(r),
									 .RGB1PWM(g),
									 .RGB2PWM(b),
									 .RGB0(r_out),
									 .RGB1(g_out),
									 .RGB2(b_out)
									 );
	defparam RGBA_DRIVER.CURRENT_MODE = "0b0";
	defparam	RGBA_DRIVER.RGB0_CURRENT =	"0b111111";
	defparam	RGBA_DRIVER.RGB1_CURRENT =	"0b111111" ;
	defparam	RGBA_DRIVER.RGB2_CURRENT =	"0b111111";

endmodule
