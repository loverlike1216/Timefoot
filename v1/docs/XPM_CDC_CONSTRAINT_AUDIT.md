# XPM Gray constraint audit

Stage:INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS, TIMEFOOT/v1. Audit date2026-11-01.
Historical full-node profile/outputs remain read-only. This audit uses the installed Vivado2025.2
Build6299465 library, not a downloaded replacement or modified vendor source.

## Root cause and controlled reproduction

Installed `Vivado/data/ip/xpm/xpm_cdc/tcl/xpm_cdc_gray.tcl` queries clocks on scoped src_clk/dest_clk,
then reads minimum PERIOD. If source clock is absent it uses1000ns; absent destination uses1001ns.
Its max-delay bound is the SOURCE period; bus-skew bound is min(source,destination periods).
These are fallback values, not FPGA operating periods and not a special FIFO timing allowance.

The original implement.tcl called synth_design before reading common_clocks.xdc. Macro Tcl ran
without the primary/derived clock objects and serialized the fallback exceptions. Adding clocks
after synthesis did not retroactively recompute those Tcl expressions.

`probe_xpm_order.tcl` compares unchanged tf_node_top RTL/Part:

| Run | Only ordering difference | Observed exported Gray max/skew |
|---|---|---|
| p0_order_late | synth then read primary clocks | repeated1000.000ns max-delay and bus-skew |
| p0_order_early | read primary clocks BEFORE synth | automatic6.667/10/20ns source max-delay;6.667ns skew for these crossings |

The early run actually completed opt/place/phys_opt/route and report_bus_skew. Its exact source/
destination cells and actual clock objects are in gray_clock_objects.tsv; all macro-generated
exceptions are exported in effective_synth/effective_routed.xdc. Raw synth logs, clocks, exception
and bus-skew reports remain under verification/evidence/p0_order_early (and late counterpart).
This test does not claim to fix the old complete-node external I/O failure.

## Correction and acceptance

New adapter flow reads adapter_clocks.xdc before synthesis. Work clocks are derived from the actual
MMCM, never independently redefined. Forwarded output clock is defined at the ODDR output before
interface delays are applied. No arbitrary replacement number, blanket clock group, global false
path or new manual waiver is used. Vendor synchronizer exceptions and internal vendor waivers are
distinguished from application policy. Actual generated periods/endpoints, exception coverage/
ignored exceptions and routed bus skew must be checked in BOTH final Parts.

Every final Gray crossing must be bounded by its actual source period, with skew no looser than
the relevant source/destination minimum. Missing clocks or a1000/1001fallback fails the audit.
Review all_fanout endpoints, first-stage Gray registers and bus-skew constraint coverage rather
than treating zero Critical CDC as proof. Duplicate exported constraints/ignored entries must be
explained from report_exceptions, not silently discarded. The canonical final adapter reports,
not early development attempts that changed source during a two-Part run, determine acceptance.

## Related interface/RDC findings

A fast cumulative counter was initially tried with standalone XPM_GRAY; enabled simulator checks
reported missed stable-sampling assumptions. It was replaced by a full-handshake status snapshot,
without disabling the assertion. Application frame ledgers allow sparse coherent snapshots and
wait128link clocks for quiescent reconciliation. FIFO pointers continue using vendor Gray logic.

The original core TX valid contains asynchronous safety masking. Connecting it directly to the
new FIFO enabled RAM from that asynchronous cone (REQP-1839). A synchronous holding slot now
terminates that mask before FIFO write-enable. Initial per-beat ready also failed the half-cycle
return path; the implemented full-frame-credit protocol reserves capacity and observes low/high
acknowledgement through XPM, eliminating that combinational timing dependency structurally.

## Sources checked

- [AMD UG903 non-project timing/XDC order](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Non-Project-Flows)
- [AMD UG903 output constraints](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Output-Delays)
- [AMD XPM_CDC_GRAY](https://docs.amd.com/r/en-US/pg382-xpm-cdc-generator/XPM_CDC_GRAY)
- [AMD UG949 asynchronous relationships](https://docs.amd.com/r/2023.2-English/ug949-vivado-design-methodology/Asynchronous)
- Installed2025.2 XPM Tcl/HDL read-only and actual late/early tool output are the version-specific evidence.
