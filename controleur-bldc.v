module bldc_controller #(
    parameter int FREQUENCY        = 1000000, 
    parameter int PHASE            = 50,
    parameter int DUTY_SIZE        = 8,
    parameter int MIN_DUTY_PERCENT = 50
)(
    input  logic                 RST, EN, CLK,
    output logic                 U, V, W,      // Positif
    output logic                 Un, Vn, Wn,   // Négatif
    input  logic [DUTY_SIZE-1:0] duty,         // Consigne
    input  logic                 Ha, Hb, Hc    // Capteurs Hall
);

    // --- Constantes et Signaux Internes ---
    localparam int MAX_CPT = FREQUENCY / PHASE;
    
    // Calcul de la valeur minimale du rapport cyclique
    localparam logic [DUTY_SIZE-1:0] MIN_DUTY = ((1 << DUTY_SIZE) * MIN_DUTY_PERCENT) / 100;

    logic [2:0] sensor;
    int phase_counter = 0;
    logic [DUTY_SIZE-1:0] pwm_counter = 0;
    logic pwm_out;
    logic [DUTY_SIZE-1:0] current_duty;
    int ramp_divider = 0;

    // Concatenation des capteurs 
    assign sensor = {Ha, Hb, Hc};

    // --- Génération du signal PWM (P_PWM) ---
    always_ff @(posedge CLK or posedge RST) begin : P_PWM
        if (RST) begin
            pwm_counter <= 0;
            pwm_out     <= 1'b0;
        end else begin
            pwm_counter <= pwm_counter + 1;
            // Comparaison pour générer le rapport cyclique
            if (pwm_counter < current_duty)
                pwm_out <= 1'b1;
            else
                pwm_out <= 1'b0;
        end
    end

    // --- Compteur de phase (P_PHASE_CPT) ---
    always_ff @(posedge CLK or posedge RST) begin : P_PHASE_CPT
        if (RST) begin
            phase_counter <= 0;
        end else begin
            if (phase_counter == MAX_CPT - 1)
                phase_counter <= 0;
            else
                phase_counter <= phase_counter + 1;
        end
    end

    // --- Génération des sorties et Commutation (P_OUPUT_GEN) ---
    always_ff @(posedge CLK or posedge RST) begin : P_OUPUT_GEN
        if (RST) begin
            // Valeurs par défaut au reset [cite: 20]
            {U, V, W, Un, Vn, Wn} <= 6'b000000; 
        end else begin
            // Valeurs par défaut à chaque cycle 
            {U, V, W, Un, Vn, Wn} <= 6'b000000;
            
            if (EN) begin 
                case (sensor)
                    3'b001: begin U <= pwm_out; Vn <= 1'b1; end
                    3'b101: begin U <= pwm_out; Wn <= 1'b1; end
                    3'b100: begin V <= pwm_out; Wn <= 1'b1; end
                    3'b110: begin V <= pwm_out; Un <= 1'b1; end
                    3'b010: begin W <= pwm_out; Un <= 1'b1; end
                    3'b011: begin W <= pwm_out; Vn <= 1'b1; end
                    default: ;
                endcase
            end
        end
    end

    // --- Gestion de la rampe d'accélération (P_RAMP) ---
    always_ff @(posedge CLK or posedge RST) begin : P_RAMP
        if (RST) begin
            current_duty <= 0;
            ramp_divider <= 0;
        end else begin
            if (EN) begin
                if (ramp_divider >= 200) begin 
                    ramp_divider <= 0;
                    // Incrémentation/décrémente vers la consigne 
                    if (current_duty < duty) begin
                        if (current_duty == 0 && duty >= MIN_DUTY)
                            current_duty <= MIN_DUTY; // Démarrage franc 
                        else
                            current_duty <= current_duty + 1;
                    end else if (current_duty > duty) begin
                        current_duty <= current_duty - 1; 
                    end
                end else begin
                    ramp_divider <= ramp_divider + 1;
                end
            end else begin
                current_duty <= 0;
                ramp_divider <= 0;
            end
        end
    end

endmodule