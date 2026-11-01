`timescale 1ns/1ps
// Regression preserves all three original counter-bit outputs and the same2ns budget.
// Work-domain state is explicitly transferred and re-registered in the ref output domain.
module tf_pin_timing_top(input wire ref_in,output wire [2:0] q);
 wire ref_clk,fb,fb_buf,c0,c1,c2,c50,c100,c150,locked;
 BUFG br(.I(ref_in),.O(ref_clk));
 MMCME2_BASE #(.CLKIN1_PERIOD(20.0),.DIVCLK_DIVIDE(1),.CLKFBOUT_MULT_F(18.0),
 .CLKOUT0_DIVIDE_F(18.0),.CLKOUT1_DIVIDE(9),.CLKOUT2_DIVIDE(6)) mmcm(
 .CLKIN1(ref_clk),.CLKFBIN(fb_buf),.CLKFBOUT(fb),.CLKOUT0(c0),.CLKOUT1(c1),.CLKOUT2(c2),
 .LOCKED(locked),.RST(1'b0),.PWRDWN(1'b0));
 BUFG bf(.I(fb),.O(fb_buf));BUFG b0(.I(c0),.O(c50));BUFG b1(.I(c1),.O(c100));BUFG b2(.I(c2),.O(c150));
 reg [7:0] a=0,b=0,d=0;
 always @(posedge c50)if(locked)a<=a+1'b1;
 always @(posedge c100)if(locked)b<=b+1'b1;
 always @(posedge c150)if(locked)d<=d+1'b1;
 wire [2:0] sync_bits;
 tf_bit_sync s0(.src_clk(c150),.src_bit(d[7]),.dst_clk(ref_clk),.dst_bit(sync_bits[0]));
 tf_bit_sync s1(.src_clk(c100),.src_bit(b[7]),.dst_clk(ref_clk),.dst_bit(sync_bits[1]));
 tf_bit_sync s2(.src_clk(c50),.src_bit(a[7]),.dst_clk(ref_clk),.dst_bit(sync_bits[2]));
 (* IOB="TRUE" *)reg [2:0] output_reg=0;
 always @(posedge ref_clk)output_reg<=sync_bits;
 assign q=output_reg;
endmodule
