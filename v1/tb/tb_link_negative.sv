`timescale 1ns/1ps
module tb_link_negative;
 reg clk=0,rst=1,flush=1,valid=0,sof=0,ready=0;reg [3:0] data=0;
 always #10 clk=~clk;
 wire credit,fv,flag;wire [207:0] frame;wire [31:0] start,fwd,abort_count,errors;
 tf_link_rx dut(.clk(clk),.root_rst(rst),.flush(flush),.pin_data(data),.pin_valid(valid),.pin_sof(sof),
 .pin_ready(credit),.frame(frame),.frame_valid(fv),.frame_ready(ready),.started(start),.forwarded(fwd),
 .aborted(abort_count),.framing_errors(errors),.error_flag(flag));
 task beat(input bit s,input [3:0] d);begin @(negedge clk);valid=1;sof=s;data=d;end endtask
 task clear_link;begin @(negedge clk);valid=0;sof=0;flush=1;repeat(4)@(negedge clk);flush=0;wait(credit);end endtask
 initial begin
  #155;rst=0;flush=0;wait(credit);
  beat(0,3);@(negedge clk);valid=0;repeat(4)@(negedge clk);
  if(errors!=1||!flag||fv)$fatal(1,"NO_SOF_NOT_REJECTED");
  clear_link();beat(1,1);beat(0,2);beat(1,3);@(negedge clk);valid=0;
  repeat(4)@(negedge clk);if(errors!=2||abort_count!=1||fv)$fatal(1,"NESTED_SOF_NOT_ABORTED");
  clear_link();beat(1,0);for(integer i=1;i<52;i++)beat(0,0);
  // Session flush coincides with the final captured beat. No completed frame
  // may escape and the reserved transaction must appear in the abort ledger.
  @(negedge clk);flush=1;valid=0;ready=1;repeat(4)@(negedge clk);
  if(fv||fwd!=0||abort_count<2)$fatal(1,"FLUSH_LAST_BEAT");
  flush=0;wait(credit);beat(1,0);for(integer j=1;j<52;j++)beat(0,0);
  @(negedge clk);valid=0;wait(fwd==1);#50;
  if(flag||frame!=0)$fatal(1,"NEGATIVE_RECOVERY");
  $display("TEST_PASS tb_link_negative malformed_sof flush_last_beat recovery errors=%0d abort=%0d",errors,abort_count);$finish;
 end
 initial begin #20000;$fatal(1,"NEGATIVE_TIMEOUT");end
endmodule

module tb_status_snapshot;
 reg sc=0,dc=0;reg [31:0] counter=0;wire [63:0] snapshot;
 always #3.333 sc=~sc;initial begin #1.127;forever #10 dc=~dc;end
 always @(posedge sc)counter<=counter+32'h13579bdf;
 tf_status_snapshot #(.WIDTH(64)) dut(.src_clk(sc),.dst_clk(dc),.source({counter,~counter}),.snapshot(snapshot));
 integer seen=0;
 always @(posedge dc)if($time>1000)begin
  if(snapshot[63:32]!==~snapshot[31:0])$fatal(1,"TORN_STATUS_SNAPSHOT");seen=seen+1;
 end
 initial begin #100000;if(seen<1000)$fatal(1,"SNAPSHOT_COVERAGE");
 $display("TEST_PASS tb_status_snapshot arbitrary_multibit_jumps samples=%0d",seen);$finish;end
endmodule
