`timescale 1ns/1ps
// A reset request from either endpoint flushes BOTH domains. Clocks may stop;
// interfaces remain inhibited until both clocks return and reset/busy converges.
module tf_async_fifo #(parameter integer WIDTH=208,DEPTH=16,COORDINATED_RESET=0)(
 input wire wr_clk,rd_clk,wr_flush,rd_flush,
 input wire [WIDTH-1:0] in_data,input wire in_valid,output wire in_ready,
 output wire [WIDTH-1:0] out_data,output wire out_valid,input wire out_ready,
 output wire full,empty,wr_online,rd_online,
 output wire [$clog2(DEPTH):0] wr_level,rd_level);
 wire wa,ra,wb,rb,read_request;reg fifo_rst=1;reg [5:0] startup=0;
 // Flush inputs are levels held for >= 8 clocks of the slower endpoint.
 // Arbitrate in ONE clock domain before distributing a registered reset.
 // XPM already transfers its internal busy state; do not duplicate that CDC.
 tf_reset_sync wreset(.clk(wr_clk),.arst(wr_flush),.rst(wa));
 generate if(COORDINATED_RESET)begin
  // Both flushes must derive from the SAME session-reset owner. This mode
  // prevents duplicated reset-request synchronization across parallel FIFOs.
  assign read_request=1'b0;
 end else begin
  tf_bit_sync read_flush_request(.src_clk(rd_clk),.src_bit(rd_flush),.dst_clk(wr_clk),.dst_bit(read_request));
 end endgenerate
 always @(posedge wr_clk)begin
  if(startup!=63)startup<=startup+1'b1;
  fifo_rst<=wa|read_request|(startup!=63);
 end
 tf_reset_sync rreset(.clk(rd_clk),.arst(fifo_rst),.rst(ra));
 reg [4:0] wguard=0,rguard=0;
 always @(posedge wr_clk) if(wa||fifo_rst||wb) wguard<=0;else if(wguard!=31)wguard<=wguard+1'b1;
 always @(posedge rd_clk) if(ra||rd_flush||rb) rguard<=0;else if(rguard!=31)rguard<=rguard+1'b1;
 assign wr_online=(wguard==31)&~wa&~fifo_rst&~wb;
 assign rd_online=(rguard==31)&~ra&~rd_flush&~rb;
 assign in_ready=wr_online&~full;
 assign out_valid=rd_online&~empty;
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("auto"),.FIFO_WRITE_DEPTH(DEPTH),
 .WRITE_DATA_WIDTH(WIDTH),.READ_DATA_WIDTH(WIDTH),.READ_MODE("fwft"),.FIFO_READ_LATENCY(0),
 .CDC_SYNC_STAGES(3),.RELATED_CLOCKS(0),.SIM_ASSERT_CHK(1),
 .WR_DATA_COUNT_WIDTH($clog2(DEPTH)+1),.RD_DATA_COUNT_WIDTH($clog2(DEPTH)+1),
 .PROG_FULL_THRESH(DEPTH-6),.PROG_EMPTY_THRESH(5),.USE_ADV_FEATURES("0707")) u_fifo(
 .rst(fifo_rst),.sleep(1'b0),.wr_clk(wr_clk),.rd_clk(rd_clk),
 .din(in_data),.wr_en(in_valid&in_ready),.full(full),.wr_rst_busy(wb),
 .dout(out_data),.rd_en(out_valid&out_ready),.empty(empty),.rd_rst_busy(rb),
 .wr_data_count(wr_level),.rd_data_count(rd_level),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
endmodule
