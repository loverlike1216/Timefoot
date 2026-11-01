`timescale 1ns/1ps
module tb_physical_node;
 reg refclk=0,mon=0,ctrl=0,rxclk=0,arst=1,marker=0,mq=1,cs=1,mosi=0;
 always #10 refclk=~refclk;initial begin #3;forever #10 mon=~mon;end
 always #20 ctrl=~ctrl;initial begin #1;forever #10 rxclk=~rxclk;end
 wire fclk,tv,sof,credit,miso,ready,event_out,fault_out,rready;wire [3:0] data;
 tf_physical_node_top dut(.ref_in(refclk),.monitor_in(mon),.rx_clock(rxclk),.control_clock(ctrl),.arst(arst),
 .sync_marker(marker),.marker_qualified(mq),.rx_data(4'd0),.rx_valid(1'b0),.rx_sof(1'b0),.rx_ready(rready),
 .tx_clock(fclk),.tx_data(data),.tx_valid(tv),.tx_sof(sof),.tx_ready(credit),
 .control_cs_n(cs),.control_mosi(mosi),.control_miso(miso),.control_ready(ready),.event_out(event_out),.fault_out(fault_out));
 reg sink_flush=1;wire srst,sflush;wire [207:0] frame;wire fv;wire [31:0] starts,fwds,aborts,errors;wire sfault;
 tf_reset_sync gr(.clk(fclk),.arst(arst),.rst(srst));tf_reset_sync fr(.clk(fclk),.arst(sink_flush),.rst(sflush));
 tf_link_rx sink(.clk(fclk),.root_rst(srst),.flush(sflush),.pin_data(data),.pin_valid(tv),.pin_sof(sof),.pin_ready(credit),
 .frame(frame),.frame_valid(fv),.frame_ready(1'b1),.started(starts),.forwarded(fwds),.aborted(aborts),.framing_errors(errors),.error_flag(sfault));
 task transaction(input [47:0] command,output [47:0] response);begin
  wait(ready);@(negedge ctrl);#1;cs=0;response=0;
  for(integer i=47;i>=0;i=i-1)begin mosi=command[i];@(posedge ctrl);@(negedge ctrl);#1;response={response[46:0],miso};end
  cs=1;mosi=0;repeat(4)@(negedge ctrl);
 end endtask
 task access(input bit write,input [7:0] addr,input [31:0] value,input bit expect_error,output [31:0] result);
  reg [47:0] response;begin
   transaction({write?8'h01:8'h02,addr,value},response);#1000;
   transaction({8'h02,8'h40,32'd0},response);#1000;
   if(!response[47]||response[46]!==expect_error||response[39:32]!==addr)
    $fatal(1,"SERIAL_RESPONSE addr=%h response=%h error_expected=%b",addr,response,expect_error);
   result=response[31:0];
  end
 endtask
 task wr(input [7:0] addr,input [31:0] value);reg [31:0] unused;begin access(1,addr,value,0,unused);end endtask
 task rd(input [7:0] addr,output [31:0] value);begin access(0,addr,0,0,value);end endtask
 function [31:0] crc(input [175:0] body);reg [31:0] c;begin c=-1;
  for(integer i=175;i>=0;i=i-1)c=(c<<1)^((c[31]^body[i])?32'h04c11db7:0);crc=~c;end endfunction
 integer got=0,fd;reg [31:0] p,seq;reg [63:0] target;
 always @(posedge fclk)if(fv)begin
  seq=got;p=(seq*17+3)*3+7;p=(p^32'h5a5aa5a5)+frame[111:80];
  // source_timestamp lives at143:80 of complete frame; low32=111:80.
  if(frame[207:176]!==1||frame[175:144]!==seq||frame[63:32]!==p||frame[31:0]!==crc(frame[207:32]))$fatal(1,"PHYSICAL_NODE_DATA got=%0d frame=%h",got,frame);
  $fdisplay(fd,"%0d,%h",got,frame);got=got+1;
 end
 always @(posedge event_out)begin #1;if(dut.timestamp!==target||dut.executed_id!=42)$fatal(1,"PHYSICAL_EVENT_EDGE");end
 reg [31:0] status,tmp,low,high;
 initial begin
  fd=$fopen("physical.csv","w");#500;arst=0;wait(ready);rd('h40,status);if(!status[0])$fatal(1,"NODE_NOT_CLOCK_READY");
  access(0,'hfc,0,1,tmp);access(1,'h30,1,1,tmp); // invalid address and pre-RUN submit
  wr('h00,15);wr('h10,1000000);wr('h14,0);wr('h18,1);wr('h04,1);
  rd('h40,status);if(!status[1])$fatal(1,"NODE_PREPARE_ACK");
  sink_flush=0;@(negedge refclk);marker=1;@(negedge refclk);marker=0;
  wr('h04,4);rd('h40,status);if(!status[4]||!status[3])$fatal(1,"NODE_NOT_RUNNING");
  rd('h48,low);rd('h4c,high);target={high,low}+10000;
  wr('h20,42);wr('h24,1);wr('h28,target[31:0]);wr('h2c,target[63:32]);wr('h30,1);
  wait(got==64);#1000;rd('h54,tmp);if(tmp!=42)$fatal(1,"EVENT_ID_READBACK");
  rd('h60,tmp);if(tmp!=1)$fatal(1,"EVENT_COUNT_READBACK");rd('h70,tmp);if(tmp!=0)$fatal(1,"MANAGEMENT_OVERFLOW");
  // Read while qualification is revoked; the response must remain valid and
  // a subsequent status must show no RUN/no time-valid. No bus deadlock.
  fork begin rd('h40,status);end begin #500;mq=0;end join
  rd('h40,status);if(status[4]||status[3]||!fault_out)$fatal(1,"CONTROL_DURING_FAULT");
  access(1,'h04,4,1,tmp);wr('h04,2);sink_flush=1;mq=1;
  access(1,'h04,1,1,tmp); // same session cannot resume after abort
  wr('h18,2);wr('h10,2000000);wr('h04,1);rd('h40,status);if(!status[1])$fatal(1,"SECOND_SESSION_PREPARED");
  sink_flush=0;@(negedge refclk);marker=1;@(negedge refclk);marker=0;wr('h04,4);
  rd('h44,tmp);if(tmp!=2)$fatal(1,"SESSION_READBACK");rd('h40,status);if(!status[4])$fatal(1,"SECOND_SESSION_RUN");
  $display("TEST_PASS tb_physical_node serial_fault_status event64 packets=64 session_reuse_rejected");$fclose(fd);$finish;
 end
 initial begin #2000000;$fatal(1,"PHYSICAL_NODE_TIMEOUT got=%0d",got);end
endmodule
