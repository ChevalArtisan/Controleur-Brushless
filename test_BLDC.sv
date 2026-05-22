module test_vitesse;
	
	logic clk, rst;
	logic unsigned [7:0] duty;
	logic unsigned [15:0] max_cpt;
	logic unsigned [15:0] current_duty;

	vitesse_ramp test(.clk(clk),
		.rst(rst),
		.duty(duty),
		.max_cpt(max_cpt),
		.current_duty(current_duty));

	initial clk = 0;
	always clk = #500ns ~clk;

	initial begin
		rst = 1;
		#1ms
		rst = 0;
		duty = 8'b11000000;
		max_cpt = 16'b 0100111000100000;
		#2s


		$finish;
	end


endmodule
