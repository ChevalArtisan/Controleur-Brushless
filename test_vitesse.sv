module test_vitesse;
	
	logic clk, rst;
	logic unsigned [7:0] duty;
	logic unsigned [7:0] current_duty;

	vitesse_ramp test(.clk(clk),
		.rst(rst),
		.duty(duty),
		.current_duty(current_duty));

	initial clk = 0;
	always clk = #500ns ~clk;

	initial begin
		rst = 1;
		#1ms
		rst = 0;
		duty = 8'b11000000; //75%
		#2s

		duty = 8'b11111111; //100%
		#2s

		duty = 8'b01111111; //50%
		#2s


		$finish;
	end


endmodule