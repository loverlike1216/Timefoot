`timescale 1ns/1ps
// Generic single-beat register port, entirely in reference/control clk domain.
module tf_control_interface #(parameter [3:0] DEFAULT_MASK=15,parameter [11:0] DEFAULT_MAP=12'b100_010_001_000)(input wire clk,rst,valid,write,input wire [7:0] address,
 input wire [31:0] wdata,output wire ready,output reg rvalid,output reg [31:0] rdata,output reg bus_error,
 input wire running,input wire [3:0] state,input wire [31:0] session_id,input wire [63:0] timestamp,
 input wire [3:0] faults,input wire event_ready,input wire [31:0] recovery_count,
 output reg [3:0] node_mask,output reg [63:0] epoch,output reg start,
 output reg [31:0] event_id,event_session,output reg [63:0] event_target,
 output reg event_valid,cancel_all,cancel_valid,output reg [31:0] cancel_id,
 output reg [11:0] stage_map,output reg [3:0] source_mask);
 reg [31:0] timestamp_high,submitted_count,canceled_count;
 assign ready=~(valid&&write&&address==8'h30&&!event_ready);
 always @(posedge clk)begin
  if(rst)begin node_mask<=DEFAULT_MASK;stage_map<=DEFAULT_MAP;source_mask<=1;timestamp_high<=0;epoch<=1000000;start<=0;event_id<=0;event_session<=0;event_target<=0;
   event_valid<=0;cancel_all<=0;cancel_valid<=0;cancel_id<=0;rvalid<=0;rdata<=0;bus_error<=0;submitted_count<=0;canceled_count<=0;end
  else begin
   start<=0;event_valid<=0;cancel_all<=0;cancel_valid<=0;rvalid<=0;bus_error<=0;
   if(valid&&ready)begin
    rvalid<=1;
    if(write)case(address)
     8'h00:node_mask<=wdata[3:0];8'h04:start<=wdata[0];
     8'h10:epoch[31:0]<=wdata;8'h14:epoch[63:32]<=wdata;
     8'h20:event_id<=wdata;8'h24:event_session<=wdata;
     8'h28:event_target[31:0]<=wdata;8'h2c:event_target[63:32]<=wdata;
     8'h30:begin event_valid<=wdata[0];if(wdata[0])submitted_count<=submitted_count+1'b1;end
     8'h34:begin cancel_id<=wdata;cancel_valid<=1;canceled_count<=canceled_count+1'b1;end
     8'h38:cancel_all<=wdata[0];default:bus_error<=1;
     8'h60:stage_map<=wdata[11:0];8'h64:source_mask<=wdata[3:0];
    endcase
    else case(address)
     8'h00:rdata<={28'd0,node_mask};8'h10:rdata<=epoch[31:0];8'h14:rdata<=epoch[63:32];
     8'h40:rdata<={27'd0,running,state};8'h44:rdata<=session_id;
     8'h48:begin rdata<=timestamp[31:0];timestamp_high<=timestamp[63:32];end
     8'h4c:rdata<=timestamp_high;8'h50:rdata<={28'd0,faults};
     8'h60:rdata<={20'd0,stage_map};8'h64:rdata<={28'd0,source_mask};
     8'h80:rdata<=submitted_count;8'h84:rdata<=canceled_count;8'h88:rdata<=recovery_count;
     default:begin rdata<=0;bus_error<=1;end
    endcase
   end
  end
 end
endmodule
