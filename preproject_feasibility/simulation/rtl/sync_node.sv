`timescale 1ns/1ps
// Evaluation RTL. epoch_bus is a bundled, stable control bus; NOT a free-running CDC bus.
module sync_node #(
  parameter integer W=64, SYNC_TIMEOUT=4096, REF_TIMEOUT=32
)(input wire ref_clk, mon_clk, reset_n, enable, pll_locked,
  input wire sync_async, input wire [W-1:0] epoch_bus,
  input wire arm, input wire [W-1:0] event_time,
  output reg [W-1:0] ticks, output wire active, output wire event_out,
  output reg [3:0] errors, output reg ref_missing);
  (* ASYNC_REG="TRUE" *) reg [1:0] rr, mr;
  always @(posedge ref_clk or negedge reset_n)
    if(!reset_n) rr<=0; else rr<={rr[0],1'b1};
  always @(posedge mon_clk or negedge reset_n)
    if(!reset_n) mr<=0; else mr<={mr[0],1'b1};
  reg heartbeat;
  always @(posedge ref_clk or negedge reset_n)
    if(!reset_n) heartbeat<=0; else heartbeat<=~heartbeat;
  (* ASYNC_REG="TRUE" *) reg [1:0] hb_sync;
  reg hb_last;
  reg [$clog2(REF_TIMEOUT+1)-1:0] ref_age;
  always @(posedge mon_clk or negedge reset_n) begin
    if(!reset_n) begin hb_sync<=0; hb_last<=0; ref_age<=0; ref_missing<=1; end
    else if(!mr[1]) begin hb_sync<=0; hb_last<=0; ref_age<=0; ref_missing<=1; end
    else begin
      hb_sync<={hb_sync[0],heartbeat}; hb_last<=hb_sync[1];
      if(hb_sync[1]!=hb_last) begin ref_age<=0; ref_missing<=0; end
      else if(ref_age==REF_TIMEOUT-1) ref_missing<=1;
      else ref_age<=ref_age+1'b1;
    end
  end
  (* ASYNC_REG="TRUE" *) reg [1:0] sync_ff, missing_ff, lock_ff;
  reg sync_last, valid, pending, arm_last, fired, session_gate;
  reg [W-1:0] target;
  reg [$clog2(SYNC_TIMEOUT+1)-1:0] sync_age;
  wire sync_rise=sync_ff[1] & ~sync_last;
  wire [W-1:0] lead=event_time-ticks;
  // Fault stays inhibited after raw LOCK/missing recovers, until a fresh qualified SYNC.
  // Physical asynchronous reset/gate implementation still requires CDC/RDC review.
  always @(posedge ref_clk or negedge reset_n or posedge ref_missing or negedge pll_locked)
    if(!reset_n || ref_missing || !pll_locked) session_gate<=0;
    else if(sync_rise && lock_ff[1] && !missing_ff[1]) session_gate<=1;
  assign active=valid & session_gate & enable & pll_locked & ~ref_missing;
  // Asynchronous inhibit is evaluation fail-closed logic, not a qualified safety output.
  assign event_out=fired & active;
  always @(posedge ref_clk or negedge reset_n) begin
    if(!reset_n) begin
      sync_ff<=0; missing_ff<=3; lock_ff<=0; sync_last<=0;
      valid<=0; pending<=0; arm_last<=0; fired<=0; ticks<=0;
      sync_age<=0; errors<=0; target<=0;
    end else if(!rr[1]) begin
      sync_ff<=0; missing_ff<=3; lock_ff<=0; sync_last<=0;
      valid<=0; pending<=0; arm_last<=0; fired<=0; ticks<=0;
      sync_age<=0; errors<=0; target<=0;
    end else begin
      sync_ff<={sync_ff[0],sync_async}; missing_ff<={missing_ff[0],ref_missing};
      lock_ff<={lock_ff[0],pll_locked}; sync_last<=sync_ff[1];
      arm_last<=arm; fired<=0;
      if(valid && pending && ticks==target && sync_age!=SYNC_TIMEOUT-1) begin
        fired<=1; pending<=0;
      end
      if(!enable || !lock_ff[1] || missing_ff[1]) begin
        valid<=0; pending<=0;
        if(!lock_ff[1]) errors[0]<=1;
        if(missing_ff[1]) errors[1]<=1;
      end else if(sync_rise) begin
        sync_age<=0;
        // Heartbeat SYNC never steps a running timebase. New epoch requires invalid state.
        if(!valid) begin ticks<=epoch_bus; valid<=1; pending<=0; end
        else ticks<=ticks+1'b1;
      end else if(valid) begin
        ticks<=ticks+1'b1;
        if(sync_age==SYNC_TIMEOUT-1) begin valid<=0; pending<=0; errors[2]<=1; end
        else begin
          sync_age<=sync_age+1'b1;
          if(arm && !arm_last) begin
            if(!pending && lead!=0 && !lead[W-1]) begin target<=event_time; pending<=1; end
            else errors[3]<=1;
          end
        end
      end
    end
  end
endmodule
