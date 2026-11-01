`timescale 1ns/1ps
module tf_timebase(
 input wire clk,rst,abort_session,
 input wire prepare,input wire [31:0] prepare_session,input wire [63:0] prepare_epoch,
 input wire sync_marker,marker_qualified,input wire run_enable,
 output reg [63:0] timestamp,output reg [31:0] session_id,
 output reg prepared,applied,time_valid,output reg protocol_error);
 reg [63:0] staged_epoch;reg marker_last;
 initial begin timestamp=0;session_id=0;prepared=0;applied=0;time_valid=0;
  staged_epoch=0;marker_last=0;protocol_error=0;end
 always @(posedge clk or posedge rst) begin
  if(rst)begin timestamp<=0;session_id<=0;prepared<=0;applied<=0;time_valid<=0;
   staged_epoch<=0;marker_last<=0;protocol_error<=0;end
  else begin
   marker_last<=sync_marker;
   if(time_valid)timestamp<=timestamp+1'b1;
   if(abort_session)begin prepared<=0;applied<=0;time_valid<=0;protocol_error<=0;end
   else if(prepare)begin
    if(run_enable)protocol_error<=1;
    else begin staged_epoch<=prepare_epoch;session_id<=prepare_session;
     prepared<=1;applied<=0;time_valid<=0;protocol_error<=0;end
   end else if(sync_marker&&!marker_last)begin
    if(prepared&&!applied&&!run_enable&&marker_qualified)begin timestamp<=staged_epoch;time_valid<=1;applied<=1;end
    else protocol_error<=1;
   end
   if(!marker_qualified)begin applied<=0;time_valid<=0;protocol_error<=1;end
  end
 end
endmodule
