`timescale 1ns/1ps
module tb_sync;
 parameter integer N=4;
 reg common=0,mon=0,run_ref=1,rst=0,sync=0,arm=0;
 reg [3:0] en,lock=0;reg [63:0] epoch=0,target=0;
 reg [3:0] node_rst=15;
 wire [3:0] rc,act,ev,missing;wire [63:0] tick[4];wire [3:0] err[4];
 integer cnt[4];realtime edge_time[4];integer trace,seed;
 always #10 common=~common;
 always #5 mon=~mon;
 genvar i;
 generate for(i=0;i<4;i=i+1) begin:g
  localparam integer DELAY=(i==0)?0:(i==1)?2:(i==2)?5:10;
  wire sr;
  assign #(DELAY) rc[i]=common&run_ref;
  assign #(DELAY) sr=sync;
  sync_node #(.SYNC_TIMEOUT(256),.REF_TIMEOUT(32)) dut(.ref_clk(rc[i]),.mon_clk(mon),
   .reset_n(rst&node_rst[i]),.enable(en[i]),.pll_locked(lock[i]),.sync_async(sr),.epoch_bus(epoch),
   .arm(arm),.event_time(target),.ticks(tick[i]),.active(act[i]),.event_out(ev[i]),
   .errors(err[i]),.ref_missing(missing[i]));
  initial begin cnt[i]=0;edge_time[i]=0;end
  always @(posedge ev[i]) begin
   if(!en[i] || !act[i]) $fatal(1,"EVENT_WHILE_INVALID node=%0d",i);
   cnt[i]=cnt[i]+1;edge_time[i]=$realtime;
   $fdisplay(trace,"EVENT,%0d,%0d,%0t,%0d",i,cnt[i],$realtime,tick[i]);
  end
 end endgenerate
 task pulse_sync;
  begin @(negedge common);#5 sync=1;#60 sync=0;#100;end
 endtask
 task check_active;
  begin for(integer k=0;k<4;k=k+1) if(act[k] !== (k<N)) $fatal(1,"ACTIVE node %0d",k);end
 endtask
 task schedule;
  begin @(negedge common); target=tick[0]+64'd24; arm=1; #80 arm=0; #600; end
 endtask
 initial begin
  if(!$value$plusargs("SEED%d",seed)) seed=1;
  trace=$fopen("event_trace.csv","w");$fdisplay(trace,"kind,node,count,time_ps,ticks");
  en=(1<<N)-1;
  #100 rst=1;#300 lock=15;#200;
  pulse_sync();check_active();schedule();
  for(integer k=0;k<4;k=k+1) begin
   if(cnt[k] != ((k<N)?1:0)) $fatal(1,"NODE_COUNT %0d",k);
   if(k>0 && k<N && ((edge_time[k]-edge_time[0]) != ((k==1)?2:(k==2)?5:10)))
     $fatal(1,"REFERENCE_DELAY node=%0d skew=%0f",k,edge_time[k]-edge_time[0]);
  end
  $display("PASS node_count_and_distribution N=%0d skew_ns=%0f",N,edge_time[N-1]-edge_time[0]);
  // A periodic heartbeat must not reload time or suppress a coincident scheduled event.
  begin reg [63:0] before_tick;before_tick=tick[0]; pulse_sync();
   if(tick[0]<=before_tick) $fatal(1,"TIME_JUMP_ON_HEARTBEAT");end
  schedule();if(cnt[0]!=2) $fatal(1,"DUPLICATE_OR_MISSING");
  $display("PASS monotonic_heartbeat_and_repeated_events");
  if(N>1) begin
   en[N-1]=0;#100;if(act[N-1]) $fatal(1,"DISABLE");
   schedule();if(cnt[0]!=3||cnt[N-1]!=2) $fatal(1,"ISOLATION");
   en[N-1]=1;epoch=tick[0];pulse_sync();check_active();
   $display("PASS disable_late_join_isolation (late join epoch accuracy not implied)");
   node_rst[N-1]=0;#100;
   if(!act[0]||act[N-1]) $fatal(1,"NODE_RESET_ISOLATION");
   node_rst[N-1]=1;#300;epoch=tick[0];pulse_sync();check_active();
   $display("PASS individual_node_reset_and_reacquire");
  end
  // Reference disappearance is detected by the independent monitor even without ref edges.
  @(negedge common);target=tick[0]+64'd24;arm=1;#80;arm=0;
  run_ref=0;#500;
  if(act!=0 || (missing&en)!=en) $fatal(1,"REFERENCE_LOSS_UNDETECTED");
  begin integer old_count;old_count=cnt[0];run_ref=1;#700;
   if(act[0]||cnt[0]!=old_count) $fatal(1,"STALE_EVENT_AFTER_REFERENCE_RECOVERY");end
  epoch=1000;pulse_sync();check_active();
  $display("PASS reference_interruption_and_reacquire");
  lock[0]=0;#1;if(act[0]||ev[0]) $fatal(1,"UNLOCK_INHIBIT");
  #100;lock[0]=1;#100;if(act[0]) $fatal(1,"UNLOCK_STALE_VALID");
  pulse_sync();if(!act[0]) $fatal(1,"UNLOCK_RESYNC");
  $display("PASS pll_unlock_requires_resync");
  #5300;if((act&en)!=0) $fatal(1,"SYNC_TIMEOUT");
  epoch=2000;pulse_sync();check_active();
  $display("PASS sync_loss_timeout_and_recovery");
  rst=0;#100;rst=1;#400;epoch=64'hfffffffffffffff0;pulse_sync();
  @(negedge common);target=64'd12;arm=1;#80;arm=0;#1000;
  if(tick[0]>200) $fatal(1,"COUNTER_DID_NOT_WRAP");
  if(edge_time[0]<$realtime-1200) $fatal(1,"WRAP_EVENT_MISSING");
  $display("PASS counter_wrap_and_epoch_recovery");
  // Reject stale / current commands, and hold command high: no repeated enqueue.
  begin integer old_count;old_count=cnt[0];
   @(negedge common);target=tick[0]-1;arm=1;#100;arm=0;#100;
   if(cnt[0]!=old_count||!err[0][3]) $fatal(1,"STALE_COMMAND_ACCEPTED");
  end
  $display("PASS stale_command_rejection");
  $fclose(trace);$display("TEST_PASS tb_sync N=%0d SEED=%0d",N,seed);$finish;
 end
 initial begin #100000;$fatal(1,"TIMEOUT");end
endmodule
module tb_sync_1; tb_sync #(.N(1)) tb(); endmodule
module tb_sync_2; tb_sync #(.N(2)) tb(); endmodule
module tb_sync_3; tb_sync #(.N(3)) tb(); endmodule
module tb_sync_4; tb_sync #(.N(4)) tb(); endmodule
