`timescale 1ns/1ps
module tb_stream;
 reg rx=0,wc=0,flush=1,valid=0,ready=0;always #7 rx=~rx;always #4.5 wc=~wc;
 reg [207:0] frame;wire ir,ov,err,full,empty;wire [3:0] ec;wire [175:0] body;
 wire [31:0] ac,rc;wire [4:0] level;reg [31:0] sess=7;
 tf_stream_link dut(.rx_clk(rx),.work_clk(wc),.rx_flush(flush),.work_flush(flush),
 .rx_frame(frame),.rx_valid(valid),.rx_ready(ir),.session_id(sess),.out_body(body),.out_valid(ov),
 .out_ready(ready),.error(err),.error_code(ec),.accepted_count(ac),.rejected_count(rc),.full(full),.empty(empty),.level(level));
 function automatic [31:0] crc(input [175:0] b);
  reg [31:0] c;begin c=32'hffffffff;for(integer i=175;i>=0;i=i-1)c=(c<<1)^((c[31]^b[i])?32'h04c11db7:0);crc=~c;end
 endfunction
 function automatic [207:0] packet(input [31:0] s,n,input [15:0] len);
  reg [175:0] b;begin b={s,n,64'(n*20+1000),len,32'(n*17+3)};packet={b,crc(b)};end
 endfunction
 integer got=0,fd;reg [31:0] lfsr=1;reg check_positive=1;
 always @(negedge wc)begin lfsr=(lfsr<<1)^({32{lfsr[31]}}&32'h04c11db7);if(!flush)ready=(lfsr[2:0]!=0);end
 always @(posedge wc)if(ov&&ready)begin
  if(!check_positive)$fatal(1,"INVALID_FRAME_FORWARDED");
  if(body[175:144]!=sess||body[143:112]!=got||body[111:48]!=(got*20+1000)||body[31:0]!=(got*17+3))$fatal(1,"STREAM_DATA");
  $fdisplay(fd,"%0d,%h",got,body);got=got+1;
 end
 task send(input [207:0] f);
  begin @(negedge rx);frame=f;valid=1;@(posedge rx);while(!ir)@(posedge rx);@(negedge rx);valid=0;end
 endtask
 task restart;
  begin flush=1;valid=0;#200;flush=0;#1500;end
 endtask
 initial begin
  fd=$fopen("stream.csv","w");restart();
  for(integer i=0;i<40;i=i+1)send(packet(sess,i,4));wait(got==40);#100;
  if(err||ac!=40)$fatal(1,"VALID_STREAM_ERROR");$display("PASS stream_crc_order_backpressure");
  check_positive=0;restart();send(packet(7,0,4)^208'd1);wait(err);if(ec!=1||rc!=1)$fatal(1,"CRC_ERROR_POLICY");
  $display("PASS crc_corruption_rejected");
  restart();send(packet(6,0,4));wait(err);if(ec!=2)$fatal(1,"SESSION_ERROR_POLICY");
  restart();send(packet(7,2,4));wait(err);if(ec!=3)$fatal(1,"SEQUENCE_ERROR_POLICY");
  restart();send(packet(7,0,8));wait(err);if(ec!=4)$fatal(1,"LENGTH_ERROR_POLICY");
  $display("PASS old_session_sequence_and_length_rejected");
  $display("TEST_PASS tb_stream");$fclose(fd);$finish;
 end
 initial begin #300000;$fatal(1,"STREAM_TIMEOUT");end
endmodule
