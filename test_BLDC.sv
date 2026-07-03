module test_BLDC;
	
	logic rst, tour;
	logic unsigned [7:0] duty;
	logic U,V,W,Un,Vn,Wn;
	logic tour_complet;
	logic unsigned [11:0] vitesse_instantanee;

	controleur_bldc test(
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


	initial begin
		tour = 0;

		for (int i = 0; i < 300; i++) begin	//300 tours à 50t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#20ms
			tour = 1;
		end

		for (int i = 0; i < 600; i++) begin	//600 tours à 100t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#10ms
			tour = 1;
		end

		for (int i = 0; i < 150; i++) begin	//150 tours à 25t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#40ms
			tour = 1;
		end

		$finish;

	end

	initial begin
		rst = 1;
		#1ms
		rst = 0;

		//////////////////////////////// 50t/s
		duty = 8'b11000000; //75%
		#2s

		duty = 8'b11111111; //100%
		#2s

		duty = 8'b01000000; //50%
		#2s

		//////////////////////////////// 100t/s
		duty = 8'b11000000; //75%
		#2s

		duty = 8'b11111111; //100%
		#2s

		duty = 8'b01000000; //50%
		#2s

		//////////////////////////////// 200t/s
		duty = 8'b11000000; //75%
		#2s

		duty = 8'b11111111; //100%
		#2s

		duty = 8'b01000000; //50%
		#2s


		$finish;
	end


endmodule
