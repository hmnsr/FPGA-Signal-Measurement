module test_signal_gen (
	input wire clk_50,
	input wire reset,
	input wire [1:0] freq_sel,
	input wire [1:0] duty_sel,
	output reg sig_out
);
	// switches are asynchronous, two-flop sync the selections
	reg [3:0] sel_meta, sel_sync;
	always @(posedge clk_50) begin
		sel_meta <= {duty_sel, freq_sel};
		sel_sync <= sel_meta;
	end
	
	reg [15:0] period, high_t, cnt;
	
	always @* begin
		case (sel_sync[1:0])
			2'd0: period = 16'd50000;
			2'd1: period = 16'd5000;
			2'd2: period = 16'd500;
			default: period = 16'd50;
		endcase
		
		case (sel_sync[3:2])
			2'd0: high_t = period >> 1;
			2'd1: high_t = period >> 2;
			2'd2: high_t = period - (period >> 2);
			default: high_t = period >> 3;
		endcase
	end
	
	always @(posedge clk_50) begin
		if (reset) begin
			cnt <= 16'd0;
			sig_out <= 1'b0;
		end else begin
			// use >= (not ==) so a switch change can never leave cnt above period
			cnt <= (cnt >= period - 16'd1) ? 16'd0 : cnt + 16'd1;
			sig_out <= (cnt < high_t);
		end
	end
endmodule