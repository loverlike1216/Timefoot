`timescale 1ns/1ps
module tf_node_core #(parameter integer NODE_ID=0,PAYLOAD_W=32,FIFO_DEPTH=16,FRAMES=64)(
 input wire ref_clk,work_clk,rx_clk,ref_rst,work_rst,
 input wire abort_session,prepare_valid,input wire [31:0] prepare_session,
 input wire [63:0] prepare_epoch,input wire [2:0] prepare_stage_mask,input wire prepare_source,
 input wire sync_marker,marker_qualified,run_enable,
 input wire [31:0] event_id,event_session,input wire [63:0] event_target,input wire event_valid,
 output wire event_ready,input wire cancel_all,cancel_valid,input wire [31:0] cancel_id,
 input wire [175+PAYLOAD_W:0] rx_frame,input wire rx_valid,output wire rx_ready,
 output wire [175+PAYLOAD_W:0] tx_frame,output wire tx_valid,input wire tx_ready,
 output wire [63:0] timestamp,output wire [31:0] session_id,
 output wire prepared,applied,time_valid,event_execute,output wire [31:0] executed_id,
 output wire [63:0] executed_timestamp,output wire node_fault,
 output wire fifo_full,output wire [$clog2(FIFO_DEPTH):0] fifo_level,
 output wire [31:0] sample_count,output reg [31:0] delivered_count);
 localparam B=144+PAYLOAD_W,F=B+32;
 wire tb_prepared,tb_error;reg link_hold=1,cfg_pending=0,source_ref=0;
 reg [35:0] config_ref;wire [35:0] config_work;wire cfg_ready,cfg_valid;
 wire accept_prepare=prepare_valid&~tb_prepared&marker_qualified;
 wire local_work_flush,ref_flush;
 assign ref_flush=link_hold;
 // link_hold is the sole session-reset owner. ref_rst asserts it even if
 // the reference stops; clock_manager also holds ref_rst on work-clock loss.
 tf_reset_sync datapath_reset(.clk(work_clk),.arst(link_hold),.rst(local_work_flush));
 always @(posedge ref_clk or posedge ref_rst)begin
  if(ref_rst)begin link_hold<=1;cfg_pending<=0;config_ref<=0;source_ref<=0;end
  else if(abort_session)begin link_hold<=1;cfg_pending<=0;end
  else begin
   if(accept_prepare)begin link_hold<=0;config_ref<={prepare_session,prepare_stage_mask,prepare_source};
    source_ref<=prepare_source;cfg_pending<=1;end
   if(cfg_pending&&cfg_ready)cfg_pending<=0;
  end
 end
 tf_cdc_bridge #(.WIDTH(36),.COORDINATED_RESET(1)) config_bridge(.src_clk(ref_clk),.dst_clk(work_clk),
 .src_flush(link_hold),.dst_flush(local_work_flush),.src_data(config_ref),
 .src_valid(cfg_pending),.src_ready(cfg_ready),.dst_data(config_work),.dst_valid(cfg_valid),.dst_ready(~local_work_flush));
 reg [31:0] work_session=0;reg [2:0] work_mask=0;reg work_source=0,config_loaded=0;
 always @(posedge work_clk)begin
  if(local_work_flush)begin work_session<=0;work_mask<=0;work_source<=0;config_loaded<=0;end
  else if(cfg_valid)begin {work_session,work_mask,work_source}<=config_work;config_loaded<=1;end
 end
 wire configured_ref;
 tf_bit_sync config_status(.src_clk(work_clk),.src_bit(config_loaded),.dst_clk(ref_clk),.dst_bit(configured_ref));
 assign prepared=tb_prepared&configured_ref;
 tf_timebase timebase(.clk(ref_clk),.rst(ref_rst),.abort_session(abort_session),.prepare(accept_prepare),
 .prepare_session(prepare_session),.prepare_epoch(prepare_epoch),.sync_marker(sync_marker),.marker_qualified(marker_qualified),.run_enable(run_enable),
 .timestamp(timestamp),.session_id(session_id),.prepared(tb_prepared),.applied(applied),.time_valid(time_valid),.protocol_error(tb_error));
 wire edone,eerror;wire [3:0] ecode;wire [31:0] exc,abc,rjc;wire [3:0] qlevel;
 tf_event_scheduler scheduler(.clk(ref_clk),.rst(ref_rst),.enabled(run_enable),.time_valid(time_valid),
 .timestamp(timestamp),.session_id(session_id),.event_id(event_id),.event_session(event_session),
 .target_timestamp(event_target),.event_valid(event_valid),.event_ready(event_ready),
 .cancel_all(cancel_all),.cancel_valid(cancel_valid),.cancel_id(cancel_id),
 .event_execute(event_execute),.event_done(edone),.event_error(eerror),.error_code(ecode),
 .executed_id(executed_id),.executed_timestamp(executed_timestamp),.executed_count(exc),
 .aborted_count(abc),.rejected_count(rjc),.queue_level(qlevel));
 wire [B-1:0] acq_body;wire av,ar,absy,aov;wire [F-1:0] aframe;wire afv,afr;
 tf_data_source #(.PAYLOAD_W(PAYLOAD_W),.FRAMES(FRAMES)) source(.clk(ref_clk),.rst(ref_flush),
 .start(event_execute),.enabled(source_ref&run_enable),.timestamp(timestamp),.session_id(session_id),
 .body(acq_body),.valid(av),.ready(ar),.busy(absy),.sample_count(sample_count),.overrun(aov));
 tf_stream_tx #(.PAYLOAD_W(PAYLOAD_W)) source_encoder(.clk(ref_clk),.rst(ref_flush),
 .in_body(acq_body),.in_valid(av),.in_ready(ar),.frame(aframe),.valid(afv),.ready(afr));
 wire [B-1:0] sb,eb;wire sv,sr,ev,er;wire serr,eerr;wire [3:0] sec,eec;
 wire [31:0] sa,srej,ea,erej;wire sf,se,ef,ee;wire [$clog2(FIFO_DEPTH):0] sl,el;
 tf_stream_link #(.PAYLOAD_W(PAYLOAD_W),.DEPTH(FIFO_DEPTH),.COORDINATED_RESET(1)) source_link(.rx_clk(ref_clk),.work_clk(work_clk),
 .rx_flush(ref_flush),.work_flush(local_work_flush),.rx_frame(aframe),.rx_valid(afv),.rx_ready(afr),
 .session_id(work_session),.out_body(sb),.out_valid(sv),.out_ready(sr),.error(serr),.error_code(sec),
 .accepted_count(sa),.rejected_count(srej),.full(sf),.empty(se),.level(sl));
 tf_stream_link #(.PAYLOAD_W(PAYLOAD_W),.DEPTH(FIFO_DEPTH),.COORDINATED_RESET(1)) external_link(.rx_clk(rx_clk),.work_clk(work_clk),
 .rx_flush(ref_flush),.work_flush(local_work_flush),.rx_frame(rx_frame),.rx_valid(rx_valid),.rx_ready(rx_ready),
 .session_id(work_session),.out_body(eb),.out_valid(ev),.out_ready(er),.error(eerr),.error_code(eec),
 .accepted_count(ea),.rejected_count(erej),.full(ef),.empty(ee),.level(el));
 wire [B-1:0] pb;wire pv,pr,taskready;
 assign sr=taskready&work_source&config_loaded;
 assign er=taskready&~work_source&config_loaded;
 tf_task_pipeline #(.PAYLOAD_W(PAYLOAD_W)) tasks(.clk(work_clk),.rst(local_work_flush),.stage_mask(work_mask),
 .in_body(work_source?sb:eb),.in_valid((work_source?sv:ev)&config_loaded),.in_ready(taskready),
 .out_body(pb),.out_valid(pv),.out_ready(pr));
 wire raw_tx_valid;
 tf_stream_tx #(.PAYLOAD_W(PAYLOAD_W)) tx(.clk(work_clk),.rst(local_work_flush),
 .in_body(pb),.in_valid(pv),.in_ready(pr),.frame(tx_frame),.valid(raw_tx_valid),.ready(tx_ready));
 assign tx_valid=raw_tx_valid&~local_work_flush;
 // Read-domain occupancy alarm, not a raw write-domain full signal. XPM's
 // coherent read count includes FWFT prefetch storage. Actual write-side full
 // remains local to each FIFO and controls lossless ready/backpressure.
 assign fifo_full=(work_source?sl:el)>=FIFO_DEPTH;assign fifo_level=work_source?sl:el;
 always @(posedge work_clk)if(local_work_flush)delivered_count<=0;else delivered_count<=work_source?sa:ea;
 reg work_error=0;wire work_error_ref;reg fault_ref=0;
 always @(posedge work_clk)if(local_work_flush||!config_loaded)work_error<=0;else work_error<=work_error|serr|eerr;
 tf_bit_sync error_status(.src_clk(work_clk),.src_bit(work_error),.dst_clk(ref_clk),.dst_bit(work_error_ref));
 always @(posedge ref_clk or posedge ref_rst)if(ref_rst)fault_ref<=0;
 else if(accept_prepare)fault_ref<=0;
 else if(tb_prepared||run_enable)fault_ref<=fault_ref|work_error_ref|tb_error|aov;
 assign node_fault=fault_ref;
endmodule
