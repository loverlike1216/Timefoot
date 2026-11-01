`timescale 1ns/1ps
// Multi-FPGA logical assembly. External packet PHY adapters connect rx/tx ports.
// All control ports use the forwarded reference timing contract, not async GPIO.
module tf_system_top #(parameter integer NODES=4,PAYLOAD_W=32,FRAMES=64,
 parameter integer DIV0=18,DIV1=9,DIV2=6,DIV3=18)(
 input wire manager_clk,monitor_clk,arst,input wire [3:0] ref_clocks,node_reset,
 input wire [3:0] rx_clocks,input wire [3:0][175+PAYLOAD_W:0] rx_frames,
 input wire [3:0] rx_valid,output wire [3:0] rx_ready,
 output wire [3:0][175+PAYLOAD_W:0] tx_frames,output wire [3:0] tx_valid,input wire [3:0] tx_ready,
 input wire [3:0] markers,marker_qualified,output wire marker,
 input wire bus_valid,bus_write,input wire [7:0] bus_address,input wire [31:0] bus_wdata,
 output wire bus_ready,bus_rvalid,output wire [31:0] bus_rdata,output wire bus_error,
 output wire [3:0] work_clocks,event_execute,time_valid,clock_ready,reference_fault,
 output wire [3:0][63:0] timestamps,executed_timestamps,
 output wire [3:0][31:0] executed_ids,node_sessions,sample_counts,delivered_counts,
 output wire [3:0] fifo_full,output wire [3:0][4:0] fifo_levels,
 output wire running,output wire [3:0] state,active_mask,output wire [31:0] session_id,recoveries,
 output reg configuration_error);
 localparam [3:0] DEFAULT_MASK=(1<<NODES)-1;
 localparam [11:0] DEFAULT_MAP=NODES==1?12'b000_000_000_111:
      NODES==2?12'b000_000_110_001:NODES==3?12'b000_100_010_001:12'b100_010_001_000;
 wire manager_rst;tf_reset_sync mr(.clk(manager_clk),.arst(arst),.rst(manager_rst));
 wire [3:0] requested_mask,source_mask;wire [11:0] stage_map;wire [63:0] requested_epoch,epoch;
 wire start,abort_session,prepare_valid,ev,ca,cv;wire [31:0] eid,es,cid;wire [63:0] target;
 wire [3:0] prepared,applied,faults,event_ready,ready_m,prepared_m,applied_m,fault_m;
 wire [63:0] mt;wire all_event_ready=running&&((event_ready&active_mask)==active_mask);
 tf_control_interface #(.DEFAULT_MASK(DEFAULT_MASK),.DEFAULT_MAP(DEFAULT_MAP)) control(
 .clk(manager_clk),.rst(manager_rst),.valid(bus_valid),.write(bus_write),.address(bus_address),.wdata(bus_wdata),
 .ready(bus_ready),.rvalid(bus_rvalid),.rdata(bus_rdata),.bus_error(bus_error),
 .running(running),.state(state),.session_id(session_id),.timestamp(timestamps[0]),.faults(fault_m),.event_ready(all_event_ready),.recovery_count(recoveries),
 .node_mask(requested_mask),.epoch(requested_epoch),.start(start),.event_id(eid),.event_session(es),.event_target(target),
 .event_valid(ev),.cancel_all(ca),.cancel_valid(cv),.cancel_id(cid),.stage_map(stage_map),.source_mask(source_mask));
 // Prefix chain mapping is explicit. Missing any required stage or multiple
 // sources is a configuration fault; disabled slots are never auto-remapped.
 reg [2:0] coverage;integer c0,c1,c2,o0,o1,o2;
 always @* begin
  coverage=0;c0=0;c1=0;c2=0;o0=0;o1=0;o2=0;
  for(integer j=0;j<4;j=j+1)if(requested_mask[j])begin
   coverage=coverage|stage_map[j*3+:3];
   if(stage_map[j*3])begin c0=c0+1;o0=j;end
   if(stage_map[j*3+1])begin c1=c1+1;o1=j;end
   if(stage_map[j*3+2])begin c2=c2+1;o2=j;end
  end
 end
 wire config_ok=requested_mask!=0&&requested_mask[0]&&source_mask==1&&coverage==7&&
                ((requested_mask&(requested_mask+1'b1))==0)&&((requested_mask&~DEFAULT_MASK)==0)&&
                c0==1&&c1==1&&c2==1&&o0<=o1&&o1<=o2;
 always @(posedge manager_clk)if(manager_rst)configuration_error<=0;else if(start)configuration_error<=!config_ok;
 tf_sync_controller controller(.clk(manager_clk),.rst(manager_rst),.start(start&&config_ok),.requested_mask(requested_mask),
 .requested_epoch(requested_epoch),.node_clock_ready(ready_m),.node_prepared(prepared_m),.node_applied(applied_m),.node_fault(fault_m),
 .active_mask(active_mask),.session_id(session_id),.epoch(epoch),.abort_session(abort_session),.prepare_valid(prepare_valid),
 .sync_marker(marker),.running(running),.state(state),.recoveries(recoveries),.manager_ticks(mt));
 genvar i;generate for(i=0;i<4;i=i+1)begin:slot
  if(i<NODES)begin:present
   tf_node_top #(.NODE_ID(i),.WORK_DIV(i==0?DIV0:i==1?DIV1:i==2?DIV2:DIV3),.PAYLOAD_W(PAYLOAD_W),.FRAMES(FRAMES)) node(
    .ref_in(ref_clocks[i]),.monitor_in(monitor_clk),.rx_clock(rx_clocks[i]),.arst(arst|node_reset[i]),
    .abort_session(abort_session),.prepare_valid(prepare_valid&active_mask[i]),.prepare_session(session_id),
    .prepare_epoch(epoch),.prepare_stage_mask(stage_map[i*3+:3]),.prepare_source(source_mask[i]),
    .sync_marker(markers[i]),.marker_qualified(marker_qualified[i]),.run_enable(running&active_mask[i]),
    .event_id(eid),.event_session(es),.event_target(target),.event_valid(ev&active_mask[i]),.event_ready(event_ready[i]),
    .cancel_all(ca),.cancel_valid(cv),.cancel_id(cid),.rx_frame(rx_frames[i]),.rx_valid(rx_valid[i]),.rx_ready(rx_ready[i]),
    .tx_frame(tx_frames[i]),.tx_valid(tx_valid[i]),.tx_ready(tx_ready[i]),.timestamp(timestamps[i]),.session_id(node_sessions[i]),
    .prepared(prepared[i]),.applied(applied[i]),.time_valid(time_valid[i]),.event_execute(event_execute[i]),
    .node_fault(faults[i]),.clock_ready(clock_ready[i]),.reference_fault(reference_fault[i]),
    .executed_id(executed_ids[i]),.executed_timestamp(executed_timestamps[i]),.work_clock(work_clocks[i]),
    .fifo_full(fifo_full[i]),.fifo_level(fifo_levels[i]),.sample_count(sample_counts[i]),.delivered_count(delivered_counts[i]));
   tf_bit_sync a(.src_clk(ref_clocks[i]),.src_bit(clock_ready[i]),.dst_clk(manager_clk),.dst_bit(ready_m[i]));
   tf_bit_sync b(.src_clk(ref_clocks[i]),.src_bit(prepared[i]),.dst_clk(manager_clk),.dst_bit(prepared_m[i]));
   tf_bit_sync c(.src_clk(ref_clocks[i]),.src_bit(applied[i]),.dst_clk(manager_clk),.dst_bit(applied_m[i]));
   tf_bit_sync d(.src_clk(ref_clocks[i]),.src_bit(faults[i]),.dst_clk(manager_clk),.dst_bit(fault_m[i]));
  end else begin:absent
   assign tx_frames[i]=0;assign tx_valid[i]=0;assign rx_ready[i]=0;assign work_clocks[i]=0;
   assign event_execute[i]=0;assign timestamps[i]=0;assign node_sessions[i]=0;assign executed_ids[i]=0;assign executed_timestamps[i]=0;
   assign sample_counts[i]=0;assign delivered_counts[i]=0;assign time_valid[i]=0;assign clock_ready[i]=0;assign reference_fault[i]=0;
   assign fifo_full[i]=0;assign fifo_levels[i]=0;assign ready_m[i]=0;assign prepared_m[i]=0;assign applied_m[i]=0;assign fault_m[i]=0;
  end
 end endgenerate
endmodule
