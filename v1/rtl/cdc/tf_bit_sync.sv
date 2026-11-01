`timescale 1ns/1ps
module tf_bit_sync(input wire src_clk,src_bit,dst_clk,output wire dst_bit);
 xpm_cdc_single #(.DEST_SYNC_FF(3),.INIT_SYNC_FF(1),.SRC_INPUT_REG(0),.SIM_ASSERT_CHK(1))
 u_bit(.src_clk(src_clk),.src_in(src_bit),.dest_clk(dst_clk),.dest_out(dst_bit));
endmodule
