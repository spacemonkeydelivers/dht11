
`define REQUEST_LOW_GE 18
`define REQUEST_HIGH_E 40
`define RESPONSE_LOW_E 54
`define RESPONSE_HIGH_E 80
`define DATA_0_LOW_E 54
`define DATA_0_HIGH_E 24
`define DATA_1_LOW_E 54
`define DATA_1_HIGH_E 70

`define STATE_INITIAL 0
`define STATE_REQUEST_LOW 1
`define STATE_REQUEST_HIGH 2
`define STATE_RESPONSE_LOW 3
`define STATE_RESPONSE_HIGH 4
`define STATE_DATA_SEND_LOW 5
`define STATE_DATA_SEND_HIGH 6

`define DUMP_FILE "./dht11.vcd"

module dht11(
	inout data_io
);

	reg clk = 0;
	reg [2:0] state = `STATE_INITIAL;
	reg out_data = 1;
	reg [6:0] counter = 0;
	reg [6:0] second_counter = 0;
	assign data_io = (state == `STATE_INITIAL || state == `STATE_REQUEST_HIGH || state == `STATE_REQUEST_LOW) ? 1'bZ : out_data;
	reg data_prev_state;
	reg data_cur_state;
	reg [39:0] dht_data = 40'b1000000000000000000000000000000000010110;
	
	always #1 clk = ~clk;
	
	initial
	begin
		$dumpfile(`DUMP_FILE);
		$dumpvars();
	end
	
	always @ (data_io)
	begin
		//$display("Data was %x %x now %x", data_prev_state, data_cur_state, data_io);
		if (state == `STATE_INITIAL && data_prev_state == 1 && data_io == 0)
		begin
			$display("From init to req_low with cnt %x", counter);
			counter <= 0;
			state = `STATE_REQUEST_LOW;
		end
	end
	
	always @ (posedge clk, negedge clk)
	begin
		counter <= counter + 1;
		data_cur_state <= data_io;
		data_prev_state <= data_cur_state;
		if (state == `STATE_REQUEST_LOW)
		begin
			if (counter < `REQUEST_LOW_GE)
			begin
				if (data_prev_state == 0 && data_cur_state == 1)
				begin
					$display("From req_low to init with cnt %x", counter);
					state = `STATE_INITIAL;
					counter <= 0;
				end
			end
			else
			begin
				$display("From req_low to req_high with cnt %x", counter);
				state = `STATE_REQUEST_HIGH;
				counter <= 0;
			end
		end
		else if (state == `STATE_REQUEST_HIGH)
		begin
			if (counter != `REQUEST_HIGH_E)
			begin
				if (data_prev_state == 1 && data_cur_state == 0)
				begin
					$display("From req_high to req_low with cnt %x", counter);
					state = `STATE_REQUEST_LOW;
					counter <= 0;
				end
			end
			else
			begin
				$display("From req_high to resp_low with cnt %x", counter);
				state = `STATE_RESPONSE_LOW;
				counter <= 0;
				out_data <= 0;
			end
		end
		else if (state == `STATE_RESPONSE_LOW)
		begin
			if (counter == `RESPONSE_LOW_E)
			begin
				$display("From resp_low to resp_high with cnt %x", counter);
				state = `STATE_RESPONSE_HIGH;
				counter <= 0;
				out_data <= 1;
			end
		end
		else if (state == `STATE_RESPONSE_HIGH)
		begin
			if (counter == `RESPONSE_HIGH_E)
			begin
				$display("From resp_high to data with cnt %x", counter);
				counter <= 0;
				second_counter <= 0;
				if (dht_data[0] == 0)
				begin
					state = `STATE_DATA_SEND_LOW;
					//$display("Next state SEND_LO 0");
				end
				else
				begin
					state = `STATE_DATA_SEND_HIGH;
					//$display("Next state SEND_HI 0");
				end
			end
		end
		else if (state == `STATE_DATA_SEND_LOW)
		begin
			if (second_counter == 40)
			begin
				$display("From send_data_low to init with cnt %x", counter);
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
					//$display("Next state SEND_HI %d", second_counter+1);
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
				$display("From send_data_high to init with cnt %x", counter);
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
					//$display("Next state SEND_LO %d", second_counter+1);
				end
				second_counter <= second_counter + 1;
				counter <= 0;
				out_data <= 0;
			end
		end
	end		
endmodule
