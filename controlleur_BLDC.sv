module controleur_bldc #(  //Rassemble tout les modules et gère les entrées/sorties
)(
	input clk,
	input rst,
	input [7:0] duty,
	input tour,
	output reg U, V, W, Un, Vn, Wn,
	output reg tour_complet,
	output reg [15:0] vitesse_instantanee
);

	wire [15:0] max_cpt;
	wire [15:0] compteur;
	wire [15:0] current_duty;
	wire [2:0] etat;
	wire pwm_out;

	assign tour_complet = tour;
 

	vitesse_ramp M1(.clk(clk),
		.rst(rst),
		.duty(duty),
		.max_cpt(max_cpt),
		.current_duty(current_duty));

	compteur M2(.clk(clk),
		.rst(rst),
		.max_cpt(max_cpt),
		.compteur(compteur),
		.etat(etat));

	compte_tour M3(.clk(clk),
		.rst(rst),
		.tour(tour),
		.max_cpt(max_cpt),
		.vitesse_instantanee(vitesse_instantanee));

	pwm M4(.clk(clk),
		.rst(rst),
		.compteur(compteur),
		.current_duty(current_duty),
		.pwm_out(pwm_out));

	machine_a_etat M5(.clk(clk),
		.rst(rst),
		.pwm_out(pwm_out),
		.etat(etat),
		.U(U),
		.V(V),
		.W(W),
		.Un(Un),
		.Vn(Vn),
		.Wn(Wn));

endmodule


module vitesse_ramp #( //Prend en entrée le duty et donne compteur_interne <= compteur_interne + 1; la vitesse interne lissée
    parameter int FREQUENCY = 1000000,
    parameter int MIN_DUTY_PERCENT = 50
)(
    input clk,
    input rst,
    input unsigned [7:0] duty,
    input [15:0] max_cpt,
    output reg unsigned [15:0] current_duty
);
    int duty_calcul;
    int compteur_interne = 0;

    always_ff @(posedge clk) begin

    if (rst) begin
        current_duty <= 16'b0000000000000000;
        compteur_interne <= 0;

    end else begin

        duty_calcul =  (max_cpt / 256) * duty ; //(duty / 256) * max_cpt;


        if (compteur_interne >= FREQUENCY / 5) begin //MAJ 5 fois par seconde

            compteur_interne <= 0;

            if (duty_calcul < current_duty) begin //Ralentir
                if ((current_duty - duty_calcul) < (max_cpt / 15)) begin
                    current_duty <= duty_calcul;

                end else begin
                    current_duty <= current_duty - (max_cpt / 20);
                end
            end


            else begin //Accelerer

                if ((duty_calcul - current_duty) < (max_cpt / 15)) begin
                    current_duty <= duty_calcul;

                end else begin
                    current_duty <= (max_cpt / 20) + current_duty;
                end
            end

            if (current_duty < MIN_DUTY_PERCENT) begin //Min 50%
                current_duty <= (max_cpt / 2);
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
    output reg [15:0] compteur,
    output reg [2:0] etat
);

    always_ff @(posedge clk) begin
        if (rst) begin
            compteur <= 16'b0000000000000000;
            etat <= 3'b000;

        end else begin
            if (compteur >= int'(max_cpt)) begin  //Max_cpt = 1/6 tour = 1 phase, 1 tour = 6 phases
                compteur <= 0;
                etat <= (etat + 1) % 6;

            end else begin                
                compteur <= compteur + 1;
            end
        end
    end
endmodule


module compte_tour #(
    parameter real FREQUENCY = 1000000.0 // 1 MHz par défaut
)(
    input clk,
    input rst,
    input tour,
    output reg [15:0] max_cpt,
    output reg [15:0] vitesse_instantanee
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
	input [15:0] compteur,
	input [15:0] current_duty,
	output reg pwm_out
);

    always @(posedge clk) begin
        if(rst) begin
            pwm_out<= 1'b 0;

        end else begin

            if (compteur < current_duty) begin
                pwm_out<=1'b 1;

            end else begin
                pwm_out<= 1'b 0;
            end 
        end
    end
endmodule


module machine_a_etat #(	//Donne l'état des broches en fonction de la phase et du pwm
)(
	input clk,
	input rst,
	input pwm_out,
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
                3'b000: begin U <= pwm_out; Vn <= 1'b1; end
                3'b001: begin U <= pwm_out; Wn <= 1'b1; end
                3'b010: begin V <= pwm_out; Wn <= 1'b1; end
                3'b011: begin V <= pwm_out; Un <= 1'b1; end
                3'b100: begin W <= pwm_out; Un <= 1'b1; end
                3'b101: begin W <= pwm_out; Vn <= 1'b1; end
                default: ; 
            endcase
        end
        //TODO
    end


endmodule
