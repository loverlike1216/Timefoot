`timescale 1ns/1ps
module tf_cdc_bridge #(parameter integer WIDTH=128,DEPTH=16,COORDINATED_RESET=0)(
 input wire src_clk,dst_clk,src_flush,dst_flush,
 input wire [WIDTH-1:0] src_data,input wire src_valid,output wire src_ready,
 output wire [WIDTH-1:0] dst_data,output wire dst_valid,input wire dst_ready);
 wire f,e,wo,ro;wire [$clog2(DEPTH):0] wl,rl;
 tf_async_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH),.COORDINATED_RESET(COORDINATED_RESET)) u_bridge(
 .wr_clk(src_clk),.rd_clk(dst_clk),.wr_flush(src_flush),.rd_flush(dst_flush),
 .in_data(src_data),.in_valid(src_valid),.in_ready(src_ready),
 .out_data(dst_data),.out_valid(dst_valid),.out_ready(dst_ready),
 .full(f),.empty(e),.wr_online(wo),.rd_online(ro),.wr_level(wl),.rd_level(rl));
endmodule
