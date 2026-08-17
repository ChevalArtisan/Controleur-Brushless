module top #(
)(
    input logic CLK_27MHZ,
    input logic RST,
	input [7:0] DUTY,
	input TOUR,
	output logic U, V, W, UN, VN, WN,
	output logic TOUR_COMPLET,
	output reg [11:0] VITESSE_INSTANTANEE
);


    //instanciation

    controleur_bldc #(
    ) controleur_bldc_inst (
        .clk_27 (CLK_27MHZ),
        .rst (RST),
        .duty (DUTY),
        .tour (TOUR),
        .U (U),
        .V (V),
        .W (W),
        .Un (UN),
        .Vn (VN),
        .Wn (WN),
        .tour_complet (TOUR_COMPLET),
        .vitesse_instantanee (VITESSE_INSTANTANEE)
    );


endmodule




    
