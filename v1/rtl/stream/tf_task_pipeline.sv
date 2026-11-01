`timescale 1ns/1ps
module tf_task_pipeline #(parameter integer PAYLOAD_W=32)(
 input wire clk,rst,input wire [2:0] stage_mask,
 input wire [143+PAYLOAD_W:0] in_body,input wire in_valid,output wire in_ready,
 output wire [143+PAYLOAD_W:0] out_body,output wire out_valid,input wire out_ready);
 localparam B=144+PAYLOAD_W;
 reg [B-1:0] d[3];reg [2:0] v;wire [2:0] r;
 assign r[2]=~v[2]|out_ready;assign r[1]=~v[1]|r[2];assign r[0]=~v[0]|r[1];
 assign in_ready=r[0];assign out_body=d[2];assign out_valid=v[2];
 wire [PAYLOAD_W-1:0] p0=in_body[PAYLOAD_W-1:0];
 wire [PAYLOAD_W-1:0] p1=d[0][PAYLOAD_W-1:0];wire [PAYLOAD_W-1:0] p2=d[1][PAYLOAD_W-1:0];
 always @(posedge clk)begin
  if(rst)begin v<=0;d[0]<=0;d[1]<=0;d[2]<=0;end
  else begin
   if(r[0])begin v[0]<=in_valid;if(in_valid)d[0]<={in_body[B-1:PAYLOAD_W],stage_mask[0]?PAYLOAD_W'(p0*3+7):p0};end
   if(r[1])begin v[1]<=v[0];if(v[0])d[1]<={d[0][B-1:PAYLOAD_W],stage_mask[1]?(p1^PAYLOAD_W'(32'h5a5aa5a5)):p1};end
   if(r[2])begin v[2]<=v[1];if(v[1])d[2]<={d[1][B-1:PAYLOAD_W],stage_mask[2]?(p2+d[1][PAYLOAD_W+16 +:32]):p2};end
  end
 end
endmodule
