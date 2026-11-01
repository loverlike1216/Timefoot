`timescale 1ns/1ps
// SIMULATION ONLY physical-adapter model: finite storage, variable latency,
// backpressure and deliberate corruption. No claim about a cable/PHY.
module tf_sim_channel #(parameter integer WIDTH=208,DELAY=7,SEED=1)(
 input wire clk,flush,enable,corrupt,input wire [WIDTH-1:0] in_data,input wire in_valid,output wire in_ready,
 output wire [WIDTH-1:0] out_data,output wire out_valid,input wire out_ready);
 reg [WIDTH-1:0] data;reg busy;integer age;reg [31:0] rng=SEED;reg corrupted;
 assign in_ready=!busy&&enable&&rng[1];assign out_data=data;
 assign out_valid=busy&&age==0;
 always @(posedge clk)begin
  rng<={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
  if(flush)begin busy<=0;age<=0;data<=0;corrupted<=0;end
  else begin
   if(in_valid&&in_ready)begin busy<=1;age<=DELAY+(rng[7:4]%9);
    data<=in_data^((corrupt&&!corrupted)?WIDTH'(1):WIDTH'(0));if(corrupt)corrupted<=1;end
   if(busy&&age>0)age<=age-1;
   if(out_valid&&out_ready)busy<=0;
  end
 end
endmodule
