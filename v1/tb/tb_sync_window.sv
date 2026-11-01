`timescale 1ns/1ps
// Explicit digital adapter timing contract: >=1ns setup at the sampling edge.
// Qualification is modeled from known delays, not a hardware skew detector.
module tb_sync_window;
 reg clk=0,rst=1,prepare=0,marker=0;always #10 clk=~clk;
 wire [3:0] delayed,prepared,applied,valid,error;wire [3:0][63:0] ts;
 assign #0.2 delayed[0]=marker;assign #8.5 delayed[1]=marker;
 assign #9.5 delayed[2]=marker;assign #10.5 delayed[3]=marker;
 genvar i;generate for(i=0;i<4;i=i+1)begin
  tf_timebase t(.clk(clk),.rst(rst),.abort_session(1'b0),.prepare(prepare),.prepare_session(32'd9),.prepare_epoch(64'd123456),
  .sync_marker(delayed[i]),.marker_qualified(i<2),.run_enable(1'b0),.timestamp(ts[i]),.session_id(),
  .prepared(prepared[i]),.applied(applied[i]),.time_valid(valid[i]),.protocol_error(error[i]));
 end endgenerate
 initial begin #200;rst=0;@(negedge clk);prepare=1;@(negedge clk);prepare=0;
  repeat(10)@(negedge clk);marker=1;@(posedge clk);#1;
  if(valid!==4'b0011||applied!==4'b0011||ts[0]!=123456||ts[1]!=123456)$fatal(1,"SYNC_WINDOW");
  @(negedge clk);marker=0;repeat(3)@(posedge clk);#1;
  if(ts[0]!==ts[1]||valid[3:2]!=0||error[3:2]!=3)$fatal(1,"SYNC_BOUNDARY_REJECT");
  $display("TEST_PASS tb_sync_window delays_ns=0.2,8.5,9.5,10.5 setup_contract_ns=1");$finish;
 end
 initial begin #10000;$fatal(1,"SYNC_WINDOW_TIMEOUT");end
endmodule
