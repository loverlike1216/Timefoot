`timescale 1ns/1ps
// Reference-independent, source-synchronous management port. Free-running SCLK.
// MOSI/CS launch on SCLK falling; MISO launches rising, host samples falling.
// One48-bit command/CS: opcode8(1write/2read),address8,data32. Response on a
// subsequent transaction: flags8(valid80,error40),address8,data32. Idle CS>=2clks.
module tf_management_serial(input wire serial_clk,ref_clk,serial_rst,ref_rst,
 input wire cs_n,mosi,output reg miso=0,output reg ready=0,
 output wire bus_valid,bus_write,output wire [7:0] bus_address,output wire [31:0] bus_wdata,
 input wire bus_ready,bus_rvalid,bus_error,input wire [31:0] bus_rdata,
 output reg [31:0] protocol_errors=0);
 reg [47:0] shift=0,command=0;reg [5:0] bits=0;reg command_valid=0;
 wire command_ready;wire [47:0] cq;wire cv,cr;
 tf_cdc_bridge #(.WIDTH(48),.COORDINATED_RESET(1)) commands(.src_clk(serial_clk),.dst_clk(ref_clk),
 .src_flush(serial_rst),.dst_flush(ref_rst),.src_data(command),.src_valid(command_valid),.src_ready(command_ready),
 .dst_data(cq),.dst_valid(cv),.dst_ready(cr));
 reg [47:0] reply=0;reg reply_valid=0,pending=0;reg [7:0] address_pending;
 wire reply_ready;wire [47:0] rq;wire rv,rr;
 tf_cdc_bridge #(.WIDTH(48),.COORDINATED_RESET(1)) replies(.src_clk(ref_clk),.dst_clk(serial_clk),
 .src_flush(ref_rst),.dst_flush(serial_rst),.src_data(reply),.src_valid(reply_valid),.src_ready(reply_ready),
 .dst_data(rq),.dst_valid(rv),.dst_ready(rr));
 wire opcode_ok=cq[47:40]==1||cq[47:40]==2;
 assign bus_valid=cv&&!pending&&!reply_valid&&opcode_ok;
 assign bus_write=(cq[47:40]==1);assign bus_address=cq[39:32];assign bus_wdata=cq[31:0];
 assign cr=!pending&&!reply_valid&&(!opcode_ok||bus_ready);
 always @(posedge ref_clk)begin
  if(ref_rst)begin reply_valid<=0;pending<=0;reply<=0;address_pending<=0;end
  else begin
   if(reply_valid&&reply_ready)reply_valid<=0;
   if(cv&&cr)begin address_pending<=cq[39:32];
    if(opcode_ok)pending<=1;else begin reply<={8'hc0,cq[39:32],32'd0};reply_valid<=1;end
   end
   if(pending&&bus_rvalid)begin reply<={1'b1,bus_error,6'd0,address_pending,bus_rdata};reply_valid<=1;pending<=0;end
  end
 end
 reg [47:0] response=0,tx_shift=0;reg response_valid=0;
 assign rr=cs_n&&!response_valid;
 (* IOB="TRUE" *)reg miso_pad=0;always @*miso=miso_pad;
 always @(posedge serial_clk)begin
  if(serial_rst)begin bits<=0;shift<=0;command<=0;command_valid<=0;response<=0;
   response_valid<=0;tx_shift<=0;miso_pad<=0;ready<=0;protocol_errors<=0;end
  else begin
   if(command_valid&&command_ready)command_valid<=0;
   if(cs_n)begin bits<=0;ready<=command_ready&&!command_valid;
    if(rv&&rr)begin response<=rq;response_valid<=1;end
   end else if(bits<48)begin
    ready<=0;shift<={shift[46:0],mosi};bits<=bits+1'b1;
    if(bits==0)begin miso_pad<=response_valid?response[47]:1'b0;tx_shift<={response[46:0],1'b0};end
    else begin miso_pad<=tx_shift[47];tx_shift<=tx_shift<<1;end
    if(bits==47)begin
     response_valid<=0;
     if(command_valid&&!command_ready)protocol_errors<=protocol_errors+1'b1;
     else begin command<={shift[46:0],mosi};command_valid<=1;end
    end
   end
  end
 end
endmodule
