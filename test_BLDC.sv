module test_BLDC;
	
	logic clk, rst, tour;
	logic unsigned [7:0] duty;
	logic U,V,W,Un,Vn,Wn;
	logic tour_complet;
	logic unsigned [15:0] vitesse_instantanee;

	controleur_bldc test(
		.clk(clk),
		.rst(rst),
		.duty(duty),
		.U(U),
		.V(V),
		.W(W),
		.Un(Un),
		.Vn(Vn),
		.Wn(Wn),
		.tour(tour),
		.tour_complet(tour_complet),
		.vitesse_instantanee(vitesse_instantanee));

	initial clk = 0;
	always clk = #500ns ~clk;

	initial begin
		rst = 1;
		#1ms
		rst = 0;
		duty = 8'b11000000; //75%
		tour = 0;
		#10ms
		tour = 1;
		#10ms
		tour = 0;
		#10ms
		tour = 1;
		#10ms
		tour = 0;
		#10ms
		tour = 1;
		#10ms
		tour = 0;
		#10ms
		tour = 1;
		#10ms
		tour = 0;
		#10ms
		tour = 1;	
		#2s


		$finish;
	end


endmodule
