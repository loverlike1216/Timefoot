`timescale 1ns/1ps
module tb_pipeline;
 reg c0=0,c1=0,c2=0,c3=0,rst=0;
 always #10 c0=~c0;always #5 c1=~c1;always #3.333333 c2=~c2;always #10 c3=~c3;
 reg [127:0] src;reg sv=0;wire sr;
 reg sync_in=0,event_arm=0;reg [63:0] epoch=0,event_target=0;
 wire [63:0] global_ticks;wire sync_active,event_pulse,reference_missing;wire [3:0] sync_errors;
 sync_node #(.SYNC_TIMEOUT(100000)) timebase(.ref_clk(c0),.mon_clk(c1),.reset_n(rst),
 .enable(1'b1),.pll_locked(1'b1),.sync_async(sync_in),.epoch_bus(epoch),.arm(event_arm),
 .event_time(event_target),.ticks(global_ticks),.active(sync_active),.event_out(event_pulse),
 .errors(sync_errors),.ref_missing(reference_missing));
 wire [127:0] q0,q1,q2,s1,s2,outd;
 wire v0,v1,v2,vs1,vs2,ov;wire r0,r1,r2,rs1,rs2;
 wire [2:0] full,empty;
 reg allow1=1,allow2=1,allow3=1,sink=0;
 integer seed=1,source_gap=0;reg [31:0] prng;
 integer sent=0,got=0,stalls=0,full_seen=0,empty_seen=0,fd,session=0,cycles=0;
 reg [127:0] expected[0:2047];
 realtime start_time;
 function [31:0] step(input [31:0] x);step=x^(x<<13);step=step^(step>>17);step=step^(step<<5);endfunction
 function [31:0] calc(input [31:0] id,input [63:0] ts);
  reg [31:0] a;begin a=(id*17+3)*3+7;calc=(a^32'h5a5aa5a5)+ts[31:0];end
 endfunction
 async_fifo f0(.wclk(c0),.rclk(c1),.reset_n(rst),.wdata(src),.wvalid(sv),.wready(sr),
 .rdata(q0),.rvalid(v0),.rready(r0),.full(full[0]),.empty(empty[0]));
 task_stage #(.OP(1)) t1(.clk(c1),.reset_n(rst),.allow(allow1),.in_data(q0),.in_valid(v0),
 .in_ready(r0),.out_data(s1),.out_valid(vs1),.out_ready(rs1));
 async_fifo f1(.wclk(c1),.rclk(c2),.reset_n(rst),.wdata(s1),.wvalid(vs1),.wready(rs1),
 .rdata(q1),.rvalid(v1),.rready(r1),.full(full[1]),.empty(empty[1]));
 task_stage #(.OP(2)) t2(.clk(c2),.reset_n(rst),.allow(allow2),.in_data(q1),.in_valid(v1),
 .in_ready(r1),.out_data(s2),.out_valid(vs2),.out_ready(rs2));
 async_fifo f2(.wclk(c2),.rclk(c3),.reset_n(rst),.wdata(s2),.wvalid(vs2),.wready(rs2),
 .rdata(q2),.rvalid(v2),.rready(r2),.full(full[2]),.empty(empty[2]));
 task_stage #(.OP(3)) t3(.clk(c3),.reset_n(rst),.allow(allow3),.in_data(q2),.in_valid(v2),
 .in_ready(r2),.out_data(outd),.out_valid(ov),.out_ready(sink));
 always @(posedge c0) if(rst) begin
  cycles=cycles+1;
  if(sv && !sr) stalls=stalls+1;
  if(|full) full_seen=full_seen+1;if(&empty) empty_seen=empty_seen+1;
  if(sv && sr) begin expected[sent]={src[127:32],calc(src[127:96],src[95:32])};sent=sent+1;end
 end
 always @(posedge c3) if(rst && ov && sink) begin
  if(got>=sent) $fatal(1,"UNEXPECTED_OUTPUT");
  if(outd !== expected[got]) $fatal(1,"DATA_MISMATCH index=%0d got=%h expected=%h",got,outd,expected[got]);
  $fdisplay(fd,"%0d,%0d,%0t,%h",session,got,$realtime,outd);got=got+1;
 end
 // Random flow control changes only at clock negedges. Fixed seeds give fixed traces.
 always @(negedge c1) if(rst) allow1=(cycles%11)!=0;
 always @(negedge c2) if(rst) allow2=(cycles%17)>2;
 always @(negedge c3) if(rst) begin
  prng=step(prng);allow3=prng[1:0]!=0;
  if(cycles<300 || (cycles>500 && cycles<650)) sink=0;else sink=prng[2:0]>1;
 end
 task send_frame(input integer id);
  reg [63:0] ts;begin
   @(negedge c0);if(!sync_active) $fatal(1,"ACQUIRE_WHILE_UNSYNCHRONIZED");
   ts=global_ticks;src={32'(id),ts,32'(id*17+3)};sv=1;
   @(posedge c0);while(!sr) @(posedge c0);
   @(negedge c0);sv=0;repeat(source_gap) @(negedge c0);
  end
 endtask
 task start_session;
  begin
   #400;@(negedge c0);sync_in=1;#60;sync_in=0;wait(sync_active);
   @(negedge c0);event_target=global_ticks+10;event_arm=1;
   @(negedge c0);event_arm=0;wait(event_pulse);
   $display("PASS scheduled_acquisition_start session=%0d ticks=%0d",session,global_ticks);
  end
 endtask
 task drain;
  begin wait(got==sent);repeat(20) @(posedge c3);if(ov) $fatal(1,"EXTRA_OUTPUT");end
 endtask
 initial begin
  if(!$value$plusargs("SEED%d",seed)) seed=1;
  if(!$value$plusargs("GAP%d",source_gap)) source_gap=0;prng=seed;
  fd=$fopen("pipeline_trace.csv","w");$fdisplay(fd,"session,index,time_ps,frame");
  #100;rst=1;start_session();start_time=$realtime;
  for(integer k=0;k<320;k=k+1) send_frame(k);
  drain();
  if(stalls==0||full_seen==0||empty_seen==0) $fatal(1,"NO_FULL_EMPTY_BACKPRESSURE_COVERAGE");
  $display("PASS pipeline_50_100_150_50 frames=%0d stalls=%0d full_samples=%0d duration_ns=%0f",got,stalls,full_seen,$realtime-start_time);
  // Explicit link-down policy: quiesce, globally flush, account every in-flight accepted frame.
  for(integer k=320;k<330;k=k+1) send_frame(k);
  @(negedge c0);sv=0;rst=0;
  $fdisplay(fd,"ABORTED,%0d",sent-got);
  $display("FAULT link_reset aborted_frames=%0d (reported, not silently lost)",sent-got);
  session=1;sent=0;got=0;cycles=0;
  #100;epoch=100000;rst=1;start_session();
  for(integer k=0;k<80;k=k+1) send_frame(k);
  drain();if(got!=80) $fatal(1,"RECOVERY");
  $display("PASS link_reset_session_recovery frames=%0d",got);
  $fclose(fd);$display("TEST_PASS tb_pipeline SEED=%0d GAP=%0d",seed,source_gap);$finish;
 end
 initial begin #1000000;$fatal(1,"PIPELINE_TIMEOUT");end
endmodule
