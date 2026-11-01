`timescale 1ns/1ps
module tf_stream_tx #(parameter integer PAYLOAD_W=32)(
 input wire clk,rst,input wire [143+PAYLOAD_W:0] in_body,input wire in_valid,output wire in_ready,
 output wire [175+PAYLOAD_W:0] frame,output wire valid,input wire ready);
 localparam B=144+PAYLOAD_W;
 wire [B-1:0] body;wire [31:0] crc;
 tf_crc_engine #(.BITS(B)) enc(.clk(clk),.rst(rst),.in_body(in_body),.in_valid(in_valid),.in_ready(in_ready),
 .out_body(body),.out_crc(crc),.out_valid(valid),.out_ready(ready));
 assign frame={body,crc};
endmodule
