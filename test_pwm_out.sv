module test_pwm_out;

    logic clk, rst, acceleration;
    logic unsigned [7:0] compteur;
    logic unsigned [7:0] current_duty;
    logic pwm_out;
	logic pwm_acceleration;

    pwm test(.clk(clk),
        .rst(rst),
	.acceleration(acceleration),
        .compteur(compteur),
        .current_duty(current_duty),
        .pwm_out(pwm_out),
	.pwm_acceleration(pwm_acceleration));

    initial clk = 0;
    always clk = #500ns ~clk;

	initial compteur = 8'b 00000000;
	always compteur = #1us compteur + 1;


    initial begin
        rst = 1;
        #1ms
        rst = 0;
        current_duty = 8'b 10000000;
	acceleration = 0;
	
        #10ms
        current_duty = 8'b 11111111;
        #10ms

        current_duty = 8'b 10000000;
	acceleration = 1;
	
        #10ms
        current_duty = 8'b 11111111;
        #10ms
        $finish;
    end
endmodule