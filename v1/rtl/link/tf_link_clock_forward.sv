`timescale 1ns/1ps
// Data launches on C rising; forwarded rising edge is C falling (eye centre).
module tf_link_clock_forward(input wire clk,output wire forwarded_clk);
 ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(1'b0),.SRTYPE("SYNC")) forward_oddr(
 .C(clk),.CE(1'b1),.D1(1'b0),.D2(1'b1),.R(1'b0),.S(1'b0),.Q(forwarded_clk));
endmodule
