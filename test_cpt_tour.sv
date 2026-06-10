module test_cpt_tour;
    logic clk, rst, tour;
    wire [15:0] max_cpt;
    wire [11:0] vitesse_instantanee;

    // Correction : Ajout de la connexion .tour
    compte_tour #( .FREQUENCY(1000000.0) ) test (
        .clk(clk),
        .rst(rst),
        .tour(tour),
        .max_cpt(max_cpt),
        .vitesse_instantanee(vitesse_instantanee)
    );

    // G√©n√©ration de l'horloge (1 MHz = p√©riode 1us)
    initial clk = 0;
    always #500ns clk = ~clk;


    initial begin
		tour = 0;

		for (int i = 0; i < 300; i++) begin	//300 tours ‡ 50t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#20ms
			tour = 1;
		end

		for (int i = 0; i < 600; i++) begin	//600 tours ‡ 100t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#10ms
			tour = 1;
		end

		for (int i = 0; i < 150; i++) begin	//150 tours ‡ 25t/s (6 sec)
			tour = 1;
			#1us
			tour = 0;
			#40ms
			tour = 1;
		end

		$finish;

	end

endmodule