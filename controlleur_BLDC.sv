module controleur_bldc #(  //Rassemble tout les modules et gère les entrées/sorties
)(
	input rst,
	input [7:0] duty,
	input tour,
	output reg U, V, W, Un, Vn, Wn,
	output reg tour_complet,
	output reg [11:0] vitesse_instantanee
);

	reg clk;
	wire [15:0] max_cpt;
	wire [7:0] compteur;
	wire [7:0] current_duty;
	wire [2:0] etat;
	wire acceleration;
	wire pwm_out;
	wire pwm_acceleration;

	assign tour_complet = tour;

	initial clk = 0;
	always clk = #500ns ~clk; //Horloge (1 000 000 Hz)
 

	vitesse_ramp M1(.clk(clk),
		.rst(rst),
		.duty(duty),
		.current_duty(current_duty));

	compteur M2(.clk(clk),
		.rst(rst),
		.max_cpt(max_cpt),
		.compteur(compteur),
		.etat(etat),
        	.acceleration(acceleration));

	compte_tour M3(.clk(clk),
		.rst(rst),
		.tour(tour),
		.max_cpt(max_cpt),
		.vitesse_instantanee(vitesse_instantanee));

	pwm M4(.clk(clk),
		.rst(rst),
		.compteur(compteur),
		.acceleration(acceleration),
		.current_duty(current_duty),
		.pwm_out(pwm_out),
		.pwm_acceleration(pwm_acceleration));

	machine_a_etat M5(.clk(clk),
		.rst(rst),
		.pwm_out(pwm_out),
		.pwm_acceleration(pwm_acceleration),
		.etat(etat),
		.U(U),
		.V(V),
		.W(W),
		.Un(Un),
		.Vn(Vn),
		.Wn(Wn));

endmodule


module vitesse_ramp #( //Prend en entr�e le duty et donne compteur_interne <= compteur_interne + 1; la vitesse interne liss�e
    parameter int FREQUENCY = 1000000,
    parameter int MIN_DUTY_PERCENT = 128
)(
    input clk,
    input rst,
    input unsigned [7:0] duty,
    output reg unsigned [7:0] current_duty
);
    int compteur_interne = 0;

    always_ff @(posedge clk) begin

    if (rst) begin
        current_duty <= 8'b00000000;
        compteur_interne <= 0;

    end else begin

        if (compteur_interne >= FREQUENCY / 100) begin //MAJ 50 fois par seconde

            compteur_interne <= 0;

            if ((duty < current_duty) && (current_duty > MIN_DUTY_PERCENT)) begin //Ralentir

                    current_duty <= current_duty - 1; // 

            end


            else if ((duty != current_duty) || (current_duty < MIN_DUTY_PERCENT)) begin //Accelerer
		
                    current_duty <= current_duty + 1; // 

            end

        end else begin 
		
		compteur_interne <= compteur_interne + 1;

	end
    end



    end
endmodule



module compteur #(	//Gère le compteur interne et incrémente les phases

)(
    	input clk,
    	input rst,
    	input [15:0] max_cpt,
    	output reg [7:0] compteur,
    	output reg [2:0] etat,
        output reg acceleration
);
	int compteur_interne = 0;

	reg A, B;

    	always_ff @(posedge clk) begin
        	if (rst) begin
            		compteur_interne <= 0;
            		etat <= 3'b000;
			compteur <= 8'b00000000;
			acceleration <= 1'b0;

        	end else begin
            		if (compteur_interne >= int'(max_cpt)) begin  //Max_cpt = 1/6 tour = 1 phase, 1 tour = 6 phases
                		compteur_interne <= 0;
                		etat <= (etat + 1) % 6;
            		end else begin                
				compteur_interne <= compteur_interne + 1;
                	end

			compteur <= compteur + 1;

			acceleration <= ((etat % 2) == 0) ^ (compteur_interne < (int'(max_cpt) / 2)); //Phase d�cal�e de 1/2 = etat%2 XOR compteur_interne < phase/2
            	end
    	end
endmodule


module compte_tour #(
    parameter int FREQUENCY = 1000000 // 1 MHz par défaut
)(
    input clk,
    input rst,
    input tour,
    output reg [15:0] max_cpt,
    output reg [11:0] vitesse_instantanee
);
    int compte = 0;
    logic tour_z; // Pour détecter le front montant de 'tour'

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            compte <= 0;
            max_cpt <= 0;
            vitesse_instantanee <= 0;
            tour_z <= 0;
        end else begin
            tour_z <= tour; // Retard d'un cycle pour comparaison
            
            // Détection du front montant de 'tour'
            if (tour && !tour_z) begin
                max_cpt <= (compte / 6);
                if (compte > 0)
                    vitesse_instantanee <= (FREQUENCY / compte);
                compte <= 0; // On redémarre le compteur à chaque tour
            end else begin
                compte <= compte + 1;
            end
        end
    end
endmodule


module pwm #(	//En fonction du compteur et de la vitesse interne indique si on allume/éteint les broches
)(
	input clk,
	input rst,
	input [7:0] compteur,
	input acceleration,
	input [7:0] current_duty,
	output reg pwm_out,
	output reg pwm_acceleration
);
    int cd_pyramide;
    always @(posedge clk) begin
        if(rst) begin
            	pwm_out <= 1'b 0;
		pwm_acceleration <= 1'b 0;

        end else 
	        case (acceleration)
            		1'b 0:      cd_pyramide<=current_duty/2; 
	            	1'b 1:      cd_pyramide<=current_duty/4; 
	            	default:    cd_pyramide<=current_duty/4;

        	endcase

		//Gestion phase principale
	        if (compteur < current_duty) begin
	             	pwm_out<=1'b 1;
	        end else begin
	            	 pwm_out<= 1'b 0;
	        end
	
		//Gestion acc�leration pr�/post phase
		if (compteur < cd_pyramide) begin
	        	pwm_acceleration <=1'b 1;
	        end else begin
	            	pwm_acceleration <= 1'b 0;
	        end
	
                
    	end
endmodule


module machine_a_etat #(	//Donne l'état des broches en fonction de la phase et du pwm
)(
	input clk,
	input rst,
	input pwm_out,
	input pwm_acceleration,
	input [2:0] etat,
	output reg U,V,W,Un,Vn,Wn
);

    always @(posedge clk) begin

        if(rst) begin
            U <= 1'b 0;
            Un <= 1'b 0;
            V <= 1'b 0;
            Vn <= 1'b 0;
            W <= 1'b 0;
            Wn <= 1'b 0;

        end else begin
            U <= 1'b 0;
            Un <= 1'b 0;
            V <= 1'b 0;
            Vn <= 1'b 0;
            W <= 1'b 0;
            Wn <= 1'b 0;
            
            case (etat)
                3'b000: begin U <= pwm_out; Vn <= 1'b1; W <= pwm_acceleration; end
                3'b001: begin U <= pwm_out; Wn <= 1'b1; V <= pwm_acceleration; end
                3'b010: begin V <= pwm_out; Wn <= 1'b1; U <= pwm_acceleration; end
                3'b011: begin V <= pwm_out; Un <= 1'b1; W <= pwm_acceleration; end
                3'b100: begin W <= pwm_out; Un <= 1'b1; V <= pwm_acceleration; end
                3'b101: begin W <= pwm_out; Vn <= 1'b1; U <= pwm_acceleration; end
                default: ; 
            endcase
        end
    end


endmodule
