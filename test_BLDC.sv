module test;
timeunit 1ns;

reg clk = 0;
reg rst = 0;
reg [7:0] duty;
reg en;

wire U;
wire Un;
wire V;
wire Vn;
wire W;
wire Wn; 

controleur truc(clk,rst,duty,en,U,Un,V,Vn,W,Wn);

always
  begin
    #500 clk = 1;
    #500 clk = 0;
  end

initial
begin
	rst = 1;
	#40ns;
	rst = 0;
	en = 0;

	duty = 8'b 01000000;
	#2s;

	duty = 8'b 11000000;
	#2s;

	duty = 8'b 00000000;
	#2s;

	duty = 8'b 11111111;
	#2s;


end


endmodule