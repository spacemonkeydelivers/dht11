`include "dht11.v"

`timescale 100ns/100ns

module dht11tb();

	
	reg clk = 0;
	always #1 clk = ~clk;

	reg out = 0;
	reg data_reg = 1;
	inout data;
	assign data = (out == 0) ? 1'bZ : data_reg;

	pullup(data);
	dht11 DHT(
		.data_io(data)
	);
	
	
	initial
	begin
		#57; // wait for 5.7us
		out = 1; // master controls the line
		#15; // wait for 1.5us
		data_reg = 0; // switch to req_lo
		#185; // wait for 18.5us
		data_reg = 1; // switch to initial
		#40; // wait for 4us
		data_reg = 0; // switch to req_lo
		#183; //wait for 18.3us
		data_reg  = 1; // switch to req_hi
		#390; // wait for 39us
		data_reg = 0; // switch to req_low
		#290; // wait for 29us
		data_reg = 1; // switch to req_hi
		out = 0; // release data line
	end
	
	initial
	begin
		#50000;
		$finish;
	end

endmodule
