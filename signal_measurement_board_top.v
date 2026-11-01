// DE10-Lite wrapper for the signal measurement instrument.
//
// Switches
//   SW[1:0]  display select: 00 frequency, 01 period, 10 HIGH time, 11 duty
//   SW[3:2]  test generator frequency: 00 1 kHz, 01 10 kHz, 10 100 kHz, 11 1 MHz
//   SW[5:4]  test generator duty:      00 50 %, 01 25 %, 10 75 %, 11 12.5 %
//   SW[6]    0 = measure the SIGNAL_IN pin (Arduino D3)
//            1 = measure the internal test generator (no wire needed)
// Pins (Arduino header, 3.3 V logic only)
//   TEST_OUT  = Arduino D2 (PIN_AB7): test generator output
//   SIGNAL_IN = Arduino D3 (PIN_AB8): measurement input
// Loopback test: jumper D2 to D3 with SW[6] = 0.
module signal_measurement_board_top (
	input wire MAX10_CLK_50,
	input wire KEY0,
	input wire [6:0] SW,
	input wire SIGNAL_IN,
	output wire TEST_OUT,
	output wire [6:0] HEX0,
	output wire [6:0] HEX1,
	output wire [6:0] HEX2,
	output wire [6:0] HEX3,
	output wire [6:0] HEX4,
	output wire [6:0] HEX5,
	output wire [9:0] LEDR
);
	wire reset = ~KEY0;
	wire [31:0] frequency_hz, period_cycles, high_cycles;
	wire [6:0] duty_cycle_percent;
	reg [31:0] display_value;
	reg [39:0] bcd_value;
	integer i;
	integer j;
	
	// built-in test signal
	wire test_signal;
	test_signal_gen generator (
		.clk_50(MAX10_CLK_50),
		.reset(reset),
		.freq_sel(SW[3:2]),
		.duty_sel(SW[5:4]),
		.sig_out(test_signal)
	);
	assign TEST_OUT = test_signal;
	
	// choose what gets measured, since SW[6] is slow and the measurement module syncs this before use
	wire measured_signal = SW[6] ? test_signal : SIGNAL_IN;
	
	signal_measurement_top measurement (
		.clk_50(MAX10_CLK_50),
		.reset(reset),
		.signal_in(measured_signal),
		.frequency_hz(frequency_hz),
		.period_cycles(period_cycles),
		.high_cycles(high_cycles),
		.duty_cycle_percent(duty_cycle_percent)
	);
	
	always @* begin
		case (SW[1:0])
			2'b00: display_value = frequency_hz;
			2'b01: display_value = period_cycles;
			2'b10: display_value = high_cycles;
			2'b11: display_value = {25'd0, duty_cycle_percent};
			default: display_value = 32'd0;
		endcase
		
		// convert 32-bit reading into ten decimal digits
		bcd_value = 40'd0;
		for (i = 31; i >= 0; i = i - 1) begin
			for (j = 0; j < 10; j = j + 1)
				if (bcd_value[j*4 +: 4] >= 4'd5)
					bcd_value[j*4 +: 4] = bcd_value[j*4 +: 4] + 4'd3;
			bcd_value = {bcd_value[38:0], display_value[i]};
		end
	end
	
	hex7seg digit0 (.value(bcd_value[3:0]),	.seg(HEX0));
	hex7seg digit1 (.value(bcd_value[7:4]),	.seg(HEX1));
	hex7seg digit2 (.value(bcd_value[11:8]),	.seg(HEX2));
	hex7seg digit3 (.value(bcd_value[15:12]),	.seg(HEX3));
	hex7seg digit4 (.value(bcd_value[19:16]),	.seg(HEX4));
	hex7seg digit5 (.value(bcd_value[23:20]),	.seg(HEX5));
	
	// LEDR0: value exceeds six displayed decimal digits
	assign LEDR[0] = |bcd_value[39:24];
	// LEDR1: measuring internal test generator
	assign LEDR[1] = SW[6];
	assign LEDR[9:2] = 8'b0;
endmodule