`timescale 1ns/1ps
module tb_system #(parameter integer N=4);
 localparam F=208,B=176,FRAMES=40;
 reg mc=0,mon=0,arst=1;always #10 mc=~mc;initial begin #3;forever #10 mon=~mon;end
 reg [3:0] ref_on=15,nreset=0,mq=15;wire [3:0] refs,markers,rxclk,wclk;
 wire marker;genvar j;
 generate for(j=0;j<4;j=j+1)begin:clocks
  assign #(j*0.6) refs[j]=mc&ref_on[j];assign #(2.0+j*0.7) markers[j]=marker;
  if(j==0)assign rxclk[j]=mc;else assign rxclk[j]=wclk[j-1];
 end endgenerate
 wire [3:0][F-1:0] txf,rxf;wire [3:0] txv,txr,rxv,rxr,execute,tvalid,cready,rfault,full;
 wire [3:0][4:0] levels;wire [3:0][63:0] ts,ets;wire [3:0][31:0] ids,sessions,samples,delivered;
 reg bv=0,bw=1;reg [7:0] ba=0;reg [31:0] bd=0;wire br,brv,be;wire [31:0] bdata;
 wire running;wire [3:0] state,mask;wire [31:0] session,recoveries;wire configerror;
 tf_system_top #(.NODES(N),.FRAMES(FRAMES)) dut(.manager_clk(mc),.monitor_clk(mon),.arst(arst),.ref_clocks(refs),.node_reset(nreset),
 .rx_clocks(rxclk),.rx_frames(rxf),.rx_valid(rxv),.rx_ready(rxr),.tx_frames(txf),.tx_valid(txv),.tx_ready(txr),
 .markers(markers),.marker_qualified(mq),.marker(marker),.bus_valid(bv),.bus_write(bw),.bus_address(ba),.bus_wdata(bd),
 .bus_ready(br),.bus_rvalid(brv),.bus_rdata(bdata),.bus_error(be),.work_clocks(wclk),.event_execute(execute),.time_valid(tvalid),
 .clock_ready(cready),.reference_fault(rfault),.timestamps(ts),.executed_timestamps(ets),.executed_ids(ids),.node_sessions(sessions),
 .sample_counts(samples),.delivered_counts(delivered),.fifo_full(full),.fifo_levels(levels),.running(running),.state(state),
 .active_mask(mask),.session_id(session),.recoveries(recoveries),.configuration_error(configerror));
 reg channel_enable=1,corrupt=0,output_block=0;reg final_ready=0;reg [31:0] rng=1;integer seed=1,fd,ef,phase=0,count=0,total=0,stalls=0,max_level=0;
 time event_time[4];reg [3:0] seen=0;reg [31:0] expect_seq=0,expected_session=0;reg checking=0;
 integer source_fd;reg [31:0] previous_samples=0;
 always @(posedge refs[0])begin #2;
  if(!running)previous_samples=0;
  else if(samples[0]>previous_samples)begin
   if(dut.slot[0].present.node.core.acq_body[111:48]!==ts[0]-1'b1)$fatal(1,"SOURCE_TIMEBASE_CAPTURE");
   $fdisplay(source_fd,"%0d,%0d,%h",phase,$time,dut.slot[0].present.node.core.acq_body);
   previous_samples=samples[0];
  end else previous_samples=samples[0];
 end
 generate for(j=0;j<4;j=j+1)begin:channels
  if(j==0)begin assign rxf[j]=0;assign rxv[j]=0;end
  if(j<N-1)begin
   tf_sim_channel #(.WIDTH(F),.DELAY(5+j*3),.SEED(j+3)) link(.clk(wclk[j]),.flush(!running),.enable(channel_enable),
    .corrupt(corrupt&&j==0),.in_data(txf[j]),.in_valid(txv[j]),.in_ready(txr[j]),.out_data(rxf[j+1]),.out_valid(rxv[j+1]),.out_ready(rxr[j+1]));
  end else if(j==N-1)assign txr[j]=final_ready;
  else begin assign txr[j]=0;if(j>=N)begin assign rxf[j]=0;assign rxv[j]=0;end end
  if(j<N)always @(posedge execute[j])begin
   event_time[j]=$time;seen[j]=1;
   if(ets[j]!==ts[j])$fatal(1,"EVENT_EDGE_TIMESTAMP node=%0d",j);
   $fdisplay(ef,"%0d,%0d,%0d,%0d,%0d",phase,j,sessions[j],ids[j],ets[j]);
  end
 end endgenerate
 function [31:0] crc(input [B-1:0] body);reg [31:0] c;begin c=32'hffffffff;
  for(integer i=B-1;i>=0;i=i-1)c={c[30:0],1'b0}^((c[31]^body[i])?32'h04c11db7:0);crc=~c;end endfunction
 function [31:0] result(input [31:0] seq,input [63:0] stamp);reg [31:0] p;begin
  p=(seq*17+3)*3+7;p=p^32'h5a5aa5a5;result=p+stamp[31:0];end endfunction
 always @(posedge wclk[N-1])begin
  rng<={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
  if(checking&&txv[N-1]&&txr[N-1])begin
   if(txf[N-1][207:176]!==expected_session||txf[N-1][175:144]!==expect_seq||txf[N-1][79:64]!==16'd4||
      txf[N-1][31:0]!==crc(txf[N-1][207:32])||txf[N-1][63:32]!==result(expect_seq,txf[N-1][143:80]))
      $fatal(1,"END_TO_END frame=%h seq=%0d session=%0d",txf[N-1],expect_seq,expected_session);
   $fdisplay(fd,"%0d,%0d,%0d,%0d,%h",phase,$time,expected_session,expect_seq,txf[N-1]);
   count=count+1;total=total+1;expect_seq=expect_seq+1;
  end
  if(txv[N-1]&&!txr[N-1])stalls=stalls+1;
 end
 always @(negedge wclk[N-1])final_ready=checking&&!output_block&&rng[0]&&rng[3];
 always @(posedge mc)begin #4;
  if(checking&&running)begin
   for(integer i=0;i<N;i=i+1)if(mask[i])begin
    if(ts[i]!==ts[0]||!tvalid[i]||sessions[i]!==session)$fatal(1,"TIME_ALIGNMENT node=%0d",i);
    if(levels[i]>max_level)max_level=levels[i];
   end
  end
 end
 task wr(input [7:0] a,input [31:0] d);begin
  @(negedge mc);ba=a;bd=d;bw=1;bv=1;@(posedge mc);while(!br)@(posedge mc);
  @(negedge mc);bv=0;if(be)$fatal(1,"CSR_WRITE %h",a);
 end endtask
 task wait_run;begin wait(running);repeat(5)@(negedge mc);if(configerror)$fatal(1,"CONFIGURATION");
  expected_session=session;expect_seq=0;count=0;seen=0;checking=1;
 end endtask
 task schedule(input [31:0] id,input [63:0] target);begin
  wr('h20,id);wr('h24,session);wr('h28,target[31:0]);wr('h2c,target[63:32]);wr('h30,1);
 end endtask
 task burst;reg [63:0] target;begin target=ts[0]+100;seen=0;output_block=1;schedule(100+phase,target);
  wait(seen==((1<<N)-1));#5;for(integer i=0;i<N;i=i+1)begin
   if(ets[i]!==target)$fatal(1,"TARGET_MISMATCH");
   if(event_time[i]>event_time[0]+3||event_time[0]>event_time[i]+3)$fatal(1,"PHYSICAL_SIM_SKEW");
  end
  #150000;output_block=0;wait(count==FRAMES);repeat(20)@(negedge mc);
  $display("PASS phase=%0d nodes=%0d session=%0d frames=%0d stalls=%0d max_fifo=%0d",phase,N,session,count,stalls,max_level);
 end endtask
 reg [31:0] previous_session;integer rec;
 initial begin
  if($test$plusargs("SEED17"))seed=17;else if($test$plusargs("SEED2026"))seed=2026;
  rng=seed;fd=$fopen("system.csv","w");ef=$fopen("system_events.csv","w");source_fd=$fopen("system_source.csv","w");
  #500;arst=0;wait(!dut.manager_rst);repeat(2)@(negedge mc);
  wr('h00,0);wr('h04,1);repeat(4)@(negedge mc);
  if(!configerror||running)$fatal(1,"INVALID_CONFIGURATION_ACCEPTED");
  wr('h00,(1<<N)-1);wr('h10,32'hfffffff0);wr('h14,32'hffffffff);wr('h04,1);wait_run();burst();
  // Reference loss while future work is queued. No event from the old session may execute.
  phase=1;checking=0;previous_session=session;schedule(900,ts[0]+10000);
  @(negedge mc);ref_on[N-1]=0;#6000;
  if(running||!rfault[N-1]||tvalid[N-1]||execute[N-1])$fatal(1,"REFERENCE_LOSS_NOT_SAFE");
  @(negedge mc);ref_on[N-1]=1;wait_run();if(session==previous_session)$fatal(1,"OLD_SESSION_RESUME");burst();
  // Repeated local reset / late join uses a new global session.
  phase=2;checking=0;previous_session=session;@(negedge mc);nreset[N-1]=1;#1000;nreset[N-1]=0;
  wait(!running);wait_run();if(session==previous_session)$fatal(1,"RESET_SESSION");burst();
  // Unqualified marker/window is rejected; qualification is an adapter contract.
  phase=3;checking=0;previous_session=session;mq[N-1]=0;#10000;
  if(running)$fatal(1,"UNQUALIFIED_MARKER_ACCEPTED");mq[N-1]=1;wait_run();
  if(session==previous_session)$fatal(1,"MARKER_RECOVERY_SESSION");burst();
  if(N>1)begin
   // Deliberate in-flight CRC corruption aborts the session, not silently drops.
   phase=4;checking=0;previous_session=session;corrupt=1;schedule(500,ts[0]+100);
   wait(!running);corrupt=0;wait_run();if(session==previous_session)$fatal(1,"CRC_FAULT_SESSION");burst();
   // Quiesced membership change requires an explicit new map and epoch.
   phase=5;checking=0;wr('h00,1);wr('h60,7);wr('h04,1);wait_run();
   if(mask!=1)$fatal(1,"MEMBERSHIP_MASK");
   wr('h00,(1<<N)-1);wr('h60,N==2?49:N==3?273:2184);wr('h04,1);wait_run();burst();
  end
  if(stalls==0||recoveries<3||max_level<16)$fatal(1,"COVERAGE_MISSING");
  $display("TEST_PASS tb_system nodes=%0d seed=%0d outputs=%0d recoveries=%0d max_fifo=%0d",N,seed,total,recoveries,max_level);
  $fclose(fd);$fclose(ef);$fclose(source_fd);$finish;
 end
 initial begin #5000000;$fatal(1,"SYSTEM_TIMEOUT state=%0d running=%b prepared=%b applied=%b ready=%b fault=%b",state,running,dut.prepared,dut.applied,cready,dut.faults);end
endmodule
module tb_system_1;tb_system #(.N(1)) t();endmodule
module tb_system_2;tb_system #(.N(2)) t();endmodule
module tb_system_3;tb_system #(.N(3)) t();endmodule
module tb_system_4;tb_system #(.N(4)) t();endmodule
