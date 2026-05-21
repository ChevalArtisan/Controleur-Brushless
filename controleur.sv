module bldc_controller #(
    parameter int FREQUENCY = 1000000;
    parameter int MIN_DUTY_PERCENT = 50;

) (
    input logic RST,CLK, TOUR_IN,
    input logic [7:0] DUTY,
    output logic U,V,W,Un,Vn,Wn,TOUR_OUT,
    output logic [15:0] VITESSE 


);
    integer clk_count=0;
    integer pwm_count=0;
    logic[2:0] state <= 3'b 000;
    logic pwm_out<=0;


    always @(posedge CLK or posedge TOUR_IN ) begin : CPT_TOUR
        if (RST) begin
            clk_count<=0;
        end else begin
            if (TOUR) begin
                //TODO calcul vitesse 
                clk_count<=0;
            end else begin
                clk_count<=clk_count+1;
            end
        end
    end

    always @( posedge CLK ) begin : RAMP
        //TODO transfo duty into current_duty en suivant le principe de ramp
    end

    always @( posedge CLK ) begin : PWM_CPT
        if (RST) begin
            pwm_count<=0;
        end else begin
            pwm_count<=pwm_count+1;
            if (pwm_count>=MAX_CPT)begin
                pwm_count<=0;
            end
        end
        
    end
    

    always @(posedge CLK) begin :STATE_MACHINE
        if(RST) begin
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
            
            case (state)
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

    always @(posedge CLK) begin : PWM_OUT
        if(RST) begin
            pwm_out<= 1'b 0;
        end else begin
            if (pwm_count<current_duty) begin
                pwm_out<=1'b 1;
            end else begin
                pwm_out<= 1'b 0;
            end 
        end
    end
endmodule