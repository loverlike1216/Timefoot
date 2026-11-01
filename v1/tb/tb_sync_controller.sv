`timescale 1ns/1ps
module tb_sync_controller;
 reg clk=0,rst=1,start=0;always #10 clk=~clk;
 reg [3:0] cr=15,prep=0,applied=0,fault=0;wire [3:0] mask,state;wire [31:0] sid,rec;
 wire [63:0] epoch,ticks;wire ab,pv,marker,run;integer markers=0;
 tf_sync_controller #(.LEAD_TICKS(64),.TIMEOUT(256),.RESET_TICKS(64'hffffffffffffffc0)) dut(
 .clk(clk),.rst(rst),.start(start),.requested_mask(4'b1111),.requested_epoch(64'h12345678),.node_clock_ready(cr),
 .node_prepared(prep),.node_applied(applied),.node_fault(fault),.active_mask(mask),.session_id(sid),.epoch(epoch),
 .abort_session(ab),.prepare_valid(pv),.sync_marker(marker),.running(run),.state(state),.recoveries(rec),.manager_ticks(ticks));
 always @(posedge marker)begin markers=markers+1;applied=15;end
 initial begin #200;rst=0;@(negedge clk);start=1;@(negedge clk);start=0;
  wait(pv);repeat(5)@(negedge clk);prep=15;wait(run);
  if(markers!=1||ticks>1000||sid!=1)$fatal(1,"SYNC_MANAGER_WRAP");
  $display("PASS manager_wrap future_marker verify sid=%0d ticks=%0d",sid,ticks);
  fault=4;wait(ab);fault=0;prep=0;applied=0;
  wait(pv);wait(dut.until_apply==8);@(negedge clk);prep=15;
  repeat(4)@(negedge clk);if(run||markers!=1)$fatal(1,"LATE_PREPARED_PRIORITY");
  wait(rec>=2);$display("TEST_PASS tb_sync_controller wrap late_ack fault_priority");$finish;
 end
 initial begin #50000;$fatal(1,"SYNC_CONTROLLER_TIMEOUT");end
endmodule
