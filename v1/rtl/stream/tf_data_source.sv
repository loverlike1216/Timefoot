`timescale 1ns/1ps
module tf_data_source #(parameter integer PAYLOAD_W=32,FRAMES=64)(
 input wire clk,rst,start,enabled,input wire [63:0] timestamp,input wire [31:0] session_id,
 output reg [143+PAYLOAD_W:0] body,output reg valid,input wire ready,
 output reg busy,output reg [31:0] sample_count,output reg overrun);
 reg [31:0] seq;reg [$clog2(FRAMES+1)-1:0] remaining;
 always @(posedge clk)begin
  if(rst)begin body<=0;valid<=0;busy<=0;seq<=0;remaining<=0;sample_count<=0;overrun<=0;end
  else begin
   if(valid&&ready)valid<=0;
   if(start&&enabled)begin if(busy)overrun<=1;else begin busy<=1;remaining<=FRAMES;end end
   if(busy&&(!valid||ready))begin
    body<={session_id,seq,timestamp,16'(PAYLOAD_W/8),PAYLOAD_W'(seq*17+3)};
    valid<=1;seq<=seq+1'b1;sample_count<=sample_count+1'b1;remaining<=remaining-1'b1;
    if(remaining==1)busy<=0;
   end
  end
 end
endmodule
