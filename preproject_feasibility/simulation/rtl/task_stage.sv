`timescale 1ns/1ps
module task_stage #(parameter integer OP=1)(
 input wire clk,reset_n,allow,input wire [127:0] in_data,input wire in_valid,
 output wire in_ready,output reg [127:0] out_data,output reg out_valid,input wire out_ready);
 wire slot=~out_valid|out_ready;
 assign in_ready=slot&allow;
 wire [31:0] x=in_data[31:0];
 wire [31:0] result=(OP==1)?(x*32'd3+32'd7):(OP==2)?(x^32'h5a5aa5a5):(x+in_data[63:32]);
 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin out_valid<=0;out_data<=0;end
  else if(slot) begin
   out_valid<=in_valid&allow;
   if(in_valid&allow) out_data<={in_data[127:32],result};
  end
 end
endmodule
