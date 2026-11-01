`timescale 1ns/1ps
// Complete digital pin profile, not a board wiring approval. All former208-bit
// data/control/status functions terminate in actual adapters and registers.
module tf_physical_node_top #(parameter integer LANES=4,WORK_DIV=6)(
 input wire ref_in,monitor_in,rx_clock,control_clock,arst,
 input wire sync_marker,marker_qualified,
 input wire [LANES-1:0] rx_data,input wire rx_valid,rx_sof,output wire rx_ready,
 output wire tx_clock,output wire [LANES-1:0] tx_data,output wire tx_valid,tx_sof,input wire tx_ready,
 input wire control_cs_n,control_mosi,output wire control_miso,control_ready,
 output wire event_out,output reg fault_out=1);
 wire ref_clk,monitor_clk,rx_clk,ctrl_clk,work_clk,rr,wr,locked,ready,ref_fault;
 BUFG br(.I(ref_in),.O(ref_clk));BUFG bm(.I(monitor_in),.O(monitor_clk));
 BUFG bx(.I(rx_clock),.O(rx_clk));BUFG bc(.I(control_clock),.O(ctrl_clk));
 tf_clock_manager #(.WORK_DIV(WORK_DIV)) clocks(.ref_clk(ref_clk),.monitor_clk(monitor_clk),.arst(arst),
 .work_clk(work_clk),.locked(locked),.ref_rst(rr),.work_rst(wr),.reference_fault(ref_fault),.clock_ready(ready));
 wire root_ref,root_work,root_rx,root_ctrl;
 tf_reset_sync gr(.clk(ref_clk),.arst(arst),.rst(root_ref));tf_reset_sync gw(.clk(work_clk),.arst(arst),.rst(root_work));
 tf_reset_sync gx(.clk(rx_clk),.arst(arst),.rst(root_rx));tf_reset_sync gc(.clk(ctrl_clk),.arst(arst),.rst(root_ctrl));
 wire bv,bwrite,bready,brvalid,berror;wire [7:0] addr;wire [31:0] wdata,rdata,ctrl_errors,ctrl_errors_ref;
 tf_management_serial management(.serial_clk(ctrl_clk),.ref_clk(ref_clk),.serial_rst(root_ctrl),.ref_rst(root_ref),
 .cs_n(control_cs_n),.mosi(control_mosi),.miso(control_miso),.ready(control_ready),.bus_valid(bv),.bus_write(bwrite),
 .bus_address(addr),.bus_wdata(wdata),.bus_ready(bready),.bus_rvalid(brvalid),.bus_error(berror),.bus_rdata(rdata),.protocol_errors(ctrl_errors));
 tf_status_snapshot #(.WIDTH(32)) ctl_status(.src_clk(ctrl_clk),.dst_clk(ref_clk),.source(ctrl_errors),.snapshot(ctrl_errors_ref));
 wire abort_session,prepare,run_request,source_role,er,ca,cv,ev;
 wire [2:0] map;wire [31:0] sid,eid,es,cid;wire [63:0] epoch,target;
 wire prepared,applied,time_valid,core_fault,framing_ref,framing_rx,execute,edone,eerror;
 wire [31:0] active_sid,executed_id,exc,abc,rjc,samples,delivered;wire [63:0] timestamp,executed_time;
 wire [3:0] ecode,scode;wire cf;wire [4:0] cl;
 reg hold_session=1;
 always @(posedge ref_clk or posedge rr)if(rr)hold_session<=1;
 else if(abort_session)hold_session<=1;else if(prepare&&marker_qualified)hold_session<=0;
 wire flush_work,flush_link,flush_rx;
 tf_reset_sync fw(.clk(work_clk),.arst(hold_session),.rst(flush_work));
 tf_reset_sync fl(.clk(ref_clk),.arst(hold_session),.rst(flush_link));
 tf_reset_sync fx(.clk(rx_clk),.arst(hold_session),.rst(flush_rx));
 wire [207:0] core_tx,core_rx;wire ctv,ctr,crv,crr;
 wire tfull,tstats;wire [4:0] tlevel;wire [31:0] ta,tsent,tabort,rxstart,rxfwd,rxabort,rxerr;
 tf_link_tx #(.LANES(LANES)) transmitter(.work_clk(work_clk),.link_clk(ref_clk),.work_root_rst(root_work),.link_root_rst(root_ref),
 .work_flush(flush_work),.link_flush(flush_link),.frame(core_tx),.frame_valid(ctv),.frame_ready(ctr),.pin_ready(tx_ready),
 .pin_data(tx_data),.pin_valid(tx_valid),.pin_sof(tx_sof),.pin_clock(tx_clock),.fifo_full(tfull),.queue_level(tlevel),
 .accepted(ta),.wire_sent(tsent),.aborted(tabort),.stats_valid(tstats));
 tf_link_rx #(.LANES(LANES)) receiver(.clk(rx_clk),.root_rst(root_rx),.flush(flush_rx),.pin_data(rx_data),.pin_valid(rx_valid),.pin_sof(rx_sof),
 .pin_ready(rx_ready),.frame(core_rx),.frame_valid(crv),.frame_ready(crr),.started(rxstart),.forwarded(rxfwd),.aborted(rxabort),.framing_errors(rxerr),.error_flag(framing_rx));
 tf_bit_sync ff(.src_clk(rx_clk),.src_bit(framing_rx),.dst_clk(ref_clk),.dst_bit(framing_ref));
 wire [127:0] work_snapshot,rx_snapshot;
 tf_status_snapshot #(.WIDTH(128)) ws(.src_clk(work_clk),.dst_clk(ref_clk),
 .source({ta,28'd0,scode,26'd0,cf,cl,delivered}),.snapshot(work_snapshot));
 tf_status_snapshot #(.WIDTH(128)) xs(.src_clk(rx_clk),.dst_clk(ref_clk),
 .source({rxerr,rxabort,rxfwd,rxstart}),.snapshot(rx_snapshot));
 wire fault=core_fault|framing_ref;
 always @(posedge ref_clk or posedge rr)if(rr)fault_out<=1;else fault_out<=fault;
 tf_node_registers registers(.clk(ref_clk),.rst(root_ref),.bus_valid(bv),.bus_write(bwrite),.bus_address(addr),.bus_wdata(wdata),
 .bus_ready(bready),.bus_rvalid(brvalid),.bus_error(berror),.bus_rdata(rdata),.clock_ready(ready),.prepared(prepared),.applied(applied),
 .time_valid(time_valid),.node_fault(fault),.marker_qualified(marker_qualified),.event_ready(er),.event_error(eerror),.event_error_code(ecode),
 .executed_id(executed_id),.executed_count(exc),.event_aborted(abc),.event_rejected(rjc),.timestamp(timestamp),.executed_time(executed_time),
 .active_session(active_sid),.work_status(work_snapshot),.tx_status({31'd0,tstats,tsent,tabort}),.rx_status(rx_snapshot),.control_errors(ctrl_errors_ref),
 .abort_session(abort_session),.prepare_valid(prepare),.run_request(run_request),.source_role(source_role),.stage_mask(map),.prepare_session(sid),
 .prepare_epoch(epoch),.event_id(eid),.event_session(es),.cancel_id(cid),.event_target(target),.event_valid(ev),.cancel_all(ca),.cancel_valid(cv));
 tf_node_core core(.ref_clk(ref_clk),.work_clk(work_clk),.rx_clk(rx_clk),.ref_rst(rr),.work_rst(wr),
 .abort_session(abort_session),.prepare_valid(prepare),.prepare_session(sid),.prepare_epoch(epoch),.prepare_stage_mask(map),.prepare_source(source_role),
 .sync_marker(sync_marker),.marker_qualified(marker_qualified),.run_enable(run_request&marker_qualified&ready),
 .event_id(eid),.event_session(es),.event_target(target),.event_valid(ev),.event_ready(er),.cancel_all(ca),.cancel_valid(cv),.cancel_id(cid),
 .rx_frame(core_rx),.rx_valid(crv),.rx_ready(crr),.tx_frame(core_tx),.tx_valid(ctv),.tx_ready(ctr),
 .timestamp(timestamp),.session_id(active_sid),.prepared(prepared),.applied(applied),.time_valid(time_valid),.event_execute(execute),
 .executed_id(executed_id),.executed_timestamp(executed_time),.node_fault(core_fault),.fifo_full(cf),.fifo_level(cl),.sample_count(samples),
 .delivered_count(delivered),.scheduler_done(edone),.scheduler_error(eerror),.scheduler_code(ecode),.stream_code(scode),
 .scheduler_executed(exc),.scheduler_aborted(abc),.scheduler_rejected(rjc));
 assign event_out=execute;
endmodule
