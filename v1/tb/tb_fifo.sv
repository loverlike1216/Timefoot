`timescale 1ns/1ps
module tb_fifo;
 reg wc=0,rc=0,wf=1,rf=1,iv=0,ready=0;
 always #7 wc=~wc;always #11 rc=~rc;
 reg [63:0] din=0;wire [63:0] dout;wire ir,ov,full,empty,wo,ro;wire [4:0] wl,rl;
 tf_async_fifo #(.WIDTH(64),.DEPTH(16)) dut(.wr_clk(wc),.rd_clk(rc),.wr_flush(wf),.rd_flush(rf),
 .in_data(din),.in_valid(iv),.in_ready(ir),.out_data(dout),.out_valid(ov),.out_ready(ready),
 .full(full),.empty(empty),.wr_online(wo),.rd_online(ro),.wr_level(wl),.rd_level(rl));
 reg [63:0] expected[512];integer sent=0,got=0,stalls=0,max_level=0,fd;
 always @(posedge wc)if(!wf&&!rf)begin
  if(iv&&ir)begin expected[sent]=din;sent=sent+1;end
  if(iv&&!ir)stalls=stalls+1;if(wl>max_level)max_level=wl;
 end
 always @(posedge rc)if(ov&&ready&&!wf&&!rf)begin
  if(got>=sent||dout!==expected[got])$fatal(1,"FIFO_ORDER_OR_CORRUPTION got=%0d",got);
  $fdisplay(fd,"%0d,%h",got,dout);got=got+1;
 end
 task send(input [63:0] data);
  begin @(negedge wc);din=data;iv=1;@(posedge wc);while(!ir)@(posedge wc);@(negedge wc);iv=0;end
 endtask
 initial begin
  fd=$fopen("fifo.csv","w");#200;wf=0;rf=0;
  fork begin for(integer i=0;i<64;i=i+1)send(64'h100000000+i);end
       begin #4000;ready=1;end join
  wait(got==64);#100;if(stalls==0||max_level<16)$fatal(1,"FIFO_COVERAGE");
  $display("PASS async_fifo_order_full_empty_backpressure max=%0d stalls=%0d",max_level,stalls);
  ready=0;for(integer i=0;i<10;i=i+1)send(64'h200000000+i);
  @(negedge rc);rf=1;iv=0;#200;sent=0;got=0;rf=0;wait(wo&&ro);#100;ready=1;
  for(integer i=0;i<40;i=i+1)send(64'h300000000+i);
  wait(got==40);#200;if(ov)$fatal(1,"FIFO_STALE_AFTER_RD_ONLY_RESET");
  $display("PASS reader_only_reset_flushes_both_endpoints");
  @(negedge wc);wf=1;#200;sent=0;got=0;wf=0;wait(wo&&ro);
  for(integer i=0;i<16;i=i+1)send(64'h400000000+i);
  wait(got==16);#100;$display("TEST_PASS tb_fifo");$fclose(fd);$finish;
 end
 initial begin #100000;$fatal(1,"FIFO_TIMEOUT");end
endmodule
