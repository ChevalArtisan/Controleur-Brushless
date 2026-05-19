module controleur #(parameter CLK_Freq = 1000000,
		parameter PHASE = 50,
		parameter MIN_DUTY_PERCENT = 50)(clk,rst,duty,en,U,Un,V,Vn,W,Wn);

	input clk;
	input rst;
	input [7:0] duty;
	input en;
	output U;
	output Un;
	output V;
	output Vn;
	output W;
	output Wn;

reg U;
reg Un;
reg V;
reg Vn;
reg W;
reg Wn;

	integer MAX_CPT = CLK_Freq / PHASE;
    integer compteur = 0;
    integer etape = 7;
    integer etape_moteur = 7;
    integer res = MAX_CPT / 2;
    integer res_actuel = 0;

    integer temp_compteur;
    integer temp_vitesse;

    //Controleur
    always @(posedge clk)
        begin
            if (rst == 1) begin
                etape <= 0;
            end

            res <= (MAX_CPT * $rtoi($bitstoreal(duty))) / 256;

            //Min 50%
            if (((100 * $rtoi($bitstoreal(duty))) / 256) < MIN_DUTY_PERCENT) begin
                res <= (MAX_CPT * MIN_DUTY_PERCENT) / 100;
            end


            if ((compteur % MAX_CPT) == 0) begin
                etape <= (etape + 1) % 6;
            end
        end 

	
	//Vitesse
    always @(posedge clk)
        begin
            if (rst == 1) begin
                etape <= 0;
            end

            if (compteur % MAX_CPT == 0) begin //Mise à jour à chaque changement de phase


                if (abs(res_actuel - res) <  (MAX_CPT / 15)) begin   //Si la différence entre le nouveau res et le res_actuel est inférieur à 7% de MAX_CPT, on lui attribue res
                    temp_vitesse = res;
                end
                    
                else if (res_actuel < res) begin
                    temp_vitesse = res_actuel + (MAX_CPT / 20);          //Accelère de 5% de MAX_CPT
                end

                else if (res_actuel > res) begin 
                    temp_vitesse = res_actuel - (MAX_CPT / 20);          //Décélère de 5% de MAX_CPT          
                end;


            end

            res_actuel <= temp_vitesse;
             
        end

	//compteur
    always @(posedge clk)
        begin

            if ((compteur >= MAX_CPT) || (rst == 1)) begin
                temp_compteur = 0;
            end 
            else begin
                temp_compteur = compteur + 1;
            end

            compteur <= temp_compteur;
        end

	//PWM
    always @(posedge clk)
        begin
            etape_moteur = 0;

            if (compteur < res_actuel) begin
                etape_moteur = etape;
            end
        end

	//Machine à état
    always @(posedge clk) begin
    if(etape_moteur == 1) begin
      U <= 1'b 1;
      Un <= 1'b 0;
      V <= 1'b 0;
      Vn <= 1'b 1;
      W <= 1'b 0;
      Wn <= 1'b 0;
    end
    else if(etape_moteur == 2) begin
      U <= 1'b 1;
      Un <= 1'b 0;
      V <= 1'b 0;
      Vn <= 1'b 0;
      W <= 1'b 0;
      Wn <= 1'b 1;
    end
    else if(etape_moteur == 3) begin
      U <= 1'b 0;
      Un <= 1'b 0;
      V <= 1'b 1;
      Vn <= 1'b 0;
      W <= 1'b 0;
      Wn <= 1'b 1;
    end
    else if(etape_moteur == 4) begin
      U <= 1'b 0;
      Un <= 1'b 1;
      V <= 1'b 1;
      Vn <= 1'b 0;
      W <= 1'b 0;
      Wn <= 1'b 0;
    end
    else if(etape_moteur == 5) begin
      U <= 1'b 0;
      Un <= 1'b 1;
      V <= 1'b 0;
      Vn <= 1'b 0;
      W <= 1'b 1;
      Wn <= 1'b 0;
    end
    else if(etape_moteur == 6) begin
      U <= 1'b 0;
      Un <= 1'b 0;
      V <= 1'b 0;
      Vn <= 1'b 1;
      W <= 1'b 1;
      Wn <= 1'b 0;
    end
    else begin
      U <= 1'b 0;
      Un <= 1'b 0;
      V <= 1'b 0;
      Vn <= 1'b 0;
      W <= 1'b 0;
      Wn <= 1'b 0;
    end
  end



	







endmodule