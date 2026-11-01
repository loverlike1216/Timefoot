`timescale 1ns/1ps
module tf_sync_controller #(parameter integer LEAD_TICKS=1024,TIMEOUT=8192,
 parameter [63:0] RESET_TICKS=0)(
 input wire clk,rst,start,input wire [3:0] requested_mask,
 input wire [63:0] requested_epoch,input wire [3:0] node_clock_ready,node_prepared,node_applied,node_fault,
 output reg [3:0] active_mask,output reg [31:0] session_id,output reg [63:0] epoch,
 output reg abort_session,output wire prepare_valid,output reg sync_marker,
 output wire running,output reg [3:0] state,output reg [31:0] recoveries,
 output wire [63:0] manager_ticks);
 localparam RESET=0,WAIT_REFERENCE=1,CLOCK_LOCK=2,NODE_DISCOVERY=3,EPOCH_ALIGN=4,
 SYNC_VERIFY=5,READY=6,RUNNING=7,FAULT=8,RECOVERY=9;
 reg [63:0] ticks,apply_at;reg [15:0] age;reg marker_request,marker_sent;
 wire [63:0] until_apply=apply_at-ticks,since_apply=ticks-apply_at;
 initial if(LEAD_TICKS<=16||TIMEOUT>65535||TIMEOUT<=LEAD_TICKS)$fatal(1,"SYNC_PARAMETERS");
 assign manager_ticks=ticks;
 assign running=(state==RUNNING);assign prepare_valid=(state==EPOCH_ALIGN);
 // Source-synchronous marker launched at the falling reference edge.
 always @(negedge clk or posedge rst)if(rst)sync_marker<=0;else sync_marker<=marker_request;
 always @(posedge clk)begin
  if(rst)begin state<=RESET;active_mask<=0;session_id<=0;epoch<=0;abort_session<=1;
   ticks<=RESET_TICKS;apply_at<=0;age<=0;marker_request<=0;marker_sent<=0;recoveries<=0;end
  else begin
   ticks<=ticks+1'b1;abort_session<=0;marker_request<=0;
   if(start)begin active_mask<=requested_mask;epoch<=requested_epoch;session_id<=session_id+1'b1;
    state<=WAIT_REFERENCE;abort_session<=1;age<=0;marker_sent<=0;end
   else case(state)
    RESET:state<=WAIT_REFERENCE;
    WAIT_REFERENCE:if(active_mask!=0&&((node_clock_ready&active_mask)==active_mask))begin state<=CLOCK_LOCK;age<=0;end
    CLOCK_LOCK:if((node_clock_ready&active_mask)!=active_mask)state<=WAIT_REFERENCE;
     else if(age==31)begin state<=NODE_DISCOVERY;age<=0;end else age<=age+1'b1;
    NODE_DISCOVERY:begin state<=EPOCH_ALIGN;apply_at<=ticks+LEAD_TICKS;age<=0;marker_sent<=0;end
    EPOCH_ALIGN:begin
     if((node_clock_ready&active_mask)!=active_mask)state<=FAULT;
     else if(age==TIMEOUT-1||until_apply[63]||until_apply<=8)state<=FAULT;
     else if((node_prepared&active_mask)==active_mask)begin state<=SYNC_VERIFY;age<=0;end
     else age<=age+1'b1;
    end
    SYNC_VERIFY:begin
     age<=age+1'b1;
     if(!marker_sent&&ticks==apply_at)begin marker_request<=1;marker_sent<=1;end
     if(marker_sent&&!since_apply[63]&&since_apply>8&&((node_applied&active_mask)==active_mask))state<=READY;
     if(age==TIMEOUT-1||(node_clock_ready&active_mask)!=active_mask||(node_fault&active_mask)!=0)state<=FAULT;
    end
    READY:if((node_fault&active_mask)==0)state<=RUNNING;else state<=FAULT;
    RUNNING:if((node_fault&active_mask)!=0||(node_clock_ready&active_mask)!=active_mask)state<=FAULT;
    FAULT:begin abort_session<=1;recoveries<=recoveries+1'b1;state<=RECOVERY;age<=0;end
    RECOVERY:if(age==63)begin session_id<=session_id+1'b1;epoch<=epoch+64'd1000000;state<=WAIT_REFERENCE;age<=0;end
     else age<=age+1'b1;
    default:state<=RESET;
   endcase
  end
 end
endmodule
