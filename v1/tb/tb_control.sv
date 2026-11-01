`timescale 1ns/1ps
module tb_control;
 reg clk=0,rst=1,valid=0,write=1,er=0;always #10 clk=~clk;
 reg [7:0] addr;reg [31:0] wd;wire ready,rv,be;wire [31:0] rd;
 reg [63:0] ts=64'h00000001ffffffff;wire [3:0] mask,src;wire [11:0] map;
 wire [63:0] epoch,target;wire start,ev,ca,cv;wire [31:0] eid,es,cid;
 tf_control_interface dut(.clk(clk),.rst(rst),.valid(valid),.write(write),.address(addr),.wdata(wd),.ready(ready),
 .rvalid(rv),.rdata(rd),.bus_error(be),.running(1'b1),.state(4'd7),.session_id(32'd5),.timestamp(ts),.faults(4'b0010),
 .event_ready(er),.recovery_count(32'd9),.node_mask(mask),.epoch(epoch),.start(start),.event_id(eid),.event_session(es),
 .event_target(target),.event_valid(ev),.cancel_all(ca),.cancel_valid(cv),.cancel_id(cid),.stage_map(map),.source_mask(src));
 task wr(input [7:0] a,input [31:0] d);begin @(negedge clk);valid=1;write=1;addr=a;wd=d;
  @(posedge clk);#1;if(!ready||be)$fatal(1,"CSR_WRITE");@(negedge clk);valid=0;end endtask
 task read_check(input [7:0] a,input [31:0] expected);begin @(negedge clk);valid=1;write=0;addr=a;
  @(posedge clk);#1;if(!rv||be||rd!==expected)$fatal(1,"CSR_READ addr=%h got=%h expected=%h",a,rd,expected);@(negedge clk);valid=0;end endtask
 initial begin
  #200;rst=0;wr('h00,7);wr('h60,273);wr('h64,1);wr('h20,42);wr('h24,5);wr('h28,1000);wr('h2c,0);
  @(negedge clk);valid=1;addr='h30;wd=1;repeat(5)begin @(posedge clk);#1;if(ready||ev)$fatal(1,"CSR_BACKPRESSURE");end
  @(negedge clk);er=1;@(posedge clk);#1;if(!ev||eid!=42||es!=5||target!=1000)$fatal(1,"CSR_EVENT");
  @(negedge clk);valid=0;
  read_check('h80,1);read_check('h48,32'hffffffff);ts=64'h0000000200000001;
  read_check('h4c,1);read_check('h48,1);read_check('h4c,2);read_check('h88,9);read_check('h50,2);
  @(negedge clk);valid=1;write=0;addr='hfc;@(posedge clk);#1;if(!be||rd!=0)$fatal(1,"CSR_INVALID_ADDRESS");
  $display("TEST_PASS tb_control backpressure atomic_timestamp invalid_address statistics");$finish;
 end
 initial begin #20000;$fatal(1,"CONTROL_TIMEOUT");end
endmodule
