`ifndef OPEN_DRAIN_V
`define OPEN_DRAIN_V
module open_drain (user_pin, package_pin);

	input     package_pin;
	output 	 user_pin;


	SB_IO_OD
	 u(
		.PACKAGEPIN (package_pin),
		.LATCHINPUTVALUE (0),
		.CLOCKENABLE (0),
		.INPUTCLK (0),
		.OUTPUTCLK (0),
		.OUTPUTENABLE (0),
		.DOUT0 (),
		.DOUT1 (),
		.DIN0 (user_pin),
		.DIN1 ()

		);
	defparam u.PIN_TYPE = 6'b000001;
	defparam u.NEG_TRIGGER = 1'b0;

endmodule

`endif
