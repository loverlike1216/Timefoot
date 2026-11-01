`timescale 1ns/1ps
// Physical-node management backend. Rejected event submissions return an error
// rather than blocking the serial queue and preventing fault-abort commands.
module tf_node_registers(input wire clk,rst,bus_valid,bus_write,input wire [7:0] bus_address,
 input wire [31:0] bus_wdata,output wire bus_ready,output reg bus_rvalid,bus_error,output reg [31:0] bus_rdata,
 input wire clock_ready,prepared,applied,time_valid,node_fault,marker_qualified,event_ready,event_error,
 input wire [3:0] event_error_code,input wire [31:0] executed_id,executed_count,event_aborted,event_rejected,
 input wire [63:0] timestamp,executed_time,input wire [31:0] active_session,
 input wire [127:0] work_status,input wire [95:0] tx_status,input wire [127:0] rx_status,input wire [31:0] control_errors,
 output reg abort_session=0,prepare_valid=0,run_request=0,source_role=1,
 output reg [2:0] stage_mask=7,output reg [31:0] prepare_session=0,
 output reg [63:0] prepare_epoch=1000000,
 output reg [31:0] event_id=0,event_session=0,cancel_id=0,output reg [63:0] event_target=0,
 output reg event_valid=0,cancel_all=0,cancel_valid=0);
 reg [31:0] time_high=0,event_time_high=0,last_prepared=0;reg ever_prepared=0;
 reg [127:0] work_shadow=0,rx_shadow=0;reg [95:0] tx_shadow=0;reg [7:0] last_error=0;
 wire [31:0] session_delta=prepare_session-last_prepared;
 assign bus_ready=1;
 always @(posedge clk)begin
  if(rst)begin bus_rvalid<=0;bus_error<=0;bus_rdata<=0;abort_session<=0;prepare_valid<=0;run_request<=0;
   source_role<=1;stage_mask<=7;prepare_session<=0;prepare_epoch<=1000000;event_id<=0;event_session<=0;event_target<=0;
   cancel_id<=0;event_valid<=0;cancel_all<=0;cancel_valid<=0;time_high<=0;last_error<=0;
   event_time_high<=0;ever_prepared<=0;last_prepared<=0;work_shadow<=0;tx_shadow<=0;rx_shadow<=0;end
  else begin
   abort_session<=0;prepare_valid<=0;event_valid<=0;cancel_all<=0;cancel_valid<=0;bus_rvalid<=0;bus_error<=0;
   if(node_fault||!clock_ready||!marker_qualified)run_request<=0;
   if(event_error)last_error<={4'd0,event_error_code};
   if(bus_valid)begin
    bus_rvalid<=1;
    if(bus_write)case(bus_address)
     8'h00:if(run_request)bus_error<=1;else begin stage_mask<=bus_wdata[2:0];source_role<=bus_wdata[3];end
     8'h04:begin
      if(bus_wdata[1])begin abort_session<=1;run_request<=0;end
      if(bus_wdata[3])run_request<=0;
      if(bus_wdata[0])begin if(!clock_ready||run_request||!marker_qualified||bus_wdata[1]||
       (ever_prepared&&(session_delta==0||session_delta[31])))bus_error<=1;
       else begin prepare_valid<=1;last_error<=0;last_prepared<=prepare_session;ever_prepared<=1;end end
      if(bus_wdata[2])begin if(!prepared||!applied||!time_valid||node_fault||!marker_qualified)bus_error<=1;else run_request<=1;end
     end
     8'h10:if(run_request)bus_error<=1;else prepare_epoch[31:0]<=bus_wdata;
     8'h14:if(run_request)bus_error<=1;else prepare_epoch[63:32]<=bus_wdata;
     8'h18:if(run_request)bus_error<=1;else prepare_session<=bus_wdata;
     8'h20:event_id<=bus_wdata;8'h24:event_session<=bus_wdata;
     8'h28:event_target[31:0]<=bus_wdata;8'h2c:event_target[63:32]<=bus_wdata;
     8'h30:if(!event_ready||!run_request)begin bus_error<=1;last_error<=8'h80;end else event_valid<=bus_wdata[0];
     8'h34:begin cancel_id<=bus_wdata;cancel_valid<=1;end
     8'h38:cancel_all<=bus_wdata[0];default:bus_error<=1;
    endcase
    else case(bus_address)
     8'h00:bus_rdata<={28'd0,source_role,stage_mask};8'h10:bus_rdata<=prepare_epoch[31:0];8'h14:bus_rdata<=prepare_epoch[63:32];
     8'h18:bus_rdata<=prepare_session;
     8'h40:bus_rdata<={24'd0,event_ready,marker_qualified,node_fault,run_request,time_valid,applied,prepared,clock_ready};
     8'h44:bus_rdata<=active_session;8'h48:begin bus_rdata<=timestamp[31:0];time_high<=timestamp[63:32];end
     8'h4c:bus_rdata<=time_high;8'h50:bus_rdata<={24'd0,last_error};8'h54:bus_rdata<=executed_id;
     8'h58:begin bus_rdata<=executed_time[31:0];event_time_high<=executed_time[63:32];end
     8'h5c:bus_rdata<=event_time_high;
     8'h60:bus_rdata<=executed_count;8'h64:bus_rdata<=event_aborted;8'h68:bus_rdata<=event_rejected;
     8'h70:bus_rdata<=control_errors;
     8'h80:begin work_shadow<=work_status;bus_rdata<=work_status[31:0];end
     8'h84:bus_rdata<=work_shadow[63:32];8'h88:bus_rdata<=work_shadow[95:64];8'h8c:bus_rdata<=work_shadow[127:96];
     8'h90:begin tx_shadow<=tx_status;bus_rdata<=tx_status[31:0];end
     8'h94:bus_rdata<=tx_shadow[63:32];8'h98:bus_rdata<=tx_shadow[95:64];
     8'ha0:begin rx_shadow<=rx_status;bus_rdata<=rx_status[31:0];end
     8'ha4:bus_rdata<=rx_shadow[63:32];8'ha8:bus_rdata<=rx_shadow[95:64];8'hac:bus_rdata<=rx_shadow[127:96];
     default:begin bus_rdata<=0;bus_error<=1;end
    endcase
   end
  end
 end
endmodule
