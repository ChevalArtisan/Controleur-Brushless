module test_MaE;

	logic clk, rst,pwm_out;
	logic unsigned [2:0] etat;
	logic U,V,W,Un,Vn,Wn;


	machine_a_etat M2(.clk(clk),
		.rst(rst),
		.pwm_out(pwm_out),
		.etat(etat),
		.U(U),
		.V(V),
		.W(W),
		.Un(Un),
		.Vn(Vn),
		.Wn(Wn));

	initial clk = 0;
	always clk = #500ns ~clk;


    initial begin
        rst = 1;//test etat 000 pwm out 1 
        #1ms
        rst = 0;
        pwm_out = 1'b 1;
        etat = 3'b 000;
        #2s //expected : U=0 V=0 W=0 Un=0 Vn=0 Wn=0
        rst = 1;
        #1ms
        rst = 0;
        pwm_out = 1'b 1; //test etat 001 pwm out 1
        etat = 3'b 001;
        #2s //expected : U=1 V=0 W=0 Un=0 Vn=1 Wn=0
        rst = 1;
        #1ms    
        rst = 0;
        pwm_out = 1'b 1; //test etat 101 pwm out 1
        etat = 3'b 101;
        #2s //expected : U=1 V=0 W=0 Un=0 Vn=0 Wn=1
        rst = 1;
        #1ms
        rst = 0;
        pwm_out = 1'b 0; //test etat 100 pwm out 0
        etat = 3'b 100;
        #2s //expected : U=0 V=0 W=0 Un=0 Vn=0 Wn=1

        $finish;
    end
endmodule


