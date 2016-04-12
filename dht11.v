`timescale 100ns/100ns

`define REQUEST_LOW_GE 180
`define REQUEST_HIGH_E 400
`define RESPONSE_LOW_E 540
`define RESPONSE_HIGH_E 800
`define DATA_0_LOW_E 540
`define DATA_0_HIGH_E 240
`define DATA_1_LOW_E 540
`define DATA_1_HIGH_E 700

`define STATE_INITIAL 0
`define STATE_REQUEST_LOW 1
`define STATE_REQUEST_HIGH 2
`define STATE_RESPONSE_LOW 3
`define STATE_RESPONSE_HIGH 4
`define STATE_DATA_SEND_LOW 5
`define STATE_DATA_SEND_HIGH 6

`define DUMP_FILE "./dht11.vcd"

//`define DEBUG 1

module dht11(
	inout data_io
);

	reg clk = 0;
	reg clk_state = 0;
	reg [2:0] state = `STATE_INITIAL;
	reg out_data = 1;
	reg [10:0] counter = 0;
	reg [10:0] second_counter = 0;
	assign data_io = (state == `STATE_INITIAL || state == `STATE_REQUEST_HIGH || state == `STATE_REQUEST_LOW) ? 1'bZ : out_data;
	reg data_prev_state;
	reg data_cur_state;
	reg [39:0] dht_data = 40'b1000000000000000000000000000000000010110;
	
	always #1 clk = ~clk;
	
	always
	begin
		#1 clk_state = ~clk_state && (state != `STATE_INITIAL);
	end
	
	initial
	begin
		$dumpfile(`DUMP_FILE);
		$dumpvars();
	end
	
	always @ (data_io)
	begin
		if (state == `STATE_INITIAL && data_prev_state == 1 && data_io == 0)
		begin
`ifdef DEBUG		
			$display("From init to req_low with cnt %x", counter);
`endif			
			counter <= 0;
			state = `STATE_REQUEST_LOW;
		end
	end
	
	always @ (posedge clk, negedge clk)
	begin
		data_prev_state <= data_io;
	end
	
	always @ (posedge clk_state, negedge clk_state)
	begin
		counter <= counter + 1;
		
		if (state == `STATE_REQUEST_LOW)
		begin
			if (counter < `REQUEST_LOW_GE)
			begin
				if (data_prev_state == 0 && data_io == 1)
				begin
`ifdef DEBUG				
					$display("From req_low to init with cnt %x", counter);
`endif					
					state = `STATE_INITIAL;
					counter <= 0;
				end
			end
			else
			begin
				if (data_prev_state == 0 && data_io == 1)
				begin
`ifdef DEBUG				
					$display("From req_low to req_high with cnt %x", counter);
`endif					
					state = `STATE_REQUEST_HIGH;
					counter <= 0;
				end
			end
		end
		else if (state == `STATE_REQUEST_HIGH)
		begin
			if (counter != `REQUEST_HIGH_E)
			begin
				if (data_prev_state == 1 && data_io == 0)
				begin
`ifdef DEBUG
					$display("From req_high to req_low with cnt %x", counter);
`endif
					state = `STATE_REQUEST_LOW;
					counter <= 0;
				end
			end
			else
			begin
`ifdef DEBUG			
				$display("From req_high to resp_low with cnt %x", counter);
`endif
				state = `STATE_RESPONSE_LOW;
				counter <= 0;
				out_data <= 0;
			end
		end
		else if (state == `STATE_RESPONSE_LOW)
		begin
			if (counter == `RESPONSE_LOW_E)
			begin
`ifdef DEBUG
				$display("From resp_low to resp_high with cnt %x", counter);
`endif
				state = `STATE_RESPONSE_HIGH;
				counter <= 0;
				out_data <= 1;
			end
		end
		else if (state == `STATE_RESPONSE_HIGH)
		begin
			if (counter == `RESPONSE_HIGH_E)
			begin
`ifdef DEBUG
				$display("From resp_high to data with cnt %x", counter);
`endif				
				counter <= 0;
				second_counter <= 0;
				if (dht_data[0] == 0)
				begin
					state = `STATE_DATA_SEND_LOW;
				end
				else
				begin
					state = `STATE_DATA_SEND_HIGH;
				end
			end
		end
		else if (state == `STATE_DATA_SEND_LOW)
		begin
			if (second_counter == 40)
			begin
`ifdef DEBUG
				$display("From send_data_low to init with cnt %x", counter);
`endif
				state = `STATE_INITIAL;
			end
			if (counter < `DATA_0_LOW_E)
			begin
				out_data <= 0;
			end
			else if (counter >= `DATA_0_LOW_E && counter < `DATA_0_LOW_E + `DATA_0_HIGH_E)
			begin
				out_data <= 1;
			end
			else
			begin
				if (dht_data[second_counter+1] == 1)
				begin
					state = `STATE_DATA_SEND_HIGH;
				end
				second_counter <= second_counter + 1;
				counter <= 0;
				out_data <= 0;
			end
		end
		else if (state == `STATE_DATA_SEND_HIGH)
		begin
			if (second_counter == 40)
			begin
`ifdef DEBUG
				$display("From send_data_high to init with cnt %x", counter);
`endif				
				state = `STATE_INITIAL;
			end
			if (counter < `DATA_1_LOW_E)
			begin
				out_data <= 0;
			end
			else if (counter >= `DATA_1_LOW_E && counter < `DATA_1_LOW_E + `DATA_1_HIGH_E)
			begin
				out_data <= 1;
			end
			else
			begin
				if (dht_data[second_counter+1] == 0)
				begin
					state = `STATE_DATA_SEND_LOW;
				end
				second_counter <= second_counter + 1;
				counter <= 0;
				out_data <= 0;
			end
		end
	end		
endmodule
