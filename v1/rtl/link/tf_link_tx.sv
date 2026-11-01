`timescale 1ns/1ps
// SDR protocol v1: fixed-size core frame, MSB beat first, SOF on first beat.
// Returned ready is FRAME CREDIT, not a per-beat combinational ready loop.
// Receiver reserves one full frame, lowers credit on SOF, and raises it only
// after forwarding that frame. TX observes low then high before rearming.
module tf_link_tx #(parameter integer FRAME_W=208,LANES=4,DEPTH=16)(
 input wire work_clk,link_clk,work_root_rst,link_root_rst,work_flush,link_flush,
 input wire [FRAME_W-1:0] frame,input wire frame_valid,output wire frame_ready,
 input wire pin_ready,output reg [LANES-1:0] pin_data=0,output reg pin_valid=0,pin_sof=0,
 output wire pin_clock,output wire fifo_full,output wire [$clog2(DEPTH):0] queue_level,
 output reg [31:0] accepted=0,output reg [31:0] wire_sent=0,aborted=0,
 output wire stats_valid);
 localparam BEATS=FRAME_W/LANES;
 initial if(FRAME_W%LANES!=0||BEATS<2)$fatal(1,"LINK_WIDTH");
 wire [FRAME_W-1:0] q;wire qv,qr,ir,empty,wo,ro;
 wire [$clog2(DEPTH):0] wl;reg active=0;reg [$clog2(BEATS)-1:0] beat=0;
 reg [7:0] settle=128;reg quiesce=1;wire quiesce_work;
 tf_bit_sync quiet_status(.src_clk(link_clk),.src_bit(quiesce),.dst_clk(work_clk),.dst_bit(quiesce_work));
 tf_link_clock_forward clkout(.clk(link_clk),.forwarded_clk(pin_clock));
 wire credit;reg wait_credit=0,saw_credit_low=0;
 tf_bit_sync credit_sync(.src_clk(link_clk),.src_bit(pin_ready),.dst_clk(link_clk),.dst_bit(credit));
 wire permit=~quiesce_work;
 reg [FRAME_W-1:0] input_slot=0;reg input_valid=0;
 assign frame_ready=(!input_valid||ir)&&permit&&!work_flush;
 // Terminate the core's asynchronous safety mask at a synchronous holding
 // register. It must never propagate combinationally into BRAM write enable.
 always @(posedge work_clk)begin
  if(work_root_rst||work_flush)input_valid<=0;
  else if(!input_valid||ir&&permit)begin
   input_valid<=frame_valid&&permit;
   if(frame_valid&&permit)input_slot<=frame;
  end
 end
 assign qr=active&&(beat==BEATS-1)&&!quiesce;
 tf_async_fifo #(.WIDTH(FRAME_W),.DEPTH(DEPTH),.COORDINATED_RESET(1)) frames(
 .wr_clk(work_clk),.rd_clk(link_clk),.wr_flush(work_flush),.rd_flush(link_flush),
 .in_data(input_slot),.in_valid(input_valid&permit),.in_ready(ir),.out_data(q),.out_valid(qv),.out_ready(qr),
 .full(fifo_full),.empty(empty),.wr_online(wo),.rd_online(ro),.wr_level(wl),.rd_level(queue_level));
 always @(posedge work_clk)if(work_root_rst)accepted<=0;
 else if(frame_valid&&frame_ready)accepted<=accepted+1'b1;
 wire [31:0] accepted_link;
 tf_status_snapshot #(.WIDTH(32)) ledger(.src_clk(work_clk),.source(accepted),.dst_clk(link_clk),.snapshot(accepted_link));
 assign stats_valid=!quiesce;
 (* IOB="TRUE" *)reg [LANES+1:0] pads=0;
 always @*begin pin_data=pads[LANES-1:0];pin_valid=pads[LANES];pin_sof=pads[LANES+1];end
 always @(posedge link_clk)begin
  if(link_root_rst)begin quiesce<=1;settle<=128;active<=0;beat<=0;pads<=0;wire_sent<=0;aborted<=0;wait_credit<=0;saw_credit_low<=0;end
  else if(link_flush)begin quiesce<=1;settle<=128;active<=0;beat<=0;pads<=0;wait_credit<=0;saw_credit_low<=0;end
  else if(settle!=0)begin
   settle<=settle-1'b1;active<=0;beat<=0;pads<=0;
   if(settle==1)begin aborted<=accepted_link-wire_sent;quiesce<=0;end
  end else begin
   if(wait_credit&&!credit)saw_credit_low<=1;
   if(active)begin
    pads<={1'b0,1'b1,q[FRAME_W-1-LANES*beat -:LANES]};
    if(beat==BEATS-1)begin active<=0;beat<=0;wire_sent<=wire_sent+1'b1;end
    else beat<=beat+1'b1;
   end else if(wait_credit)begin
    pads<=0;
    if(saw_credit_low&&credit)begin wait_credit<=0;saw_credit_low<=0;end
   end else if(qv&&credit)begin
    pads<={1'b1,1'b1,q[FRAME_W-1 -:LANES]};active<=1;beat<=1;wait_credit<=1;saw_credit_low<=0;
   end
   else pads<=0;
  end
 end
endmodule
