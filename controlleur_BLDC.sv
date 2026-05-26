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


module vitesse_ramp #( //Prend en entrée le duty et donne aux autres modules la vitesse interne lissée
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

        duty_calcul = (duty / 256) * max_cpt;

        if (compteur_interne >= FREQUENCY / 5) begin

            compteur_interne <= 0;

            if (duty_calcul < int'(current_duty)) begin //Ralentir
                if ((current_duty - duty_calcul) < (max_cpt / 15)) begin
                    current_duty <= duty_calcul;

                end else begin
                    current_duty <= duty_calcul - (max_cpt / 20);
                end
            end


            else begin //Accelerer

                if ((duty_calcul - current_duty) < (max_cpt / 15)) begin
                    current_duty <= duty_calcul;

                end else begin
                    current_duty <= duty_calcul + (max_cpt / 20);
                end
            end

            if (int'(current_duty) < MIN_DUTY_PERCENT) begin //Min 50%
                current_duty <= 16'b1000000000000000;
            end

        end
    end

    compteur_interne <= compteur_interne + 1;

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
            if (compteur >= (int'(max_cpt) / 6)) begin  //Max_cpt = 1 tour, 1 tour = 6 phases
                compteur <= 16'b0000000000000000;
                etat <= (etat + 1) % 6;

            end else begin                
                compteur <= compteur + 1;
            end
        end
    end
endmodule


module compte_tour #(	//Compte les tick entre 2 tours et modifie max_cpt pour que les 6 phases tiennent sur un tour complet
    parameter real FREQUENCY = 1000000
)(
    input clk,
    input rst,
    input tour,
    output reg [15:0] max_cpt,
    output reg [15:0] vitesse_instantanee
);
    int compte = 0;
    logic actif = 0; 

    always_ff @(posedge rst) begin
        compte <= 0;
        max_cpt <= 16'b0000000000000000;
        vitesse_instantanee <= 16'b0000000000000000;
    end

    always_ff @(posedge tour) begin
        if (actif == 0) begin
            compte <= 0;
            actif <= 1;
        
        end else begin
            max_cpt <= compte;
            vitesse_instantanee <= (FREQUENCY / compte);  //nb tour/sec
            actif <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if(actif == 1) begin
            compte <= compte + 1;
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
                3'b001: begin U <= pwm_out; Vn <= 1'b1; end
                3'b101: begin U <= pwm_out; Wn <= 1'b1; end
                3'b100: begin V <= pwm_out; Wn <= 1'b1; end
                3'b110: begin V <= pwm_out; Un <= 1'b1; end
                3'b010: begin W <= pwm_out; Un <= 1'b1; end
                3'b011: begin W <= pwm_out; Vn <= 1'b1; end
                default: ; 
            endcase
        end
        //TODO
    end


endmodule
