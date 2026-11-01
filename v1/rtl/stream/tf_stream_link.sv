`timescale 1ns/1ps
module tf_stream_link #(parameter integer PAYLOAD_W=32,DEPTH=16,COORDINATED_RESET=0)(
 input wire rx_clk,work_clk,rx_flush,work_flush,
 input wire [175+PAYLOAD_W:0] rx_frame,input wire rx_valid,output wire rx_ready,
 input wire [31:0] session_id,
 output wire [143+PAYLOAD_W:0] out_body,output wire out_valid,input wire out_ready,
 output reg error,output reg [3:0] error_code,output reg [31:0] accepted_count,rejected_count,
 output wire full,empty,output wire [$clog2(DEPTH):0] level);
 localparam B=144+PAYLOAD_W,F=B+32;
 wire [F-1:0] q;wire qv,qr,co;wire [B-1:0] checked;wire [31:0] computed;
 wire crc_ready,crc_valid;reg [31:0] received_crc,expected_sequence;
 wire [$clog2(DEPTH):0] wr_level;wire wo,ro;
 tf_async_fifo #(.WIDTH(F),.DEPTH(DEPTH),.COORDINATED_RESET(COORDINATED_RESET)) fifo(.wr_clk(rx_clk),.rd_clk(work_clk),
 .wr_flush(rx_flush),.rd_flush(work_flush),.in_data(rx_frame),.in_valid(rx_valid),.in_ready(rx_ready),
 .out_data(q),.out_valid(qv),.out_ready(qr),.full(full),.empty(empty),
 .wr_online(wo),.rd_online(ro),.wr_level(wr_level),.rd_level(level));
 assign qr=crc_ready;
 tf_crc_engine #(.BITS(B)) crc_validator(.clk(work_clk),.rst(work_flush),.in_body(q[F-1:32]),
 .in_valid(qv),.in_ready(crc_ready),.out_body(checked),.out_crc(computed),
 .out_valid(crc_valid),.out_ready(co));
 wire [31:0] got_session=checked[B-1 -:32];wire [31:0] got_sequence=checked[B-33 -:32];
 wire [15:0] got_length=checked[PAYLOAD_W+15:PAYLOAD_W];
 wire good=(computed==received_crc)&&(got_session==session_id)&&
           (got_sequence==expected_sequence)&&(got_length==PAYLOAD_W/8)&&!error;
 assign out_body=checked;assign out_valid=crc_valid&good;
 assign co=~good|out_ready;
 always @(posedge work_clk)begin
  if(work_flush)begin error<=0;error_code<=0;accepted_count<=0;rejected_count<=0;received_crc<=0;expected_sequence<=0;end
  else begin
   if(qv&&qr)received_crc<=q[31:0];
   if(crc_valid&&co)begin
    if(good)begin accepted_count<=accepted_count+1'b1;expected_sequence<=expected_sequence+1'b1;end
    else begin error<=1;rejected_count<=rejected_count+1'b1;
     error_code<=(computed!=received_crc)?1:(got_session!=session_id)?2:(got_sequence!=expected_sequence)?3:4;end
   end
  end
 end
endmodule
