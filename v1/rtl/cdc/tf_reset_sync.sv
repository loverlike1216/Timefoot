`timescale 1ns/1ps
module tf_reset_sync(input wire clk, arst, output wire rst);
 xpm_cdc_async_rst #(.DEST_SYNC_FF(3),.INIT_SYNC_FF(1),.RST_ACTIVE_HIGH(1))
 u_reset(.src_arst(arst),.dest_clk(clk),.dest_arst(rst));
endmodule
