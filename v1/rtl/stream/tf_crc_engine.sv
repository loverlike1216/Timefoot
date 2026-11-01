`timescale 1ns/1ps
// Iterative, synthesizable MSB-first CRC32. One bit/cycle, no unbounded combinational CRC path.
module tf_crc_engine #(parameter integer BITS=176)(
 input wire clk,rst,input wire [BITS-1:0] in_body,input wire in_valid,output wire in_ready,
 output reg [BITS-1:0] out_body,output reg [31:0] out_crc,output reg out_valid,input wire out_ready);
 reg busy;reg [BITS-1:0] shift;reg [31:0] crc;reg [$clog2(BITS+1)-1:0] left;
 wire [31:0] next_crc=(crc<<1)^((crc[31]^shift[BITS-1])?32'h04c11db7:32'd0);
 assign in_ready=~busy&~out_valid;
 always @(posedge clk)begin
  if(rst)begin busy<=0;shift<=0;crc<=32'hffffffff;left<=0;out_body<=0;out_crc<=0;out_valid<=0;end
  else begin
   if(out_valid&&out_ready)out_valid<=0;
   if(in_valid&&in_ready)begin out_body<=in_body;shift<=in_body;crc<=32'hffffffff;left<=BITS;busy<=1;end
   else if(busy)begin
    crc<=next_crc;shift<=shift<<1;left<=left-1'b1;
    if(left==1)begin busy<=0;out_crc<=~next_crc;out_valid<=1;end
   end
  end
 end
endmodule
