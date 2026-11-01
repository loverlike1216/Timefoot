`timescale 1ns/1ps
// Single FPGA digital integration. Ports are logical adapter interfaces, not board wiring.
module tf_node_top #(parameter integer WORK_DIV=6,NODE_ID=0,PAYLOAD_W=32,FIFO_DEPTH=16,FRAMES=64)(
 input wire ref_in,monitor_in,rx_clock,arst,
 input wire abort_session,prepare_valid,input wire [31:0] prepare_session,
 input wire [63:0] prepare_epoch,input wire [2:0] prepare_stage_mask,input wire prepare_source,
 input wire sync_marker,marker_qualified,run_enable,input wire [31:0] event_id,event_session,
 input wire [63:0] event_target,input wire event_valid,output wire event_ready,
 input wire cancel_all,cancel_valid,input wire [31:0] cancel_id,
 input wire [175+PAYLOAD_W:0] rx_frame,input wire rx_valid,output wire rx_ready,
 output wire [175+PAYLOAD_W:0] tx_frame,output wire tx_valid,input wire tx_ready,
 output wire [63:0] timestamp,output wire [31:0] session_id,
 output wire prepared,applied,time_valid,event_execute,node_fault,clock_ready,reference_fault,
 output wire [31:0] executed_id,output wire [63:0] executed_timestamp,
 output wire work_clock,output wire fifo_full,output wire [$clog2(FIFO_DEPTH):0] fifo_level,
 output wire [31:0] sample_count,delivered_count);
 wire ref_clk,monitor_clk,rx_clk,rr,wr,locked;
 BUFG br(.I(ref_in),.O(ref_clk));BUFG bm(.I(monitor_in),.O(monitor_clk));BUFG bx(.I(rx_clock),.O(rx_clk));
 tf_clock_manager #(.WORK_DIV(WORK_DIV)) clocks(.ref_clk(ref_clk),.monitor_clk(monitor_clk),.arst(arst),
 .work_clk(work_clock),.locked(locked),.ref_rst(rr),.work_rst(wr),.reference_fault(reference_fault),.clock_ready(clock_ready));
 tf_node_core #(.NODE_ID(NODE_ID),.PAYLOAD_W(PAYLOAD_W),.FIFO_DEPTH(FIFO_DEPTH),.FRAMES(FRAMES)) core(
 .ref_clk(ref_clk),.work_clk(work_clock),.rx_clk(rx_clk),.ref_rst(rr),.work_rst(wr),
 .abort_session(abort_session),.prepare_valid(prepare_valid),.prepare_session(prepare_session),
 .prepare_epoch(prepare_epoch),.prepare_stage_mask(prepare_stage_mask),.prepare_source(prepare_source),
 .sync_marker(sync_marker),.marker_qualified(marker_qualified),.run_enable(run_enable),.event_id(event_id),.event_session(event_session),
 .event_target(event_target),.event_valid(event_valid),.event_ready(event_ready),
 .cancel_all(cancel_all),.cancel_valid(cancel_valid),.cancel_id(cancel_id),
 .rx_frame(rx_frame),.rx_valid(rx_valid),.rx_ready(rx_ready),.tx_frame(tx_frame),.tx_valid(tx_valid),.tx_ready(tx_ready),
 .timestamp(timestamp),.session_id(session_id),.prepared(prepared),.applied(applied),.time_valid(time_valid),
 .event_execute(event_execute),.executed_id(executed_id),.executed_timestamp(executed_timestamp),
 .node_fault(node_fault),.fifo_full(fifo_full),.fifo_level(fifo_level),.sample_count(sample_count),.delivered_count(delivered_count));
endmodule
