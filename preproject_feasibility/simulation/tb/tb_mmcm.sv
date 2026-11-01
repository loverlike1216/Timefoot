`timescale 1ns/1ps
module tb_mmcm;
 reg ci=0,rst=1;wire c50,c100,c150,locked;
 always #10 ci=~ci;
 clock_tree dut(.clk_in(ci),.reset(rst),.clk50(c50),.clk100(c100),.clk150(c150),.locked(locked));
 realtime t0,t1,t2;integer n0=0,n1=0,n2=0;reg measure=0;
 always @(posedge c50) if(measure) begin if(n0>0&&($realtime-t0<19.99||$realtime-t0>20.01)) $fatal(1,"50MHz");t0=$realtime;n0=n0+1;end
 always @(posedge c100) if(measure) begin if(n1>0&&($realtime-t1<9.99||$realtime-t1>10.01)) $fatal(1,"100MHz");t1=$realtime;n1=n1+1;end
 always @(posedge c150) if(measure) begin if(n2>0&&($realtime-t2<6.65||$realtime-t2>6.68)) $fatal(1,"150MHz");t2=$realtime;n2=n2+1;end
 initial begin
  #200 rst=0;wait(locked);$display("PRIMITIVE_LOCK time=%0t",$realtime);#100;measure=1;#2000;measure=0;
  if(n0<99||n1<199||n2<299) $fatal(1,"CLOCK_COUNTS");
  rst=1;#200;if(locked) $fatal(1,"LOCK_RESET");rst=0;wait(locked);#100;
  $display("TEST_PASS tb_mmcm counts=%0d/%0d/%0d real_UNISIM_parameter_model_only",n0,n1,n2);$finish;
 end
 initial begin #100000;$fatal(1,"MMCM_TIMEOUT");end
endmodule
