`timescale 1ns/1ps
module tf_event_scheduler #(parameter integer DEPTH=8,MIN_LEAD=4)(
 input wire clk,rst,enabled,time_valid,input wire [63:0] timestamp,
 input wire [31:0] session_id,event_id,event_session,input wire [63:0] target_timestamp,
 input wire event_valid,output wire event_ready,input wire cancel_all,cancel_valid,
 input wire [31:0] cancel_id,
 output reg event_execute,event_done,event_error,output reg [3:0] error_code,
 output reg [31:0] executed_id,output reg [63:0] executed_timestamp,
 output reg [31:0] executed_count,aborted_count,rejected_count,
 output wire [$clog2(DEPTH):0] queue_level);
 localparam A=$clog2(DEPTH);
 reg [31:0] ids[DEPTH];reg [63:0] targets[DEPTH];reg alive[DEPTH];
 reg [A-1:0] head,tail;reg [A:0] count;
 wire [63:0] lead=target_timestamp-timestamp;
 wire [63:0] distance=targets[head]-(timestamp+1'b1);
 reg duplicate;integer i;
 always @* begin duplicate=0;for(integer j=0;j<DEPTH;j=j+1)
  if(alive[j]&&ids[j]==event_id)duplicate=1;end
 assign event_ready=enabled&time_valid&(count<DEPTH);
 assign queue_level=count;
 wire cancel_head=cancel_valid&&ids[head]==cancel_id;
 wire pop=(count!=0)&&(!alive[head]||cancel_head||distance==0||distance[63]);
 wire [A-1:0] previous_tail=tail-1'b1;
 wire [63:0] ordering=target_timestamp-targets[previous_tail];
 wire accept=event_valid&event_ready;
 wire legal=event_session==session_id&&lead>=MIN_LEAD&&!lead[63]&&!duplicate&&
             (count==0||!ordering[63]);
 always @(posedge clk or posedge rst)begin
  if(rst)begin head<=0;tail<=0;count<=0;event_execute<=0;event_done<=0;event_error<=0;
   error_code<=0;executed_id<=0;executed_timestamp<=0;executed_count<=0;aborted_count<=0;rejected_count<=0;
   for(i=0;i<DEPTH;i=i+1)begin alive[i]<=0;ids[i]<=0;targets[i]<=0;end
  end else begin
   event_execute<=0;event_done<=0;event_error<=0;
   if(!enabled||!time_valid||cancel_all)begin
    if(count!=0)aborted_count<=aborted_count+count;
    head<=0;tail<=0;count<=0;for(i=0;i<DEPTH;i=i+1)alive[i]<=0;
   end else begin
    if(cancel_valid)for(i=0;i<DEPTH;i=i+1)if(alive[i]&&ids[i]==cancel_id)alive[i]<=0;
    if(pop)begin
     head<=head+1'b1;alive[head]<=0;
     if(alive[head]&&!cancel_head&&distance==0)begin
      event_execute<=1;event_done<=1;executed_id<=ids[head];executed_timestamp<=targets[head];
      executed_count<=executed_count+1'b1;
     end else if(alive[head]&&!cancel_head)begin event_error<=1;error_code<=4;rejected_count<=rejected_count+1'b1;end
     else aborted_count<=aborted_count+1'b1;
    end
    if(accept)begin
     if(legal)begin ids[tail]<=event_id;targets[tail]<=target_timestamp;alive[tail]<=1;tail<=tail+1'b1;end
     else begin event_error<=1;rejected_count<=rejected_count+1'b1;
      error_code<=(event_session!=session_id)?1:duplicate?2:3;end
    end
    case({accept&&legal,pop})2'b10:count<=count+1'b1;2'b01:count<=count-1'b1;default:count<=count;endcase
   end
  end
 end
endmodule
