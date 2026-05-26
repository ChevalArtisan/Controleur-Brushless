module test_cpt_tour;
    logic clk, rst, tour;
    wire [15:0] max_cpt;
    wire [15:0] vitesse_instantanee;

    // Correction : Ajout de la connexion .tour
    compte_tour #( .FREQUENCY(1000000.0) ) test (
        .clk(clk),
        .rst(rst),
        .tour(tour),
        .max_cpt(max_cpt),
        .vitesse_instantanee(vitesse_instantanee)
    );

    // Génération de l'horloge (1 MHz = période 1us)
    initial clk = 0;
    always #500ns clk = ~clk;

    initial begin
        // Initialisation
        rst = 1;
        tour = 0;
        #2us;
        rst = 0;
        
        // Simulation d'un tour (durée 20ms)
        #10us;
        tour = 1; #2us; tour = 0; // Front montant
        #20ms;
        tour = 1; #2us; tour = 0; // Deuxième front -> Calcul effectué
        
        // Simulation d'un tour plus rapide (10ms)
        #10ms;
        tour = 1; #2us; tour = 0;

        #1ms;
        $display("Max CPT: %d, Vitesse: %d tour/s", max_cpt, vitesse_instantanee);
        $finish;
    end

endmodule