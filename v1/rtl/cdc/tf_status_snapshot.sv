`timescale 1ns/1ps
// Coherent periodic snapshot; arbitrary counter jumps are legal. No Gray
// single-increment or lossless-sampling assumption is imposed on telemetry.
module tf_status_snapshot #(parameter integer WIDTH=32)(
 input wire src_clk,dst_clk,input wire [WIDTH-1:0] source,output wire [WIDTH-1:0] snapshot);
 reg [WIDTH-1:0] held=0;reg send=0;wire received,request;
 always @(posedge src_clk)begin
  if(!send&&!received)begin held<=source;send<=1;end
  else if(send&&received)send<=0;
 end
 xpm_cdc_handshake #(.WIDTH(WIDTH),.DEST_SYNC_FF(3),.SRC_SYNC_FF(3),.INIT_SYNC_FF(1),
 .SIM_ASSERT_CHK(1),.DEST_EXT_HSK(0)) coherent(
 .src_clk(src_clk),.src_in(held),.src_send(send),.src_rcv(received),
 .dest_clk(dst_clk),.dest_out(snapshot),.dest_req(request),.dest_ack(1'b0));
endmodule
