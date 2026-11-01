`timescale 1ns/1ps
module tb_link_base #(parameter integer LANES=4,HALF_PERIOD=10);
 reg work=0,link=0,root=1,flush=1;always #3.333 work=~work;always #(HALF_PERIOD)link=~link;
 wire wrst,lrst,rxrst,rxflush;wire fclock,rclock;wire [LANES-1:0] td,rd;wire tv,ts,rr,tr,rv,rs;
 reg [207:0] din;reg iv=0,sink_ready=0;wire ir,ov;wire [207:0] dout;
 wire [31:0] accepted,sent,aborted,started,forwarded,raborted,ferr;wire full,stats;wire [4:0] level;
 tf_reset_sync wr(.clk(work),.arst(root),.rst(wrst));tf_reset_sync lr(.clk(link),.arst(root),.rst(lrst));
 tf_reset_sync rxr(.clk(rclock),.arst(root),.rst(rxrst));tf_reset_sync rxf(.clk(rclock),.arst(flush),.rst(rxflush));
 wire wf,lf;tf_reset_sync wfl(.clk(work),.arst(flush),.rst(wf));tf_reset_sync lfl(.clk(link),.arst(flush),.rst(lf));
 tf_link_tx #(.LANES(LANES)) tx(.work_clk(work),.link_clk(link),.work_root_rst(wrst),.link_root_rst(lrst),
 .work_flush(wf),.link_flush(lf),.frame(din),.frame_valid(iv),.frame_ready(ir),.pin_ready(tr),
 .pin_data(td),.pin_valid(tv),.pin_sof(ts),.pin_clock(fclock),.fifo_full(full),.queue_level(level),
 .accepted(accepted),.wire_sent(sent),.aborted(aborted),.stats_valid(stats));
 // Cable models: clock/data relative skew0.6ns, ready roundtrip2ns total.
 assign #1 rclock=fclock;assign #1.6 rd=td;assign #1.6 rv=tv;assign #1.6 rs=ts;assign #1 tr=rr;
 tf_link_rx #(.LANES(LANES)) rx(.clk(rclock),.root_rst(rxrst),.flush(rxflush),.pin_data(rd),.pin_valid(rv),.pin_sof(rs),
 .pin_ready(rr),.frame(dout),.frame_valid(ov),.frame_ready(sink_ready),.started(started),.forwarded(forwarded),
 .aborted(raborted),.framing_errors(ferr));
 reg [207:0] expected[512];integer put=0,got=0,fd,blocked=0,physical_beats=0,maxlevel=0;
 reg [31:0] rng=17;reg [207:0] held;reg stall_previous=0;
 always @(posedge work)if(!root&&!flush&&iv&&ir)begin expected[put]=din;put=put+1;end
 always @(posedge work)begin
  if(!wf)begin
   if(stall_previous&&(!iv||din!==held))$fatal(1,"LINK_TX_FRAME_STALL_STABILITY");
   stall_previous=iv&&!ir;held=din;
  end else stall_previous=0;
 end
 always @(posedge link)begin
  if(!lf)begin
   if(tx.wait_credit&&!tx.active)blocked=blocked+1;if(level>maxlevel)maxlevel=level;
  end
 end
 always @(posedge rclock)if(!rxflush)begin
  if(rv)physical_beats=physical_beats+1;
  if(ov&&sink_ready)begin
   if(got>=put||dout!==expected[got])$fatal(1,"LINK_REASSEMBLY got=%0d put=%0d",got,put);
   $fdisplay(fd,"%0d,%h",got,dout);got=got+1;
  end
 end
 task send(input integer id);begin
  @(negedge work);din={32'hfeedabba,32'(id),64'h0123456789abcdef,16'd4,32'(id*17+3),32'h98765432};iv=1;
  @(posedge work);while(!ir)@(posedge work);@(negedge work);iv=0;
 end endtask
 initial begin
  fd=$fopen("link.csv","w");#500;root=0;flush=0;
  fork begin for(integer i=0;i<64;i=i+1)send(i);end
   begin #60000;sink_ready=1;end join
  wait(got==64);#500;if(blocked==0||maxlevel<16||ferr!=0)$fatal(1,"LINK_FULL_COVERAGE");
  $display("PASS link%0d_full_stall_frames64 max=%0d physical_beats=%0d",LANES,maxlevel,physical_beats);
  // Flush with an in-flight partial frame and accepted queued frames. Explicit
  // TX debt is reconciled after quiesce; RX partial/pending abort is counted.
  sink_ready=0;for(integer i=0;i<8;i=i+1)send(100+i);
  wait(tx.active&&tx.beat>3);@(negedge link);flush=1;iv=0;#1000;put=0;got=0;flush=0;
  wait(stats);#1000;
  if(aborted==0||sent+aborted!=accepted||raborted==0)$fatal(1,"LINK_ABORT_LEDGER sent=%0d abort=%0d accepted=%0d rxabort=%0d",sent,aborted,accepted,raborted);
  sink_ready=1;
  for(integer i=0;i<24;i=i+1)send(200+i);
  wait(got==24);#500;if(ferr!=0)$fatal(1,"LINK_FRAMING");
  $display("TEST_PASS tb_link LANES=%0d HALF=%0d accepted=%0d sent=%0d aborted=%0d",LANES,HALF_PERIOD,accepted,sent,aborted);
  $fclose(fd);$finish;
 end
 initial begin #1000000;$fatal(1,"LINK_TIMEOUT put=%0d got=%0d ready=%b txactive=%b rxactive=%b count=%d",put,got,rr,tx.active,rx.active,rx.count);end
endmodule
module tb_link;tb_link_base #(.LANES(4)) t();endmodule
module tb_link8;tb_link_base #(.LANES(8)) t();endmodule
module tb_link25;tb_link_base #(.LANES(4),.HALF_PERIOD(20)) t();endmodule
