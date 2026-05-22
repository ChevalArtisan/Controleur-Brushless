module vitesse_ramp #(
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



module compteur #(

)(
    input clk,
    input rst,
    input [15:0] max_cpt,
    output reg [15:0] compteur,
    output reg [2:0] etape
);

    always_ff @(posedge clk) begin
        if (rst) begin
            compteur <= 16'b0000000000000000;
            etape <= 3'b000;

        end else begin
            if (compteur >= (int'(max_cpt) / 6)) begin  //Max_cpt = 1 tour, 1 tour = 6 phases
                compteur <= 16'b0000000000000000;
                etape <= (etape + 1) % 6;

            end else begin                
                compteur <= compteur + 1;
            end
        end
    end
endmodule


module compte_tour #(
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
