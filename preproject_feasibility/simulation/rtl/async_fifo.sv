`timescale 1ns/1ps
// Gray-pointer dual-clock FIFO. Reset asserts globally and releases in each domain.
// Gray bus max-delay/bus-skew constraints are REQUIRED in physical integration.
module async_fifo #(parameter integer WIDTH=128, A=3)(
 input wire wclk,rclk,reset_n,input wire [WIDTH-1:0] wdata,
 input wire wvalid,output wire wready,output wire [WIDTH-1:0] rdata,
 output wire rvalid,input wire rready,output wire full,empty);
 (* ASYNC_REG="TRUE" *) reg [1:0] wrst,rrst;
 always @(posedge wclk or negedge reset_n) if(!reset_n) wrst<=0; else wrst<={wrst[0],1'b1};
 always @(posedge rclk or negedge reset_n) if(!reset_n) rrst<=0; else rrst<={rrst[0],1'b1};
 (* ram_style="distributed" *) reg [WIDTH-1:0] mem[0:(1<<A)-1];
 reg [A:0] wb,rb,wg,rg;
 (* ASYNC_REG="TRUE" *) reg [A:0] rg1,rg2,wg1,wg2;
 reg full_r,empty_r;
 wire wen=wvalid&wready,ren=rvalid&rready;
 wire [A:0] wn=wb+wen,rn=rb+ren;
 wire [A:0] wgn=(wn>>1)^wn,rgn=(rn>>1)^rn;
 assign wready=wrst[1]&~full_r; assign rvalid=rrst[1]&~empty_r;
 assign full=full_r; assign empty=empty_r;
 assign rdata=mem[rb[A-1:0]];
 always @(posedge wclk or negedge reset_n) begin
  if(!reset_n) begin wb<=0;wg<=0;rg1<=0;rg2<=0;full_r<=0;end
  else if(!wrst[1]) begin wb<=0;wg<=0;rg1<=0;rg2<=0;full_r<=0;end
  else begin
   rg1<=rg;rg2<=rg1;wb<=wn;wg<=wgn;
   full_r<=(wgn=={~rg2[A:A-1],rg2[A-2:0]});
   if(wen) mem[wb[A-1:0]]<=wdata;
  end
 end
 always @(posedge rclk or negedge reset_n) begin
  if(!reset_n) begin rb<=0;rg<=0;wg1<=0;wg2<=0;empty_r<=1;end
  else if(!rrst[1]) begin rb<=0;rg<=0;wg1<=0;wg2<=0;empty_r<=1;end
  else begin wg1<=wg;wg2<=wg1;rb<=rn;rg<=rgn;empty_r<=(rgn==wg2);end
 end
endmodule
