`include "dht11.v"

module dht11tb();

	
	reg clk = 0;
	always #1 clk = ~clk;

	reg out = 0;
	reg data_reg = 0;
	inout data;
	assign data = (out == 0) ? 1'bZ : data_reg;

	pullup(data);
	dht11 DHT(
		.data_io(data)
	);
	
	
	initial
	begin
		#5;
		out = 1;
		#2;
		data_reg = 0; // switch to req_lo
		#17;
		data_reg = 1; // switch to initial
		#4;
		data_reg = 0; // switch to req_lo
		#4;
		data_reg = 1; // switch to req_hi
		#4;
		data_reg = 0; // switch to req_low
		#4;
		data_reg = 1; // switch to req_hi
		#2;
		out = 0; // switch to resp_lo
		
	end
	
	initial
	begin
		#5000;
		$finish;
	end

endmodule
