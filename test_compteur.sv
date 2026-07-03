module test_compteur;

	logic clk, rst, acceleration;
	logic unsigned [2:0] etat;
	logic unsigned [15:0] max_cpt;
	logic unsigned [7:0] compteur;

	compteur M2(.clk(clk),
		.rst(rst),
		.max_cpt(max_cpt),
		.compteur(compteur),
		.acceleration(acceleration),
		.etat(etat));

	initial clk = 0;
	always clk = #500ns ~clk;


	initial begin
		rst = 1;
		#1ms
		rst = 0;
		max_cpt = 16'b 0100111000100000; //20 000
		#2s

		#1ms
		max_cpt = 16'b 0010011100010000; //10 000
		#2s


		#1ms
		max_cpt = 16'b 0111010100110000; //30 000
		#2s

		$finish;
	end


endmodule
