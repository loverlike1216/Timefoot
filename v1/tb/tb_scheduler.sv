`timescale 1ns/1ps
module tb_scheduler;
 reg clk=0,rst=1,abrt=0,prep=0,marker=0,qualified=1,run=0;
 always #10 clk=~clk;
 reg [31:0] ps=1;reg [63:0] ep=64'hfffffffffffffff0;
 wire [63:0] now;wire [31:0] session;wire prepared,applied,tvalid,perr;
 tf_timebase tb(.clk(clk),.rst(rst),.abort_session(abrt),.prepare(prep),.prepare_session(ps),
 .prepare_epoch(ep),.sync_marker(marker),.marker_qualified(qualified),.run_enable(run),
 .timestamp(now),.session_id(session),.prepared(prepared),.applied(applied),.time_valid(tvalid),.protocol_error(perr));
 reg [31:0] id=0,es=1,cid=0;reg [63:0] target=0;reg ev=0,ca=0,cv=0;
 wire er,ex,done,error;wire [3:0] code;wire [31:0] xid,xc,ac,rc;wire [63:0] xt;wire [2:0] level;
 tf_event_scheduler #(.DEPTH(4)) dut(.clk(clk),.rst(rst),.enabled(run),.time_valid(tvalid),.timestamp(now),
 .session_id(session),.event_id(id),.event_session(es),.target_timestamp(target),.event_valid(ev),.event_ready(er),
 .cancel_all(ca),.cancel_valid(cv),.cancel_id(cid),.event_execute(ex),.event_done(done),.event_error(error),
 .error_code(code),.executed_id(xid),.executed_timestamp(xt),.executed_count(xc),.aborted_count(ac),.rejected_count(rc),.queue_level(level));
 integer n=0,fd;
 always @(negedge clk)if(ex)begin
  if(xt!==now||!tvalid||!run)$fatal(1,"EXECUTION_EDGE_CONTRACT");
  if(xid==2)$fatal(1,"CANCELED_EXECUTED");n=n+1;$fdisplay(fd,"EXEC,%0d,%0d,%0d",session,xid,xt);
 end
 task put(input integer ident,input integer sess,input [63:0] t);
  begin @(negedge clk);id=ident;es=sess;target=t;ev=1;@(posedge clk);while(!er)@(posedge clk);@(negedge clk);ev=0;end
 endtask
 task align;
  begin @(negedge clk);prep=1;@(negedge clk);prep=0;marker=1;@(negedge clk);marker=0;#1;end
 endtask
 initial begin
  fd=$fopen("scheduler.csv","w");#200;rst=0;align();if(!tvalid||now!==ep)$fatal(1,"EPOCH_LOAD");
  run=1;
  begin reg [63:0] base;base=now;put(1,1,base+30);put(2,1,base+40);put(3,1,base+50);
   @(negedge clk);cid=2;cv=1;@(negedge clk);cv=0;#1300;
  end
  if(n!=2||xc!=2||ac!=1)$fatal(1,"QUEUE_CANCEL_WRAP_COUNTS n=%d xc=%d ac=%d",n,xc,ac);
  $display("PASS scheduler_queue_cancel_wrap_exact_timestamp");
  put(9,99,now+30);put(10,1,now-2);#40;if(rc!=2)$fatal(1,"REJECTION_POLICY");
  put(11,1,now+80);put(11,1,now+90);#40;if(rc!=3)$fatal(1,"DUPLICATE_POLICY");
  @(negedge clk);ca=1;@(negedge clk);ca=0;#40;if(level!=0)$fatal(1,"CANCEL_ALL");
  $display("PASS session_late_duplicate_and_abort");
  put(20,1,now+100);put(21,1,now+110);put(22,1,now+120);put(23,1,now+130);
  #1;if(er||level!=4)$fatal(1,"QUEUE_FULL");
  @(negedge clk);abrt=1;run=0;@(negedge clk);abrt=0;#40;
  if(tvalid||level!=0||ex)$fatal(1,"ABORT_OLD_SESSION");
  ps=2;ep=1000;qualified=0;align();if(tvalid||!perr)$fatal(1,"UNQUALIFIED_MARKER_ACCEPTED");
  $display("PASS unqualified_capture_window_rejected");
  qualified=1;@(negedge clk);abrt=1;@(negedge clk);abrt=0;align();
  if(!tvalid||session!=2)$fatal(1,"FRESH_SESSION");
  $display("TEST_PASS tb_scheduler");$fclose(fd);$finish;
 end
 initial begin #30000;$fatal(1,"SCHEDULER_TIMEOUT");end
endmodule
