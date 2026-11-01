`timescale 1ns/1ps
// Actual AMD primitive. 50*18=900 MHz VCO, divide by 18/9/6 => 50/100/150.
module clock_tree(input wire clk_in,reset,output wire clk50,clk100,clk150,locked);
 wire fb,fb_buf,c0,c1,c2;
 MMCME2_BASE #(.BANDWIDTH("OPTIMIZED"),.CLKIN1_PERIOD(20.0),.DIVCLK_DIVIDE(1),
 .CLKFBOUT_MULT_F(18.0),.CLKOUT0_DIVIDE_F(18.0),.CLKOUT1_DIVIDE(9),
 .CLKOUT2_DIVIDE(6),.STARTUP_WAIT("FALSE")) mmcm(
 .CLKIN1(clk_in),.CLKFBIN(fb_buf),.RST(reset),.PWRDWN(1'b0),.CLKFBOUT(fb),
 .CLKOUT0(c0),.CLKOUT1(c1),.CLKOUT2(c2),.LOCKED(locked));
 BUFG bfb(.I(fb),.O(fb_buf));
 BUFG b0(.I(c0),.O(clk50)); BUFG b1(.I(c1),.O(clk100)); BUFG b2(.I(c2),.O(clk150));
endmodule
