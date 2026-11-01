`timescale 1ns/1ps
// Forwarded-clock domain. Registered FRAME CREDIT and a full reserved slot.
// CRC/session/sequence validation is performed by tf_stream_link before tasks.
module tf_link_rx #(parameter integer FRAME_W=208,LANES=4)(
 input wire clk,root_rst,flush,input wire [LANES-1:0] pin_data,input wire pin_valid,pin_sof,
 (* IOB="TRUE" *)output reg pin_ready=0,output reg [FRAME_W-1:0] frame=0,output reg frame_valid=0,input wire frame_ready,
 output reg [31:0] started=0,forwarded=0,aborted=0,framing_errors=0,output reg error_flag=0);
 localparam BEATS=FRAME_W/LANES;
 (* IOB="TRUE" *)reg [LANES+1:0] captured=0;
 // IOB input registers capture the complete physical beat together. The
 // previous registered ready belongs to this physical sampling edge.
 reg credit_core=0,capture_ready=0;wire capture_accept=captured[LANES];
 reg [FRAME_W-1:0] assembly=0;reg active=0;
 reg [$clog2(BEATS)-1:0] count=0;reg flush_previous=1;
 wire [LANES-1:0] data=captured[LANES-1:0];wire sof=captured[LANES+1];
 always @(posedge clk)begin
  captured<={pin_sof,pin_valid,pin_data};capture_ready<=credit_core;
  pin_ready<=credit_core;
  if(root_rst)begin pin_ready<=0;credit_core<=0;frame<=0;frame_valid<=0;assembly<=0;active<=0;count<=0;
   started<=0;forwarded<=0;aborted<=0;framing_errors<=0;error_flag<=0;flush_previous<=1;capture_ready<=0;captured<=0;end
  else if(flush)begin
   if(!flush_previous)aborted<=aborted+(active?1:0)+(frame_valid?1:0)+(capture_accept&&sof?1:0);
   flush_previous<=1;pin_ready<=0;credit_core<=0;frame_valid<=0;active<=0;count<=0;capture_ready<=0;error_flag<=0;captured<=0;
  end else begin
   flush_previous<=0;
   if(pin_valid&&credit_core&&pin_sof)begin started<=started+1'b1;credit_core<=0;end
   if(frame_valid&&frame_ready)begin frame_valid<=0;forwarded<=forwarded+1'b1;end
   if(!active&&!capture_accept&&!frame_valid&&!pin_valid)credit_core<=1;
   if(capture_accept)begin
    if(sof&&capture_ready)begin
     if(active)begin aborted<=aborted+1'b1;framing_errors<=framing_errors+1'b1;error_flag<=1;end
     assembly<={{(FRAME_W-LANES){1'b0}},data};active<=1;count<=1;
    end else if(active&&!sof)begin
     assembly<={assembly[FRAME_W-LANES-1:0],data};
     if(count==BEATS-1)begin frame<={assembly[FRAME_W-LANES-1:0],data};frame_valid<=1;active<=0;count<=0;end
     else count<=count+1'b1;
    end else begin
     framing_errors<=framing_errors+1'b1;error_flag<=1;
     if(active)begin aborted<=aborted+1'b1;active<=0;count<=0;end
    end
   end
  end
 end
endmodule
