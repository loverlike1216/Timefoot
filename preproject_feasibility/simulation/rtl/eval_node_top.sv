`timescale 1ns/1ps
// Per-device OOC harness. All I/O/control interfaces are virtual, not board constraints.
module eval_node_top(input wire ref_clk,mon_clk,reset_n,enable,sync_in,arm,
 input wire [63:0] epoch,event_time,input wire [127:0] din,input wire vin,rout,
 output wire rin,vout,output wire [127:0] dout,output wire event_out,active,
 output wire [63:0] ticks,output wire [3:0] errors);
 wire c50,c100,c150,locked,missing,full,empty;
 wire [127:0] q;wire qv,qr;
 (* ASYNC_REG="TRUE" *) reg [1:0] active150;
 always @(posedge c150 or negedge reset_n) if(!reset_n) active150<=0; else active150<={active150[0],active};
 clock_tree c(.clk_in(ref_clk),.reset(~reset_n),.clk50(c50),.clk100(c100),.clk150(c150),.locked(locked));
 sync_node n(.ref_clk(c50),.mon_clk(mon_clk),.reset_n(reset_n),.enable(enable),
 .pll_locked(locked),.sync_async(sync_in),.epoch_bus(epoch),.arm(arm),.event_time(event_time),
 .ticks(ticks),.active(active),.event_out(event_out),.errors(errors),.ref_missing(missing));
 async_fifo f(.wclk(c100),.rclk(c150),.reset_n(reset_n),.wdata(din),.wvalid(vin),
 .wready(rin),.rdata(q),.rvalid(qv),.rready(qr),.full(full),.empty(empty));
 task_stage #(.OP(2)) s(.clk(c150),.reset_n(reset_n),.allow(active150[1]),.in_data(q),
 .in_valid(qv),.in_ready(qr),.out_data(dout),.out_valid(vout),.out_ready(rout));
endmodule
