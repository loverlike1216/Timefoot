`timescale 1ns/1ps
// Pin-routing experiment only. This is NOT a board bitstream design.
module pin_clock_top(input wire ref_in,output wire [2:0] q);
 wire c50,c100,c150,locked;
 clock_tree c(.clk_in(ref_in),.reset(1'b0),.clk50(c50),.clk100(c100),.clk150(c150),.locked(locked));
 reg [7:0] a=0,b=0,d=0;
 always @(posedge c50) if(locked) a<=a+1;
 always @(posedge c100) if(locked) b<=b+1;
 always @(posedge c150) if(locked) d<=d+1;
 assign q={a[7],b[7],d[7]};
endmodule
