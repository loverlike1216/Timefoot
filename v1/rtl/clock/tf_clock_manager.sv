`timescale 1ns/1ps
module tf_clock_manager #(parameter integer WORK_DIV=6,MON_TIMEOUT=96)(
 input wire ref_clk,monitor_clk,arst,
 output wire work_clk,locked,ref_rst,work_rst,reference_fault,
 output wire clock_ready);
 wire fb,fb_buf,wraw,mon_rst,hb_mon,lock_mon;
 reg [4:0] hb_count=0;reg heartbeat=0;reg mmcm_reset=1;
 wire hb_rst;
 tf_reset_sync hr(.clk(ref_clk),.arst(arst),.rst(hb_rst));
 // A session/local reset may arrive one reference cycle after a toggle.
 // Preserve the heartbeat phase during reset so XPM never sees a shortened
 // pulse. FPGA INIT establishes the initial phase; reset restarts only count.
 always @(posedge ref_clk) if(hb_rst)begin hb_count<=0;end
 else if(hb_count==15)begin hb_count<=0;heartbeat<=~heartbeat;end
 else hb_count<=hb_count+1'b1;
 MMCME2_BASE #(.CLKIN1_PERIOD(20.0),.DIVCLK_DIVIDE(1),.CLKFBOUT_MULT_F(18.0),
 .CLKOUT0_DIVIDE_F(WORK_DIV*1.0),.STARTUP_WAIT("FALSE")) mmcm(
 .CLKIN1(ref_clk),.CLKFBIN(fb_buf),.CLKFBOUT(fb),.CLKOUT0(wraw),
 .LOCKED(locked),.RST(mmcm_reset),.PWRDWN(1'b0));
 BUFG bfb(.I(fb),.O(fb_buf));BUFG bw(.I(wraw),.O(work_clk));
 tf_reset_sync mr(.clk(monitor_clk),.arst(arst),.rst(mon_rst));
 tf_bit_sync hcross(.src_clk(ref_clk),.src_bit(heartbeat),.dst_clk(monitor_clk),.dst_bit(hb_mon));
 tf_bit_sync lcross(.src_clk(ref_clk),.src_bit(locked),.dst_clk(monitor_clk),.dst_bit(lock_mon));
 reg hb_prev=0;reg [$clog2(MON_TIMEOUT+1)-1:0] age=0;
 reg fault_reg=1;
 always @(posedge monitor_clk or posedge mon_rst) begin
  if(mon_rst)begin hb_prev<=0;age<=0;fault_reg<=1;mmcm_reset<=1;end
  else begin
   hb_prev<=hb_mon;
   if(hb_prev!=hb_mon)begin age<=0;fault_reg<=~lock_mon;mmcm_reset<=0;end
   else if(age==MON_TIMEOUT-1)begin fault_reg<=1;mmcm_reset<=1;end
   else begin age<=age+1'b1;if(!lock_mon)fault_reg<=1;end
  end
 end
 assign reference_fault=fault_reg;
 // One registered monitor fault source; no combinational status crossing.
 tf_reset_sync rf(.clk(ref_clk),.arst(fault_reg),.rst(ref_rst));
 tf_reset_sync wf(.clk(work_clk),.arst(fault_reg),.rst(work_rst));
 assign clock_ready=~ref_rst;
endmodule
