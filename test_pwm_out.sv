module test_pwm_out;

    logic clk, rst;
    logic unsigned [15:0] compteur;
    logic unsigned [15:0] current_duty;
    logic unsigned [15:0] max_cpt;
    logic pwm_out;

    pwm test(.clk(clk),
        .rst(rst),
        .compteur(compteur),
        .current_duty(current_duty),
        .pwm_out(pwm_out));

    initial clk = 0;
    always clk = #500ns ~clk;

    initial begin
        rst = 1;
        #1ms
        rst = 0;
        compteur = 16'b 0000000000000000;
        current_duty = 16'b 0100111000100000;
        #10ms
        compteur = 16'b 0000000010000000;
        current_duty = 16'b 0000000000000000;
        #10ms
        $finish;
    end
endmodule