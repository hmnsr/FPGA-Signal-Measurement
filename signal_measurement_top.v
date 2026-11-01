module signal_measurement_top #(parameter integer GATE_CYCLES = 50000000)(
	input wire clk_50,
	input wire reset,
	input wire signal_in,
	
	output reg [31:0] frequency_hz,
	output reg [31:0] period_cycles,
	output reg [31:0] high_cycles,
	output reg [6:0] duty_cycle_percent
);

	// sync external input to the FPGA clock
	reg signal_meta;
	reg signal_sync;
	reg signal_sync_d;
	
	// count clock cycles and input rising edges
	reg [31:0] gate_counter;
	reg [31:0] pulse_count;
	
	// count period and high-time
	reg [31:0] period_counter;
	reg [31:0] high_counter;
	
	// was a previous rising edge detected
	reg have_previous_rising;
	
	// detect a rising and falling edge
	wire rising_edge = signal_sync & ~signal_sync_d;
	wire falling_edge = ~signal_sync & signal_sync_d;
	
	// Duty = (high_cycles * 100) / period_cycles. A 39 step restoring divider
	// keeps the divide outside the 20 ns clock-to-clock path
	localparam integer DIV_BITS = 39;
	
	reg div_busy;
	reg [5:0] div_steps;
	reg [DIV_BITS-1:0] div_num;
	
	reg [31:0] div_den;
	reg [31:0] div_rem;
	
	wire [38:0] high_cycles_ext = {7'd0, high_cycles};
	
	wire [DIV_BITS-1:0] duty_numerator = (high_cycles_ext << 6) + (high_cycles_ext << 5) + (high_cycles_ext << 2);
	
	wire [32:0] div_rem_shift = {div_rem, div_num[DIV_BITS-1]};
	wire div_ge = (div_rem_shift >= {1'b0, div_den});
	wire [32:0] div_rem_next = div_ge ? (div_rem_shift - {1'b0, div_den}) : div_rem_shift;
	wire [DIV_BITS-1:0] div_quot_next = {div_num[DIV_BITS-2:0], div_ge};
	
	always @(posedge clk_50) begin
		if (reset) begin
			signal_meta <= 1'b0;
			signal_sync <= 1'b0;
			signal_sync_d <= 1'b0;
			
			gate_counter <= 32'd0;
			pulse_count <= 32'd0;
			frequency_hz <= 32'd0;
			
			period_counter <= 32'd0;
			high_counter <= 32'd0;
			period_cycles <= 32'd0;
			high_cycles <= 32'd0;
			duty_cycle_percent <= 7'd0;
			
			have_previous_rising <= 1'b0;
			
			div_busy <= 1'b0;
			div_steps <= 6'd0;
			div_num <= {DIV_BITS{1'b0}};
			div_den <= 32'd1;
			div_rem <= 32'd0;
		end else begin
			// syncing
			signal_meta <= signal_in;
			signal_sync <= signal_meta;
			signal_sync_d <= signal_sync;
			
			// frequency measurement
			if (gate_counter == GATE_CYCLES - 1) begin
				gate_counter <= 32'd0;
				
				// include an edge at the window boundary
				frequency_hz <= pulse_count + (rising_edge ? 32'd1 : 32'd0);
				
				pulse_count <= 32'd0;
			end else begin
				gate_counter <= gate_counter + 1'b1;
				
				if (rising_edge)
					pulse_count <= pulse_count + 1'b1;
			end
			
			// period measurement
			if (rising_edge) begin
				if (have_previous_rising) begin
					period_cycles <= period_counter + 1'b1; // include final clock cycle
					
					if (!div_busy && period_counter != 32'hffffffff) begin
						div_busy <= 1'b1;
						div_steps <= 6'd39;
						div_num <= duty_numerator;
						div_den <= period_counter + 1'b1;
						div_rem <= 32'd0;
					end
				end
				
				period_counter <= 32'd0;
				have_previous_rising <= 1'b1;
			end else begin
				period_counter <= period_counter + 1'b1;
			end
			
			if (div_busy) begin
				div_num <= div_quot_next;
				div_rem <= div_rem_next[31:0];
				
				if (div_steps == 6'd1) begin
					div_busy <= 1'b0;
					div_steps <= 6'd0;
					
					if (|div_quot_next[DIV_BITS-1:7] || div_quot_next[6:0] > 7'd100)
						duty_cycle_percent <= 7'd100;
					else
						duty_cycle_percent <= div_quot_next[6:0];
				end else begin
					div_steps <= div_steps - 1'b1;
				end
			end
			
			// high-time measurement
			if (signal_sync) begin
				high_counter <= high_counter + 1'b1;
			end
			
			if (falling_edge) begin
				high_cycles <= high_counter;
				high_counter <= 32'd0;
			end
		end
	end
endmodule